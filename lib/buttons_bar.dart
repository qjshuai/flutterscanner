import 'package:flutter/material.dart';

class ExpandedButtonsBar extends StatelessWidget {
  final List<ButtonInfo> buttonInfo;

  ExpandedButtonsBar(this.buttonInfo);

  @override
  Widget build(BuildContext context) {
    final buttons = buttonInfo
        .map((e) => Expanded(
      flex: 1,
      child: FlatButton(
        // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        color: e.backgroundColor,
        child: Text(e.text,
            style: TextStyle(color: e.textColor, fontSize: 15)),
        onPressed: e.onPressed,
      ),
    ))
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }
}

class ButtonInfo {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final void Function() onPressed;

  const ButtonInfo(
      {this.text, this.textColor, this.backgroundColor, this.onPressed});
}
