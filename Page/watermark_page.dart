import 'dart:math';

import 'package:flutter/material.dart';
import 'package:USB_Share/Util/palette.dart';

class WaterMark extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final String text;
  const WaterMark(
      {super.key,
      required this.columnCount,
      required this.rowCount,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: creatColumnWidgets(),
      ),
    );
  }

  List<Widget> creatRowWdiges() {
    List<Widget> list = [];
    for (var i = 0; i < rowCount; i++) {
      final widget = Expanded(
          child: Center(
              child: Transform.rotate(
        angle: -pi / 10,
        child: Text(
          text,
          style: const TextStyle(
              color: greyColor, // Color(0x08000000),
              fontSize: 8,
              decoration: TextDecoration.none),
        ),
      )));
      list.add(widget);
    }
    return list;
  }

  List<Widget> creatColumnWidgets() {
    List<Widget> list = [];
    for (var i = 0; i < columnCount; i++) {
      final widget = Expanded(
          child: Row(
        children: creatRowWdiges(),
      ));
      list.add(widget);
    }
    return list;
  }
}
