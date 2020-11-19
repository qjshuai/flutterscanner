import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:scanner/receipt/receipt_info.dart';
import 'package:scanner/widgets/alert.dart';
import 'package:scanner/utils/constants.dart';
import 'package:scanner/utils/scan_state.dart';
import '../widgets/buttons_bar.dart';
import '../utils/error_envelope.dart';

/// 收件
Future<bool> showReceiptDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
          onWillPop: () => Future.value(false), child: ReceiptDialog()));
}

class ReceiptDialog extends StatefulWidget {
  @override
  _ReceiptDialogState createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  List<ReceiptInfo> groups = [];
  ScanState _scanState = ScanningState();

  @override
  void initState() {
    super.initState();

    //自动开启扫码
    _startScan();
  }

  void _startScan() async {
    print('开始扫码');
    String code;
    try {
      code = await nativeChannel.invokeMethod('scan');
      print('扫码成功');
    } catch (e) {
      String msg = ErrorEnvelope(e).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        Navigator.of(context).pop();
        print('取消扫码');
        return; //取消扫码不做提示, 退出即可
      }
      print('扫码出错');
      showErrorDialog(context, msg);
      return;
    }
    //开始获取信息
    print('开始获取订单信息');
    _scanState = FetchingState();
    try {
      final groups = await _fetchReceiptInfo(code);
      print('获取订单信息成功');
      setState(() {
        this.groups = groups;
        _scanState = FetchSuccessState();
      });
    } catch (e) {
      print('获取订单信息出错');
      String msg = ErrorEnvelope(e).toString();
      _scanState = FetchingErrorState(msg);
      showAlertDialog(context, msg, onRetry: _startScan);
    }
  }

  /// 获取洁衣(收件)信息
  Future<List<ReceiptInfo>> _fetchReceiptInfo(String code) async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final response = await http.get<Map<String, dynamic>>(
        '/roshine/parcelorden/collectParcel',
        queryParameters: {'serialNumber': code});
    return (response.data["data"] as List<dynamic>)
        .map((e) => ReceiptInfo.fromJson(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_scanState is ScanningState) {
      child = null;
    } else if (_scanState is FetchingState) {
      child = CircularProgressIndicator();
    } else {
      child = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemBuilder: buildGroupCell, itemCount: groups.length),
            ),
            _buildBottomBar(context),
          ],
        ),
      );
    }
    return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        backgroundColor: Colors.transparent,
        child: child);
  }

  /// 底部按钮
  Widget _buildBottomBar(BuildContext context) {
    final info = [
      ButtonInfo(
          text: '完成',
          textColor: Colors.white,
          backgroundColor: Color(0xFF7C9A92),
          onPressed: () {
            Navigator.of(context).pop(false);
          }),
      ButtonInfo(
          text: '继续扫码',
          textColor: Colors.white,
          backgroundColor: Color(0xFF253334),
          onPressed: () {
            // Navigator.of(context).pop(true);
            _startScan();
          })
    ];
    return SizedBox(
      height: 60.0,
      child: ExpandedButtonsBar(info),
    );
  }

  Widget buildGroupCell(BuildContext context, int index) {
    final group = groups[index];
    List<Widget> children = [
      SizedBox(height: 3),
      SizedBox(
          height: 35,
          child: Text(group.shortCode ?? '',
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF253334)))),
      Text('订单短码',
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Color(0Xff8C9C9D))),
    ];

    /// 订单详细信息
    final orders =
        group.orders.map((order) => _buildOrderCell(context, order)).toList();
    children.addAll(orders);

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<Widget> _buildImages(ReceiptOrder order) {
    //添加图片
    if (order.pics.isNotEmpty) {
      return order.pics.map(_buildImage).toList();
    }
    return null;
  }

  Widget _buildImage(String url) {
    return Column(
      children: [
        SizedBox(height: 10),
        CachedNetworkImage(
          imageUrl: url,
//          height: 80,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildOrderCell(BuildContext context, ReceiptOrder order) {
    var children = [
      Divider(
        height: 49,
        color: Color(0xFFCCCCCC),
      ),
      Text('订单信息', style: TextStyle(fontSize: 13.0, color: Color(0xFF8C9C9D))),
      SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: _buildCell('客户名', order.nickname ?? '')),
          Expanded(child: _buildCell('手机号', order.tel ?? '')),
        ],
      ),
      _buildCell('订单号', order.orderCode ?? ''),
      _buildCell('洁品信息', order.detailsString ?? ''),
      _buildCell('洁品备注', order.featuresString ?? ''),
    ];
    final images = _buildImages(order);
    if (images != null) {
      children.addAll(images);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
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
