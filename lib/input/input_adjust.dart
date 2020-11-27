import 'dart:ui';
import 'package:environment/service_center.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import 'package:quiver/strings.dart';
import 'package:scanner/send/storage_order.dart';
import 'package:scanner/utils/constants.dart';
import 'package:scanner/utils/scan_state.dart';
import 'package:scanner/widgets/alert.dart';
import 'package:scanner/widgets/toast.dart';
import '../widgets/buttons_bar.dart';
import '../utils/error_envelope.dart';

// 发件入库
Future<bool> showInputAdjustDialog(BuildContext context, String code) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InputAdjustDialog(code));
}

class InputAdjustDialog extends StatefulWidget {
  final String code;

  InputAdjustDialog(this.code);

  @override
  _InputAdjustDialogState createState() => _InputAdjustDialogState();
}

class _InputAdjustDialogState extends State<InputAdjustDialog> {
  ScanState _scanState = ScanningState();

  SendOrder _order;

  SendStation get _selectedStation => _order?.selectedStation;

  /// 是否正在选择站点
  bool _onSelecting = false;

  @override
  void initState() {
    super.initState();

    _startFetch();
  }

  void _startFetch() async {
    //开始获取信息
    print('开始获取订单信息');
    setState(() {
      _scanState = FetchingState();
    });
    try {
      final order = await _fetchOrder(widget.code);
      print('获取订单信息成功');

      setState(() {
        this._order = order;
        _scanState = FetchSuccessState();
      });
    } catch (e) {
      print('获取订单信息出错');
      String msg = ErrorEnvelope(e).toString();
      setState(() {
        _scanState = FetchingErrorState(msg);
      });
      showAlertDialog(context, msg, onRetry: (){
        Navigator.of(context).pop(true);
      });
    }
  }

  void _startScan() async {
    print('开始扫码');
    String code;
    try {
      code = await nativeChannel.invokeMethod('scan');
      if (isEmpty(code)) {
        Navigator.of(context).pop();
        print('取消扫码');
        return; //取消扫码不做提示, 退出即可
      }
      print('扫码成功');
    } catch (e) {
      String msg = ErrorEnvelope(e).toString();
      print('扫码出错');
      showErrorDialog(context, msg);
      return;
    }
    //开始获取信息
    print('开始获取订单信息');
    setState(() {
      _scanState = FetchingState();
    });
    try {
      final order = await _fetchOrder(code);
      print('获取订单信息成功');

      setState(() {
        this._order = order;
        _scanState = FetchSuccessState();
      });
    } catch (e) {
      print('获取订单信息出错');
      String msg = ErrorEnvelope(e).toString();
      setState(() {
        _scanState = FetchingErrorState(msg);
      });
      showAlertDialog(context, msg, onRetry: _startScan);
    }
  }

