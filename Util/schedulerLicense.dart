import 'dart:io';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/hive_helper.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LicenseScheduler {
  runScheduler(context) async {
    Directory dir = await getApplicationSupportDirectory();

    String licenseFilePath = '${dir.path}\\cardioData.txt';
    File file = File(licenseFilePath);
    if (await file.exists()) {
      String licenceKey = await file.readAsString();
      Directory pythonFileDir = await Constants.getDataDirectory();
      String pythonFilePath = pythonFileDir.path;
      var result = await Process.run(
          'python', ['$pythonFilePath/decryptKey.py', licenceKey]);
      if (result.stdout != null && result.stdout != '') {
        String restultOutput = result.stdout;
        restultOutput = restultOutput.replaceAll('(', " ");
        restultOutput = restultOutput.replaceAll(')', " ").toString();

        List<String> resultList = restultOutput.split(',');
        String toDate = resultList.last.replaceAll("'", " ").trim();
        if (toDate != '') {
          toDate = Constants.licenseFormat.format(DateTime.parse(toDate));
          DateTime toDateDateTime = DateTime.parse(toDate);
          DateTime now = DateTime.now();
          String cDate = Constants.licenseFormat.format(now);
          DateTime currentDate = DateTime.parse(cDate);

          Duration difference = toDateDateTime.difference(currentDate);
          Map<String, dynamic> payload = new Map<String, dynamic>();
          payload["data"] = "content";
          if (difference.isNegative || toDateDateTime == currentDate) {
            //if (toDateDateTime.isAfter(currentDate)) {
            //toDate is in the past.
            HiveHelper().saveLicenseExpired(true);
            Navigator.of(context).pushNamedAndRemoveUntil(
                PageRouter.licenseExpied, (Route<dynamic> route) => false);
          } else if (difference.inDays == 30) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.info,
              text: "License is about to expire with in 30 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 20) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.info,
              text: "License is about to expire with in 20 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 15) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.info,
              text: "License is about to expire with in 15 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 10) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              text: "License is about to expire with in 10 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 9) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              text: "License is about to expire with in 9 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 8) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              text: "License is about to expire with in 8 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 7) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              text: "License is about to expire with in 7 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 6) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.warning,
              text: "License is about to expire with in 6 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 5) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "License is about to expire with in 5 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 4) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "License is about to expire with in 4 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 3) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "License is about to expire with in 3 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 2) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "License is about to expire with in 2 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          } else if (difference.inDays == 1) {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              text: "License is about to expire with in 1 days.",
              title: 'License Renewal',
              width: Sizing.width(10, 20),
              confirmBtnColor: primaryColor,
            );
          }
        }
      }
    }
  }
}
