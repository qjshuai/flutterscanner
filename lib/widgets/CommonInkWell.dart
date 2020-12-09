import 'package:flutter/material.dart';

class CommonInkWell extends StatelessWidget {
  CommonInkWell({this.child, this.decoration, this.onTap});

  final Function() onTap;
  final Widget child;
  final Decoration decoration;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Ink(
            decoration: decoration,
            child: InkWell(onTap: onTap, child: child)));
  }
}
