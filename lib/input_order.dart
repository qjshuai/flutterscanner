import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 输入编号
Future<String> showInputOrderDialog(BuildContext context) {
  return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InputOrderDialog());
}

class InputOrderDialog extends StatefulWidget {
  @override
  _InputOrderDialogState createState() => _InputOrderDialogState();
}

class _InputOrderDialogState extends State<InputOrderDialog> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        height: 300.0,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 43,
              child: Text(
                '手动录入编号',
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 25.0),
              ),
            ),
            SizedBox(
              height: 50,
              child: CupertinoTextField(
                controller: _controller,
                decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFCCCCCCC)))),
                placeholder: '请输入编号内容!',
              ),
            ),
            SizedBox(
              height: 1,
            ),
            CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  height: 60.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Center(
                    child: Text(
                      '确认',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15.0),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(_controller.text);
                })
          ],
        ),
      ),
    );
  }
}
