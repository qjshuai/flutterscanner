import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scanner/send/storage_order.dart';
import 'package:scanner/utils/scan_state.dart';
import '../widgets/buttons_bar.dart';
import '../utils/error_envelope.dart';

// 发件入库
Future<bool> showSendDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SendDialog());
}

class SendDialog extends StatefulWidget {
  @override
  _SendDialogState createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {

  ScanState _scanState = ScanningState();

  StorageOrder _order;
  StorageStation _selectedStation;

  /// 是否正在选择站点
  bool _onSelecting = false;

  /// 是否已经入库成功
  bool _putInSuccess = false;
  bool _onRequesting = false;
  bool _bootstrap = false;

  @override
  void initState() {
    super.initState();

    //自动开启扫码
    _startScan();
  }

  /// 点击扫码
  void _startScan(BuildContext context) async {
    try {
      // _code = await _nativeChannel.invokeMethod('scan');
      setState(() {
        _onRequesting = true;
      });
      // final order =
      //     await BlocProvider.of<EnvironmentBloc>(context).fetchOrderInfo(_code);
      setState(() {
        // _order = order;
        // _putInSuccess = false;
        // _onRequesting = false;
        // _selectedStation = _order.stationList.firstWhere(
        //     (element) => element.id == order.defaultPostStationId,
        //     orElse: () => null);
      });
      if (_selectedStation == null) {
        Fluttertoast.showToast(
            msg: '无默认驿站, 请先选择',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            fontSize: 16.0);
      }
    } catch (error) {
      var msg = ErrorEnvelope(error).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        Navigator.of(context).pop(false);
        return;
      }
      if (msg.contains('Connection failed')) {
        msg = '网络连接出错, 请检查网络连接';
      }
      setState(() {
        _onRequesting = false;
      });
      var dialog = CupertinoAlertDialog(
        content: Text(
          msg,
          style: TextStyle(fontSize: 20),
        ),
        actions: <Widget>[
          CupertinoButton(
            child: Text('取消'),
            onPressed: () => Navigator.popUntil(context, (route) {
              print(route);
              if (route is MaterialPageRoute) {
                return route.isFirst;
              }
              return false;
            }),
          ),
          CupertinoButton(
            child: Text('继续扫码'),
            onPressed: () {
              Navigator.pop(context);
              _startScan(context);
            },
          ),
        ],
      );
      showDialog<dynamic>(context: context, builder: (_) => dialog);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrap) {
      _bootstrap = true;
      _startScan(context);
    }
    if (_order == null && _onRequesting == false) {
      return Container();
    }
    return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 150, horizontal: 30),
        backgroundColor: _onRequesting ? Colors.transparent : Colors.white,
        child: _onRequesting
            ? Center(child: CircularProgressIndicator())
            : Container(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              '入库信息',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          padding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: _buildSelectedStation(),
                        ),
                        Divider(),
                        Expanded(
                            child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: ListView.builder(
                              itemBuilder: _buildOrderDetailsCell,
                              itemCount: (_order.orderDetails ?? []).length),
                        )),
                        _buildBottomBar(context),
                      ],
                    ),
                    Positioned(
                        left: 15,
                        right: 15,
                        top: 90.0,
                        child: _buildStationList())
                  ],
                ),
              ));
  }

  Widget _buildOrderDetailsCell(BuildContext context, int index) {
    final details = _order.orderDetails[index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${details.category ?? ''} 价格： ${details.title}',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        Text(
          '数量： ${details.amount}',
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ],
    );
  }

  Widget _buildSelectedStation() {
    return InkWell(
      child: Row(
        children: [
          Text(
            _selectedStation?.stationName ?? '点击选择驿站',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Spacer(),
          Icon(
            Icons.arrow_forward_ios_outlined,
            size: 15,
          )
        ],
      ),
      onTap: () {
        setState(() {
          _onSelecting = true;
        });
      },
    );
  }

  Widget _buildStationList() {
    final list = _order.stationList;
    final rowHeight = 38.0;
    final length = _order.stationList.length;
    final height = (length > 6 ? 6 : length) * rowHeight;
    return Visibility(
        visible: _onSelecting,
        child: Container(
            height: height,
            decoration: BoxDecoration(
                color: Colors.indigo, borderRadius: BorderRadius.circular(4)),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) =>
                  _buildStationCell(context, list[index], index),
              itemExtent: rowHeight,
              itemCount: length,
            )));
  }

  Widget _buildStationCell(BuildContext context, StorageStation station, int index) {
    return InkWell(
      child: Center(
        child: Container(
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
      ),
      onTap: () {
        setState(() {
          _onSelecting = false;
          _selectedStation = station;
        });
      },
    );
  }

  /// 底部按钮
  Widget _buildBottomBar(BuildContext context) {
    final info = [
      ButtonInfo(
          text: '完成',
          textColor: Colors.white,
          backgroundColor: Color(0xFF8FA6C9),
          onPressed: () {
            Navigator.of(context).pop(false);
          }),
      ButtonInfo(
          text: _putInSuccess ? '继续扫码' : '入库',
          textColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () {
            if (_putInSuccess) {
              _startScan(context);
            } else {
              _putInStorage();
            }
          }),
    ];
    return SizedBox(height: 50, child: ExpandedButtonsBar(info));
  }

  void _putInStorage() async {
    if (_selectedStation?.id == null) {
      Fluttertoast.showToast(
          msg: '未选择驿站或者驿站ID无效',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          fontSize: 16.0);
      return;
    }
    try {
      // await BlocProvider.of<EnvironmentBloc>(context)
      //     .putIn(_code, _selectedStation.id);
      // Fluttertoast.showToast(
      //     msg: '入库成功',
      //     toastLength: Toast.LENGTH_SHORT,
      //     gravity: ToastGravity.CENTER,
      //     fontSize: 16.0);
      // setState(() {
      //   _putInSuccess = true;
      // });
    } catch (e) {
      final msg = ErrorEnvelope(e).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        return;
      }
      _alertError(context, msg);
    }
  }

  /// 确定
  void _alertError(BuildContext context, String message,
      {Function() onConfirm}) {
    var dialog = CupertinoAlertDialog(
      content: Text(
        message,
        style: TextStyle(fontSize: 20),
      ),
      actions: <Widget>[
        CupertinoButton(
          child: Text('知道了'),
          onPressed: () {
            if (onConfirm != null) {
              onConfirm();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
    showDialog<dynamic>(context: context, builder: (_) => dialog);
  }
}
