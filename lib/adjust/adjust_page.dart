import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scanner/receipt/receipt_info.dart';
import '../buttons_bar.dart';

/// 收件
Future<bool> showAdjustDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptDialog());
}

class ReceiptDialog extends StatefulWidget {

  @override
  _ReceiptDialogState createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  List<ReceiptInfo> groups = [];

  // final info = await _fetchReceiptInfo(code);

  @override
  Widget build(BuildContext context) {
    return Dialog(
        insetPadding: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        backgroundColor: Colors.white,
        child: Container(
          child: Column(
            children: [
              Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListView.builder(
                        itemBuilder: buildGroupCell, itemCount: groups.length),
                  )),
              _buildBottomBar(context),
            ],
          ),
        ));
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
          text: '继续扫码',
          textColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () {
            Navigator.of(context).pop(true);
          })
    ];
    return SizedBox(
      height: 50,
      child: ExpandedButtonsBar(info),
    );
  }

  Widget buildGroupCell(BuildContext context, int index) {
    final group = groups[index];
    List<Widget> children = [
      SizedBox(height: 10),
      SizedBox(
          height: 25,
          child: Text(group.shortCode ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black))),
      Text('订单短码',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.blueGrey)),
      Text('订单信息',
          textAlign: TextAlign.left,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
    ];

    /// 订单详细信息
    final orders =
    group.orders.map((order) => _buildOrderCell(context, order)).toList();
    children.addAll(orders);
    //分隔线
    children.add(Divider(color: Colors.grey));

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
      Divider(),
      _buildCell('客户名', order.nickname ?? ''),
      _buildCell('手机号', order.tel ?? ''),
      _buildCell('订单号', order.orderCode ?? ''),
      _buildCell('洁品信息', order.detailsString ?? ''),
      _buildCell('洁品备注', order.featuresString ?? ''),
    ];
    final images = _buildImages(order);
    if (images != null) {
      children.addAll(images);
    }
    return Container(
//      padding: EdgeInsets.only(left: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildCell(String top, String bottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(top ?? '',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.blueGrey)),
        SizedBox(
          height: 5,
        ),
        Text('  ${bottom ?? ''}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        SizedBox(
          height: 5,
        ),
      ],
    );
  }
}
