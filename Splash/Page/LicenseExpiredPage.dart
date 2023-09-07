import 'dart:io';

import 'package:USB_Share/Splash/Page/LicenseKeyDialog.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class LicenseExpired extends StatefulWidget {
  const LicenseExpired({super.key});

  @override
  State<LicenseExpired> createState() => _LicenseExpiredState();
}

class _LicenseExpiredState extends State<LicenseExpired> {
  String fromDate = '';
  String toDate = '';
  String macAdd = '';

  @override
  void initState() {
    super.initState();
    getLicenseInfo();
  }

  getLicenseInfo() async {
    Directory dir = await Constants.getDataDirectory();
    String licenseFilePath = '${dir.path}\\licenseInfo.txt';
    File file = File(licenseFilePath);
    if (file.existsSync()) {
      String licenceData = await file.readAsString();
      List<String> info = licenceData.split(',');
      setState(() {
        macAdd = info[0];
        fromDate = info[1].trim().split('.').first;
        toDate = info[2].trim().split('.').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: 'Renew license',
              child: IconButton(
                  onPressed: () {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return CheckLicenseAuthentication(
                            isRenewal: true,
                          );
                        });
                  },
                  icon: Icon(
                    Icons.help_center,
                    color: primaryColor,
                  )),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: JustTheTooltip(
              content: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10, left: 10, top: 10),
                      child: RichText(
                        text: TextSpan(
                            text: 'MAC Address : ',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? const TextStyle(
                                    fontSize: 17, color: greyColor)
                                : const TextStyle(
                                    fontSize: 12, color: greyColor),
                            children: [
                              TextSpan(
                                text: ' $macAdd',
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(
                                        fontSize: 17, color: blackColor)
                                    : const TextStyle(
                                        fontSize: 12, color: blackColor),
                              )
                            ]),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Divider(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 10, left: 10, top: 7),
                      child: RichText(
                        text: TextSpan(
                            text: 'From Date      : ',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? const TextStyle(
                                    fontSize: 17, color: greyColor)
                                : const TextStyle(
                                    fontSize: 12, color: greyColor),
                            children: [
                              TextSpan(
                                text: ' $fromDate',
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(
                                        fontSize: 17, color: blackColor)
                                    : const TextStyle(
                                        fontSize: 12, color: blackColor),
                              )
                            ]),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Divider(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          right: 10, left: 10, top: 7, bottom: 10),
                      child: RichText(
                        text: TextSpan(
                            text: 'Till Date          : ',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? const TextStyle(
                                    fontSize: 17, color: greyColor)
                                : const TextStyle(
                                    fontSize: 12, color: greyColor),
                            children: [
                              TextSpan(
                                text: ' $toDate',
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(
                                        fontSize: 17, color: blackColor)
                                    : const TextStyle(
                                        fontSize: 12, color: blackColor),
                              )
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
              child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.privacy_tip,
                    color: primaryColor,
                  )),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: Colors.yellow,
              size: Sizing().height(50, 30),
            ),
            Text('Your license has been expired !',
                style: TextStyle(
                  fontSize: Sizing().height(2, 3.5),
                )),
            SizedBox(
              height: Sizing().height(2, 3),
            ),
            Text('Kindly renew license',
                style: TextStyle(
                  fontSize: Sizing().height(2, 3.5),
                )),
          ],
        ),
      ),
    );
  }
}
