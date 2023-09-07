import 'dart:io';

import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';
import 'package:flutter/material.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CommonUi {
  //String baseURL = 'https://localhost:7252/api/';

  //Dev
  String baseURL = 'http://photoappdevapi.vaanamtechdemo.com/api/';
  bool isFormAPI = false;
  //mobile
  //127.0.0.1
  //String baseURL = 'http://10.0.2.2:404/api/';

  //apk ipconfig
  //String baseURL = 'http://192.168.10.52:404/api/';

  //windows
  //String baseURL = 'http://localhost:404/api/';

  showLoadingDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 40,
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Center(
                  child: LoadingAnimationWidget.inkDrop(
                      color: whiteColor, size: 50))),
        );
      },
    );
  }

  animationLoader(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 40,
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Center(
                  child: LoadingAnimationWidget.inkDrop(
                      color: primaryColor, size: 100))),
        );
      },
    );
  }

  licenseValidatingLoader(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 40,
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: Sizing().height(5, 15),
                ),
                Text('Validating License Key...',
                    style: TextStyle(
                      fontSize: Sizing().height(2, 3.5),
                    )),
                SizedBox(
                  height: Sizing().height(7, 7),
                ),
                SizedBox(
                    height: Sizing().height(5, 25),
                    width: Sizing.width(50, 35),
                    child: Center(
                        child: LoadingAnimationWidget.inkDrop(
                            color: primaryColor, size: 30))),
              ],
            ),
          ),
        );
      },
    );
  }

  showLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  static String capitalize(String text) {
    return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
  }

  showMappedSuccessDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 40,
            insetPadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            content: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: Sizing().height(15, 6),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Sizing.width(3, 10)),
                    child: Text(
                      'Project and Template Mapped Successfully',
                      style: Platform.isWindows ? body3 : subtitle1,
                    ),
                  ),
                  SizedBox(
                    height: Sizing().height(10, 6),
                  ),
                  Container(
                    height: Sizing().height(30, 10),
                    padding: EdgeInsets.symmetric(
                      vertical: Sizing().height(1, 1),
                      horizontal: Sizing.width(2, 3),
                    ),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2)),
                    child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pushNamed(
                            PageRouter.generateReport,
                          );
                        },
                        child: Text(
                          'Ok',
                          style: TextStyle(
                              fontSize: Platform.isWindows
                                  ? Sizing().height(2, 3)
                                  : 12,
                              color: whiteColor),
                        )),
                  ),
                  SizedBox(
                    height: Sizing().height(15, 6),
                  ),
                ],
              ),
            ));
      },
    );
  }
}
