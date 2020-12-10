import 'dart:ui';
import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:quiver/strings.dart';
import 'package:scanner/widgets/alert.dart';
import 'package:scanner/utils/constants.dart';
import '../widgets/buttons_bar.dart';
import '../utils/error_envelope.dart';
import 'box.dart';

/// 收件
Future<bool> showPickupDialog(BuildContext context, {Box box}) {
  return showDialog<bool>(
      context: context,
      // barrierDismissible: false,
      builder: (context) => PickupDialog(box: box));
}

class PickupDialog extends StatefulWidget {
  final Box box;

  PickupDialog({this.box});

  @override
  _PickupDialogState createState() => _PickupDialogState();
}

enum PickupStatus {
  none, //初始状态
  box, //入袋
  pick, //揽收
}

class _PickupDialogState extends State<PickupDialog> {
  PickupStatus _status;

  /// 是否正在请求
  bool _isRequesting = false;

  int boxCount;

  @override
  void initState() {
    boxCount = widget.box.parcelNum ?? 0;
    _status = widget.box.status == 6 ? PickupStatus.none : PickupStatus.box;
    super.initState();
  }

  void _startScan() async {
    try {
      final code = await nativeChannel.invokeMethod('scan');
      if (isEmpty(code)) {
        return; //取消扫码
      }
      //入袋
      setState(() {
        _isRequesting = true;
      });
      final error = await _startBox(code);
      setState(() {
        _isRequesting = false;
      });
      if (isNotEmpty(error)) {
        showErrorDialog(context, error);
      } else {
        setState(() {
          _status = PickupStatus.box;
          widget.box.needRefresh = true;
          boxCount += 1;
        });
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });
      String msg = ErrorEnvelope(e).toString();
      showErrorDialog(context, msg);
    }
  }

  void _startPickup() async {
    setState(() {
      _isRequesting = true;
    });
    try {
      final http = GetIt.instance.get<ServiceCenter>().httpService;
      final path = '/roshine/parcelorden/collectOrder';
      final response =
          await http.get<Map<String, dynamic>>(path, queryParameters: {
        'orderId': widget.box.orderId,
      }); //keyword
      final resultCode = response.data['code'] as int;
      setState(() {
        _isRequesting = false;
      });
      if (resultCode == 0) {
        setState(() {
          widget.box.needRefresh = true;
          _status = PickupStatus.pick;
        });
      } else {
        var message = response.data['message'] as String;
        if (message == null || message == '') {
          message = '错误 code :${resultCode ?? 999}';
        }
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });
      String msg = ErrorEnvelope(e).toString();
      showErrorDialog(context, msg);
    }
  }

  Future<String> _startBox(String code) async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final path = '/roshine/parcelorden/insertParcelOrden';
    final response = await http.post<Map<String, dynamic>>(path,
        data: {'orderId': widget.box.orderId, 'serialNumber': code}); //keyword
    final resultCode = response.data['code'] as int;
    if (resultCode == 0) {
      return '';
    } else {
      var message = response.data['message'] as String;
      if (message == null || message == '') {
        message = '错误 code :${resultCode ?? 999}';
      }
      return message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.white,
            ),
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 30 + 12.0, child: _buildStatus(context)),
                SizedBox(height: 30),
                Divider(height: 0.5, color: Color(0xFFCCCCCC)),
                _buildOrder(context),
                SizedBox(height: 60.0, child: _buildBottomBar(context)),
              ],
            ),
          ),
        ));
  }

  /// 顶部状态文字
  Widget _buildStatus(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _status == PickupStatus.none
            ? widget.box.statusName
            : _status == PickupStatus.box
                ? '入袋成功'
                : '完成揽收',
        style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: _status == PickupStatus.none
                ? Theme.of(context).primaryColor
                : Color(0xFFFE630A)),
      ),
    );
  }

  /// 订单信息
  Widget _buildOrder(BuildContext context) {
    final box = widget.box;
    var children = [
      SizedBox(height: 20),
      Row(
        children: [
          Expanded(flex: 4,child: _buildCell('客户名', box.nickname ?? '无')),
          Expanded(flex: 5,child: _buildCell('手机号', box.tel ?? '无')),
        ],
      ),
      _buildCell('订单号', box.orderCode ?? '无'),
      _buildCell('洁品信息', box.subTitle ?? '无'),
      _buildCell('洁品备注', box.featuresString ?? '无'),
      _buildCell('上门地址', box.address ?? '无'),
    ];
    // if (_status == PickupStatus.pick) {
    children.add(_buildCell('脏衣袋', '$boxCount'));
    // }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 底部按钮
  Widget _buildBottomBar(BuildContext context) {
    if (_isRequesting) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    List<ButtonInfo> info;
    switch (_status) {
      case PickupStatus.none:
        info = [
          ButtonInfo(
              text: '扫码入袋',
              textColor: Colors.white,
              backgroundColor: Color(0xFF253334),
              onPressed: () {
                // Navigator.of(context).pop(true);
                _startScan();
              })
        ];
        break;
      case PickupStatus.box:
        info = [
          ButtonInfo(
              text: '完成揽件',
              textColor: Colors.white,
              backgroundColor: Color(0xFF7C9A92),
              onPressed: () {
                _startPickup();
              }),
          ButtonInfo(
              text: '继续扫码',
              textColor: Colors.white,
              backgroundColor: Color(0xFF253334),
              onPressed: () {
                _startScan();
              })
        ];
        break;
      default:
        info = [
          ButtonInfo(
              text: '完成',
              textColor: Colors.white,
              backgroundColor: Color(0xFF253334),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ];
        break;
    }
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: ExpandedButtonsBar(info));
  }

  Widget _buildCell(String top, String bottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bottom ?? '',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF253334))),
        SizedBox(
          height: 2,
        ),
        Text(top ?? '',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF8C9C9D))),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
