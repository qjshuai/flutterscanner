import 'package:flutter/material.dart';

class ExpandedButtonsBar extends StatelessWidget {
  final List<ButtonInfo> buttonInfo;

  ExpandedButtonsBar(this.buttonInfo);

  @override
  Widget build(BuildContext context) {
    final buttons = buttonInfo
        .map((e) => Expanded(
      flex: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: FlatButton(
          // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          color: e.backgroundColor,
          child: Text(e.text,
              style: TextStyle(color: e.textColor, fontSize: 15, fontWeight: FontWeight.w500)),
          onPressed: e.onPressed,
        ),
      ),
    ))
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons[0],
        SizedBox(width: 20),
        buttons[1],
      ],
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
