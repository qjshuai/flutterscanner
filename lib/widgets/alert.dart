import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showAlertDialog(
    BuildContext context, String msg, {Function onRetry}) {
  var dialog = CupertinoAlertDialog(
    content: Text(
      msg ?? '错误',
      style: TextStyle(fontSize: 20),
    ),
    actions: <Widget>[
      CupertinoButton(
        child: Text('取消'),
        onPressed: () => Navigator.popUntil(context, (route) {
          if (route is MaterialPageRoute) {
            return route.isFirst;
          }
          return false;
        }),
      ),
      CupertinoButton(
        child: Text('重试'),
        onPressed: () {
          Navigator.pop(context);
          onRetry();
        },
      ),
    ],
  );
  showDialog(context: context, builder: (_) => WillPopScope(child: dialog, onWillPop: () async => false));
}

void showErrorDialog(BuildContext context, String message,
    {Function() onConfirm}) {
  var dialog = CupertinoAlertDialog(
    content: Text(
      message ?? '错误',
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
  showDialog<dynamic>(context: context, builder: (_) => WillPopScope(child: dialog, onWillPop: () async => false));
}
