import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<bool> showToast(String msg, {ToastGravity gravity = ToastGravity.CENTER}) async {
  Fluttertoast.cancel();
  return Fluttertoast.showToast(
      msg: msg ?? '错误',
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: Color.fromARGB(190, 0, 0, 0),
      textColor: Colors.white,
      fontSize: 14.0);
}
