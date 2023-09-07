// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Sizing {
  static double baseHeight = 640.0;
  static double baseWidth = 320.0;

  static late EdgeInsets defaultPadding;
  static late EdgeInsets horizontalPadding;
  static late EdgeInsets verticalPadding;
  static late SizedBox spacingHeight;
  static late SizedBox spacingWidth;
  static late SizedBox labelSpace;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _width;
  static late double _height;
  static bool isPortrait = false;
  static bool isMobile = true;

  void init(BoxConstraints constraints, Orientation orientation) {
    isPortrait = orientation == Orientation.portrait;

    _screenWidth = constraints.maxWidth;
    _screenHeight = constraints.maxHeight;

    _width = _screenWidth / baseWidth;
    _height = _screenHeight / baseHeight;

    if (_screenWidth < 600) {
      isMobile = true;
    } else {
      isMobile = false;
    }
    defaultPadding =
        EdgeInsets.symmetric(horizontal: width(2, 5), vertical: height(2, 5));

    horizontalPadding = EdgeInsets.symmetric(
      horizontal: width(5, 10),
    );

    verticalPadding = EdgeInsets.symmetric(
      vertical: height(10, 20),
    );
    spacingHeight = SizedBox(
      height: height(10, 20),
    );
    spacingWidth = SizedBox(
      width: width(5, 10),
    );

    labelSpace = SizedBox(
      height: 10,
    );
  }

  double height(double pSize, double lSize) {
    if (isPortrait) {
      return pSize * _height;
    } else {
      return lSize * _width;
    }
  }

  static double width(double pSize, double lSize) {
    if (isPortrait) {
      return pSize * _screenHeight / baseWidth;
    } else {
      return lSize * _screenWidth / baseHeight;
    }
  }

  void enableRotation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static dynamic getScreenWidth(context) {
    double size = MediaQuery.of(context).size.width;
    return size;
  }
}
