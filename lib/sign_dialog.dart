import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scanner/order.dart';
import 'app_environment/error_envelope.dart';
import 'buttons_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanner/app_environment/environment_bloc.dart';

Future<bool> showSignDetails(
    BuildContext context, StorageOrder order, String code) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignScreen(order, code));
}

class SignScreen extends StatefulWidget {
  final StorageOrder order;
  final String code;

  SignScreen(this.order, this.code);

  @override
  _SignScreenState createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  StorageOrder get order => widget.order;
  Station _selectedStation;

  /// 是否正在选择站点
  bool onSelecting = false;

  /// 是否已经入库成功
  bool _putInSuccess = false;

  @override
  void initState() {
    _selectedStation = order.stationList
        .firstWhere((element) => element.id == order.defaultPostStationId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 150, horizontal: 30),
        backgroundColor: Colors.white,
        child: Container(
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
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: _buildSelectedStation(),
                  ),
                  Divider(),
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListView.builder(
                        itemBuilder: _buildOrderDetailsCell,
                        itemCount: (order.orderDetails ?? []).length),
                  )),
                  _buildBottomBar(context),
                ],
              ),
              Positioned(
                  left: 15, right: 15, top: 90.0, child: _buildStationList())
            ],
          ),
        ));
  }

  Widget _buildOrderDetailsCell(BuildContext context, int index) {
    final details = order.orderDetails[index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '价格： ${details.title}',
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
          onSelecting = true;
        });
      },
    );
  }

  Widget _buildStationList() {
    final list = order.stationList;
    final rowHeight = 38.0;
    final length = order.stationList.length;
    final height = (length > 6 ? 6 : length) * rowHeight;
    return Visibility(
        visible: onSelecting,
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

  Widget _buildStationCell(BuildContext context, Station station, int index) {
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
          onSelecting = false;
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
              Navigator.of(context).pop(true);
            } else {
              _putInStorage();
            }
          }),
    ];
    return SizedBox(
      height: 50,
      child: ExpandedButtonsBar(info),
    );
  }

  void _putInStorage() async {
    if (_selectedStation?.id == null) {
      Fluttertoast.showToast(
          msg: '未选择驿站或者驿站ID无效',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          // timeInSecForIosWeb: 1,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
    }
    try {
      await BlocProvider.of<EnvironmentBloc>(context)
          .putIn(widget.code, _selectedStation.id);
      Fluttertoast.showToast(
          msg: '入库成功',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          // timeInSecForIosWeb: 1,
          // backgroundColor: Colors.red,
          // textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        _putInSuccess = true;
      });
    } catch (e) {
      final msg = ErrorEnvelope(e).toString();
      if (msg.contains('已取消') && msg.contains('100')) {
        return;
      }
      _alertError(context, msg);
    }
  }

  /// 确定
  void _alertError(BuildContext context, String message) {
    var dialog = CupertinoAlertDialog(
      content: Text(
        message,
        style: TextStyle(fontSize: 20),
      ),
      actions: <Widget>[
        CupertinoButton(
          child: Text('知道了'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
    showDialog<dynamic>(context: context, builder: (_) => dialog);
  }
}
