import 'package:flutter/material.dart';

/// 收件
Future<bool> showPrintDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
          onWillPop: () => Future.value(false), child: PrintDialog()));
}

class PrintDialog extends StatefulWidget {
  @override
  _PrintDialogState createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {

  // Widget _buildInput(BuildContext context) {
  //   [0,1, 2, 3].map((e) => null)
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.0),
      child: AspectRatio(
        aspectRatio: 345.0 / 300.0,
        child: Container(
          padding: EdgeInsets.only(left: 20.0, right: 20, top: 24, bottom: 20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: 35,
                  child: Text('请输入服务码',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w600))),
              Spacer(
                flex: 30,
              ),
              SizedBox(
                height: 66,
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10.0)),
                  // child: _buildInput(context),
                ),
              ),
              Spacer(flex: 66),
              SizedBox(
                  height: 60,
                  child: FlatButton(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(10.0)),
                      child: Center(
                        child: Text(
                          '确认并打印',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