  Future<SendOrder> _fetchOrder(String code) async {
    final http = GetIt.instance.get<ServiceCenter>().httpService;
    final path = '/roshine/parcelorden/selectStationBySerialNumber';
    final response = await http.get<Map<String, dynamic>>(path,
        queryParameters: {'orderCode': code}); //keyword
    // await Future.delayed(Duration(seconds: 1));
    final order = SendOrder.fromAdjustJson(response.data["data"]);
    order.code = code;
    order.selectedStation = order.stationList.firstWhere(
        (element) => element.id == order.defaultPostStationId,
        orElse: () => null);
    return order;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_scanState is ScanningState || _scanState is FetchingErrorState) {
      child = null;
    } else if (_scanState is FetchingState || _scanState is SubmittingState) {
      print('显示loading');
      child = Center(child: CircularProgressIndicator());
    } else {
      child = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(20.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                SizedBox(
                    height: 35.0,
                    child: Text(
                      '信息调整',
                      style:
                          TextStyle(color: Color(0xFF253334), fontSize: 25.0),
                    )),
                SizedBox(height: 40),
                Divider(height: 1),
                SizedBox(height: 24),
                Container(
                  height: 60,
                  child: _buildSelectedStation(),
                ),
                SizedBox(height: 30),
                Text(
                  orderTitle,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  '洁品信息',
                  style: TextStyle(
                    color: Color(0xFF8C9C9D),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_order?.actuallyPrice ?? 0}',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '价格',
                          style: TextStyle(
                            color: Color(0xFF8C9C9D),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_order?.orderDetails?.length ?? 0}',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '数量',
                          style: TextStyle(
                            color: Color(0xFF8C9C9D),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
                Spacer(),
                _buildBottomBar(context),
              ],
            ),
            Positioned(
                left: 0, right: 0, top: 190.0, child: _buildStationList())
          ],
        ),
      );
    }
    return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        backgroundColor: Colors.transparent,
        child: child);
  }

  String get orderTitle {
    return (_order?.orderDetails ?? [])
        .map((e) => '${e.category ?? ''}${e.title ?? ''}元洁衣区 ${e.amount}件')
        .join('、');
  }

  Widget _buildSelectedStation() {
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
            color: Color(0xFFF0F5F4),
            borderRadius: BorderRadius.circular(10.0)),
        padding: EdgeInsets.only(left: 18.0, right: 10.0),
        child: Row(
          children: [
            Text(
              _selectedStation?.stationName ?? '点击选择驿站',
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios_outlined,
              size: 15,
            )
          ],
        ),
      ),
      onTap: () {
        setState(() {
          _onSelecting = true;
        });
      },
    );
  }

  Widget _buildStationList() {
    final list = _order?.stationList ?? [];
    final rowHeight = 60.0;
    final length = list.length;
    final height = (length > 6 ? 6 : length) * rowHeight;
    return Visibility(
        visible: _onSelecting,
        child: Container(
            height: height,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10.0)),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) =>
                  _buildStationCell(context, list[index], index),
              itemExtent: rowHeight,
              itemCount: length,
            )));
  }

  Widget _buildStationCell(
      BuildContext context, SendStation station, int index) {
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: index == (_order.stationList.length - 1)
                        ? Colors.transparent
                        : Color(0xFF364445)))),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(station.stationName, style: TextStyle(color: Colors.white)),
            Visibility(
                visible: station == _selectedStation,
                child: Icon(Icons.check, color: Colors.white))
          ],
        ),
      ),
      onTap: () {
        setState(() {
          _onSelecting = false;
          _order.selectedStation = station;
        });
      },
    );
  }

  /// 底部按钮
  Widget _buildBottomBar(BuildContext context) {
    final info = [
      ButtonInfo(
          text: _scanState is SubmitSuccessState ? '关闭' : '取消',
          textColor: Colors.white,
          backgroundColor: Color(0xFF7C9A92),
          onPressed: () {
            Navigator.of(context).pop(false);
          }),
      ButtonInfo(
          text: _scanState is SubmitSuccessState ? '继续录入' : '确认调整',
          textColor: Colors.white,
          backgroundColor: Color(0xFF253334),
          onPressed: () {
            if (_scanState is SubmitSuccessState) {
              // _startScan();
              Navigator.of(context).pop(true);
            } else {
              _adjustOrder();
            }
          })
    ];
    return SizedBox(
      height: 60.0,
      child: ExpandedButtonsBar(info),
    );
  }

  void _adjustOrder() async {
    final id = _selectedStation?.id;
    if (id == null) {
      showToast('未选择驿站或者驿站ID无效');
      return;
    }
    if (id == _order.defaultPostStationId) {
      showToast('驿站未更改');
      return;
    }
    try {
      setState(() {
        _scanState = SubmittingState();
      });
      final http = GetIt.instance.get<ServiceCenter>().httpService;
      await http.get<Map<String, dynamic>>(
          '/roshine/parcelorden/updateOrderPostOut',
          queryParameters: {'orderIds': _order.orderIds, 'stationId': id});
      // await Future.delayed(Duration(seconds: 1));
      showToast('更改成功');
      setState(() {
        _scanState = SubmitSuccessState();
      });
    } catch (e) {
      setState(() {
        _scanState = FetchSuccessState();
      });
      final msg = ErrorEnvelope(e).toString();
      showErrorDialog(context, msg);
    }
  }
}
