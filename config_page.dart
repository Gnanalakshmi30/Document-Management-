import 'dart:io';

import 'package:USB_Share/Configuration/Model/fontFamily_model.dart';
import 'package:USB_Share/Configuration/Model/password_model.dart';
import 'package:USB_Share/Configuration/Model/reportCategory_model.dart';
import 'package:USB_Share/Configuration/Model/templateStyle_model.dart';
import 'package:USB_Share/Configuration/Service/password_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:USB_Share/Configuration/Model/config_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  TextEditingController autoDeletecontroller = TextEditingController();
  TextEditingController imageCaptioncontroller = TextEditingController();
  TextEditingController reportCategorycontroller = TextEditingController();
  TextEditingController fontFamilycontroller = TextEditingController();
  TextEditingController syncExpirycontroller = TextEditingController();
  TextEditingController fontSizecontroller = TextEditingController();
  TextEditingController changePasswordcontroller = TextEditingController();
  TextEditingController newPasswordcontroller = TextEditingController();
  int selectedIndex = 0;
  String targetDay = "";
  String expiryTime = "";
  final configurationService = ConfigurationService();
  List<ConfigurationModel> configData = [];
  List<TemplateStyleModel> tempStyleData = [];
  List<ReportCategoryModel> reportCategoryData = [];
  List<FontFamilyModel> fontFamilyData = [];
  int selCaptionIndex = 0;
  int selCategoryIndex = 0;
  int selfontFamilyIndex = 0;
  String? selectedfontFamily;
  int? selectedFontSize;
  bool passwordVerified = false;
  List<String> fontFamilyList = [
    'Arial',
    'Times New Roman',
    'Calibri',
    'Cambria',
    'Verdana'
  ];
  List<bool> usbOrWifi = [false, false];
  final passwordService = PasswordService();
  String currentPass = '';
  String passwordChangedDuration = '';
  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();

  getConfigData() async {
    List<ConfigurationModel> res =
        await configurationService.getConfiguration();
    List<String> temp = res[0].wifiOrUsb!.split('|');
    setState(() {
      configData = res;
      imageCaptioncontroller.text = "";
      selCaptionIndex = -1;
      usbOrWifi = [
        temp[0].trim().toLowerCase() == 'true',
        temp[1].trim().toLowerCase() == 'true'
      ];
    });
  }

  getTemplateStyleData() async {
    var res = await configurationService.getTemplateStyleData();
    setState(() {
      tempStyleData = res;
      fontSizecontroller.text = "";
    });
  }

  getReportCategory() async {
    var res = await configurationService.getReportCategory();
    setState(() {
      reportCategoryData = res;
      reportCategorycontroller.text = "";
      selCategoryIndex = -1;
    });
  }

  getFontFamily() async {
    var res = await configurationService.getFontFamily();
    setState(() {
      fontFamilyData = res;
      fontFamilycontroller.text = "";
      selfontFamilyIndex = -1;
    });
  }

  getPassword() async {
    var res = await passwordService.getConfiguration();
    if (res.isNotEmpty) {
      List<PasswordModel> passwordconfigData = res;
      if (passwordconfigData.isNotEmpty) {
        setState(() {
          currentPass = passwordconfigData[0].password ?? '';
          var temp = (passwordconfigData[0].duration) ?? '-';
          if (temp != '-' && temp != "") {
            passwordChangedDuration = temp.split('.').first;
          } else {
            passwordChangedDuration = '-';
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getConfigData();
    getReportCategory();
    getTemplateStyleData();
    getFontFamily();
    getPassword();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            configList(),
            Expanded(
                child: selectedIndex == 0
                    ? autoDelete()
                    : selectedIndex == 1
                        ? syncTime()
                        : selectedIndex == 2
                            ? imageCaption()
                            : selectedIndex == 3
                                ? wifiOrUsb()
                                : selectedIndex == 4
                                    ? changePassword()
                                    : const SizedBox())
          ],
        ),
      ),
    );
  }

  configList() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: Sizing().height(1, 2),
            horizontal: Sizing.width(5, 5),
          ),
          child: Row(
            children: [
              Container(
                  height: Sizing().height(20, 20),
                  width: Sizing.width(20, 100),
                  decoration: BoxDecoration(
                    color: selectedIndex == 0
                        ? Colors.indigo[200]
                        : const Color(0xfff6f6f6),
                    borderRadius: selectedIndex == 0
                        ? BorderRadius.circular(10.0)
                        : BorderRadius.zero,
                    boxShadow: [
                      selectedIndex == 0
                          ? const BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5.0,
                            )
                          : const BoxShadow(
                              blurRadius: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(top: Sizing().height(2, 3)),
                  margin: EdgeInsets.only(
                    left: Sizing.width(2, 3),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        selectedIndex = 0;
                      });
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.delete,
                        color: whiteColor,
                        size: Sizing().height(5, 5),
                      ),
                    ),
                    title: Text(
                      'Auto delete target days',
                      style: TextStyle(
                        color: selectedIndex == 0 ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: selectedIndex == 0
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                  )),
              Container(
                  height: Sizing().height(20, 20),
                  width: Sizing.width(20, 100),
                  decoration: BoxDecoration(
                    color: selectedIndex == 1
                        ? Colors.indigo[200]
                        : const Color(0xfff6f6f6),
                    borderRadius: selectedIndex == 1
                        ? BorderRadius.circular(10.0)
                        : BorderRadius.zero,
                    boxShadow: [
                      selectedIndex == 1
                          ? const BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5.0,
                            )
                          : const BoxShadow(
                              blurRadius: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(top: Sizing().height(2, 3)),
                  margin: EdgeInsets.only(
                    left: Sizing.width(2, 3),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        selectedIndex = 1;
                      });
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.alarm,
                        color: whiteColor,
                        size: Sizing().height(5, 5),
                      ),
                    ),
                    title: Text(
                      'Sync expiry time',
                      style: TextStyle(
                        color: selectedIndex == 1 ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: selectedIndex == 1
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                  )),
              Container(
                  height: Sizing().height(20, 20),
                  width: Sizing.width(20, 100),
                  decoration: BoxDecoration(
                    color: selectedIndex == 2
                        ? Colors.indigo[200]
                        : const Color(0xfff6f6f6),
                    borderRadius: selectedIndex == 2
                        ? BorderRadius.circular(10.0)
                        : BorderRadius.zero,
                    boxShadow: [
                      selectedIndex == 2
                          ? const BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5.0,
                            )
                          : const BoxShadow(
                              blurRadius: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(top: Sizing().height(2, 3)),
                  margin: EdgeInsets.only(
                    left: Sizing.width(2, 3),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.image,
                        color: whiteColor,
                        size: Sizing().height(5, 5),
                      ),
                    ),
                    title: Text(
                      'Image caption',
                      style: TextStyle(
                        color: selectedIndex == 2 ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: selectedIndex == 2
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Sizing.width(5, 5),
          ),
          child: Row(
            children: [
              Container(
                  height: Sizing().height(20, 20),
                  width: Sizing.width(20, 100),
                  decoration: BoxDecoration(
                    color: selectedIndex == 3
                        ? Colors.indigo[200]
                        : const Color(0xfff6f6f6),
                    borderRadius: selectedIndex == 3
                        ? BorderRadius.circular(10.0)
                        : BorderRadius.zero,
                    boxShadow: [
                      selectedIndex == 3
                          ? const BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5.0,
                            )
                          : const BoxShadow(
                              blurRadius: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(top: Sizing().height(2, 3)),
                  margin: EdgeInsets.only(
                    left: Sizing.width(2, 3),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        selectedIndex = 3;
                      });
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.toggle_on,
                        color: whiteColor,
                        size: Sizing().height(5, 5),
                      ),
                    ),
                    title: Text(
                      'Wifi / USB',
                      style: TextStyle(
                        color: selectedIndex == 3 ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: selectedIndex == 3
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                  )),
              Container(
                  height: Sizing().height(20, 20),
                  width: Sizing.width(20, 100),
                  decoration: BoxDecoration(
                    color: selectedIndex == 4
                        ? Colors.indigo[200]
                        : const Color(0xfff6f6f6),
                    borderRadius: selectedIndex == 4
                        ? BorderRadius.circular(10.0)
                        : BorderRadius.zero,
                    boxShadow: [
                      selectedIndex == 4
                          ? const BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5.0,
                            )
                          : const BoxShadow(
                              blurRadius: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(top: Sizing().height(2, 3)),
                  margin: EdgeInsets.only(
                    left: Sizing.width(2, 3),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        selectedIndex = 4;
                      });
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.orange[300],
                      child: Icon(
                        Icons.key,
                        color: whiteColor,
                        size: Sizing().height(5, 5),
                      ),
                    ),
                    title: Text(
                      'Change password',
                      style: TextStyle(
                        color: selectedIndex == 4 ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: selectedIndex == 4
                            ? FontWeight.w500
                            : FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),
        )
      ],
    );
  }

  autoDelete() {
    autoDeletecontroller.text =
        configData.isNotEmpty ? configData.first.targetDays.toString() : "0";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: Sizing().height(4, 10),
                bottom: Sizing().height(4, 10),
                left: Sizing().height(4, 10),
              ),
              child: Text('Auto delete target days',
                  style: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: blackColor)),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: Sizing.width(2, 2), top: Sizing().height(2, 1)),
              child: JustTheTooltip(
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'File(s) and Folder(s) will be deleted automatically after <${configData.isNotEmpty ? configData.first.targetDays : 0}> day(s) in mobile application',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? const TextStyle(fontSize: 17, color: blackColor)
                          : const TextStyle(fontSize: 12, color: blackColor),
                    ),
                  ),
                  child: Icon(
                    Icons.info,
                    color: greyColor,
                    size: Sizing().height(4, 5),
                  )),
            )
          ],
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizing.width(15, 20)),
              child: SizedBox(
                width: Sizing.width(100, 150),
                child: TextFormField(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  controller: autoDeletecontroller,
                  cursorColor: primaryColor,
                  style: TextStyle(fontSize: Sizing().height(2, 3)),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryColor,
                        ),
                      ),
                      labelText: 'Target days',
                      labelStyle: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3))),
                  onChanged: (value) {
                    if (value != "") {
                      configData[0].targetDays = int.parse(value);
                    }
                  },
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  if (int.parse(autoDeletecontroller.text) > 0) {
                    if (autoDeletecontroller.text != "") {
                      bool res =
                          await configurationService.saveConfig(configData);
                      if (res) {
                        getConfigData();
                      }
                      CherryToast.success(
                              title: Text(
                                "Saved successfully",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    } else {
                      CherryToast.error(
                              title: Text(
                                "Please enter target days",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  } else {
                    CherryToast.error(
                            title: Text(
                              "Invalid target day",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  }
                } on Exception catch (e) {
                  rethrow;
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(7, 8),
                    vertical: Sizing().height(1, 2)),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  'Save',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                ),
              ),
            )
          ],
        ),
        SizedBox(
          height: Sizing().height(10, 10),
        ),
        Padding(
          padding: EdgeInsets.only(left: Sizing.width(4, 17)),
          child: Text(
              'Current Auto delete target day : ${configData.isNotEmpty ? configData.first.targetDays : 0}',
              style:
                  Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: blackColor)),
        )
      ],
    );
  }

  imageCaption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: Sizing().height(4, 10),
                bottom: Sizing().height(4, 10),
                left: Sizing().height(4, 10),
              ),
              child: Text('Image Caption',
                  style: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: blackColor)),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: Sizing.width(2, 2), top: Sizing().height(2, 1)),
              child: JustTheTooltip(
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Image caption will be listed as caption values while adding image through mobile and windows application. Ex: Top, Bottom, Left, Right, Right Top, Bottom Left.',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? const TextStyle(fontSize: 17, color: blackColor)
                          : const TextStyle(fontSize: 12, color: blackColor),
                    ),
                  ),
                  child: Icon(
                    Icons.info,
                    color: greyColor,
                    size: Sizing().height(4, 5),
                  )),
            ),
          ],
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizing.width(15, 20)),
              child: SizedBox(
                width: Sizing.width(100, 150),
                child: TextFormField(
                  controller: imageCaptioncontroller,
                  cursorColor: primaryColor,
                  style: TextStyle(fontSize: Sizing().height(2, 3)),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryColor,
                        ),
                      ),
                      labelText: 'Create caption',
                      labelStyle: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3))),
                  onChanged: (value) {
                    if (value != "") {
                      if (selCaptionIndex > -1) {
                        configData[selCaptionIndex].captionName = value;
                      }
                    }
                  },
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  if (imageCaptioncontroller.text != "") {
                    if (selCaptionIndex == -1) {
                      configData.add(ConfigurationModel(
                          targetDays: configData.first.targetDays,
                          syncExpTime: configData.first.syncExpTime,
                          captionID: configData.length,
                          captionName: imageCaptioncontroller.text,
                          password: configData.first.password,
                          wifiOrUsb: configData.first.wifiOrUsb));
                    }
                    bool res =
                        await configurationService.saveConfig(configData);
                    if (res) {
                      getConfigData();
                    }
                    CherryToast.success(
                            title: Text(
                              "Saved successfully",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  } else {
                    CherryToast.error(
                            title: Text(
                              "Please enter caption",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  }
                } on Exception catch (e) {
                  rethrow;
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(7, 8),
                    vertical: Sizing().height(1, 2)),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  'Save',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: Sizing.width(5, 10),
                  vertical: Sizing().height(5, 10)),
              padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(5, 5),
                  vertical: Sizing().height(5, 2)),
              decoration: BoxDecoration(
                  color: const Color(0xfff6f6f6),
                  borderRadius: BorderRadius.circular(10)),
              child: DataTable(
                  columnSpacing: Sizing().height(30, 30),
                  columns: [
                    DataColumn(
                      label: Text('ID',
                          style: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? const TextStyle(
                                  fontSize: 17,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : const TextStyle(
                                  fontSize: 12,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )),
                    ),
                    DataColumn(
                      label: Text('Caption',
                          style: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? const TextStyle(
                                  fontSize: 17,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : const TextStyle(
                                  fontSize: 12,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )),
                    ),
                    DataColumn(
                      label: Text('Action',
                          style: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? const TextStyle(
                                  fontSize: 17,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )
                              : const TextStyle(
                                  fontSize: 12,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                )),
                    ),
                  ],
                  rows: getCaptionRows()),
            ),
          ),
        )
      ],
    );
  }

  getCaptionRows() {
    List<DataRow> wigts = [];

    if (configData.isNotEmpty && configData.length > 1) {
      for (int i = 0; i < configData.length; i++) {
        if (i > 0) {
          wigts.add(DataRow(cells: [
            DataCell(Text("${configData[i].captionID}",
                style:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? const TextStyle(fontSize: 17, color: blackColor)
                        : const TextStyle(fontSize: 12, color: Colors.black))),
            DataCell(Text(
              '${configData[i].captionName}',
              style:
                  Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(fontSize: 12, color: Colors.black),
            )),
            DataCell(Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                    tooltip: 'Edit',
                    onPressed: () {
                      setState(() {
                        selCaptionIndex = configData.indexWhere((element) =>
                            element.captionID == configData[i].captionID);
                        imageCaptioncontroller.text =
                            configData[i].captionName ?? '';
                      });
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: Sizing().height(10, 5),
                    )),
                IconButton(
                    tooltip: 'Delete',
                    onPressed: () async {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Are you sure, want to delete?',
                                    style: TextStyle(
                                        fontSize: Sizing().height(2, 3.5),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(
                                    height: Sizing().height(8, 6),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: greyColor,
                                            borderRadius:
                                                BorderRadius.circular(2)),
                                        child: TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'No',
                                              style: TextStyle(
                                                  fontSize: Platform.isWindows
                                                      ? Sizing().height(2, 3)
                                                      : 12,
                                                  color: whiteColor),
                                            )),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: Sizing.width(2, 2)),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(2)),
                                        child: TextButton(
                                            onPressed: () async {
                                              try {
                                                configData.removeWhere((d) =>
                                                    d.captionID ==
                                                    configData[i].captionID);
                                                bool res =
                                                    await configurationService
                                                        .saveConfig(configData);
                                                if (res) {
                                                  getConfigData();
                                                }

                                                Navigator.pop(context);
                                                CherryToast.success(
                                                        title: Text(
                                                          "Deleted successfully",
                                                          style: TextStyle(
                                                              fontSize: Sizing()
                                                                  .height(
                                                                      5, 3)),
                                                        ),
                                                        animationType:
                                                            AnimationType
                                                                .fromRight,
                                                        autoDismiss: true)
                                                    .show(context);
                                              } on Exception catch (e) {
                                                errorLog.add(ErrorLogModel(
                                                    errorDescription:
                                                        e.toString(),
                                                    duration: DateTime.now()
                                                        .toString()));
                                                errorLogService
                                                    .saveErrorLog(errorLog);
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: Text(
                                              'Yes',
                                              style: TextStyle(
                                                  fontSize: Platform.isWindows
                                                      ? Sizing().height(2, 3)
                                                      : 12,
                                                  color: whiteColor),
                                            )),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          });
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: Sizing().height(10, 5),
                    ))
              ],
            )),
          ]));
        }
      }
    } else {
      wigts.add(DataRow(cells: [
        const DataCell(Text("")),
        DataCell(Text(
          "No data",
          style: TextStyle(
              color: Colors.black38, fontSize: Sizing().height(5, 3.5)),
        )),
        const DataCell(Text("")),
      ]));
    }
    return wigts;
  }

  syncTime() {
    syncExpirycontroller.text =
        configData.isNotEmpty ? configData.first.syncExpTime.toString() : "0";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: Sizing().height(4, 10),
                bottom: Sizing().height(4, 10),
                left: Sizing().height(4, 10),
              ),
              child: Text('Sync expiry time',
                  style: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: blackColor)),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: Sizing.width(2, 2), top: Sizing().height(2, 1)),
              child: JustTheTooltip(
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'User will be notified with an alert in mobile application if the sync is not happened after <${configData.isNotEmpty ? configData.first.syncExpTime : 0}> hour(s) of waiting period',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? const TextStyle(fontSize: 17, color: blackColor)
                          : const TextStyle(fontSize: 12, color: blackColor),
                    ),
                  ),
                  child: Icon(
                    Icons.info,
                    color: greyColor,
                    size: Sizing().height(4, 5),
                  )),
            ),
          ],
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizing.width(15, 20)),
              child: SizedBox(
                width: Sizing.width(100, 150),
                child: TextFormField(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  controller: syncExpirycontroller,
                  cursorColor: primaryColor,
                  style: TextStyle(fontSize: Sizing().height(2, 3)),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryColor,
                        ),
                      ),
                      labelText: 'Create expiry hour',
                      labelStyle: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3))),
                  onChanged: (value) {
                    if (value != "") {
                      configData[0].syncExpTime = int.parse(value);
                    }
                  },
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  if (int.parse(syncExpirycontroller.text) > 0) {
                    if (syncExpirycontroller.text != "") {
                      bool res =
                          await configurationService.saveConfig(configData);
                      if (res) {
                        getConfigData();
                      }

                      CherryToast.success(
                              title: Text(
                                "Saved successfully",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    } else {
                      CherryToast.error(
                              title: Text(
                                "Please enter expiry hour",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  } else {
                    CherryToast.error(
                            title: Text(
                              "Invalid expiry hour",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  }
                } on Exception catch (e) {
                  rethrow;
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(7, 8),
                    vertical: Sizing().height(1, 2)),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  'Save',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                ),
              ),
            )
          ],
        ),
        SizedBox(
          height: Sizing().height(10, 10),
        ),
        Padding(
          padding: EdgeInsets.only(left: Sizing.width(4, 17)),
          child: Text(
            'Current sync expiry hour :  ${configData.isNotEmpty ? configData.first.syncExpTime : 0}',
            style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                ? const TextStyle(fontSize: 17, color: blackColor)
                : const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: blackColor),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  wifiOrUsb() {
    return Padding(
      padding: EdgeInsets.only(
          top: Sizing().height(5, 10), left: Sizing.width(5, 10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: Sizing().height(5, 3)),
            child: Row(
              children: [
                Text('Enable WiFi / USB',
                    style: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? const TextStyle(fontSize: 17, color: blackColor)
                        : const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: blackColor)),
                Padding(
                  padding: EdgeInsets.only(
                      left: Sizing.width(2, 2), top: Sizing().height(2, 1)),
                  child: JustTheTooltip(
                      content: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Enabled sync mode(WiFi and/or USB) will be reflected in the dashboard of the windows application',
                          style: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? const TextStyle(fontSize: 17, color: blackColor)
                              : const TextStyle(
                                  fontSize: 12, color: blackColor),
                        ),
                      ),
                      child: Icon(
                        Icons.info,
                        color: greyColor,
                        size: Sizing().height(4, 5),
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          ToggleButtons(
            direction: Axis.horizontal,
            onPressed: (int index) async {
              usbOrWifi[index] = !usbOrWifi[index];
              configData.first.wifiOrUsb = '${usbOrWifi[0]}|${usbOrWifi[1]}';
              bool res = await configurationService.saveConfig(configData);
              if (res) {
                getConfigData();
              }
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            selectedBorderColor: Colors.green[700],
            selectedColor: Colors.white,
            fillColor: Colors.green[200],
            color: Colors.green[400],
            constraints: const BoxConstraints(
              minHeight: 40.0,
              minWidth: 80.0,
            ),
            isSelected: usbOrWifi,
            children: const [Text('Wifi'), Text('USB')],
          )
        ],
      ),
    );
  }

  changePassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: Sizing().height(4, 10),
                bottom: Sizing().height(4, 1),
                left: Sizing().height(4, 10),
              ),
              child: Text('Change password',
                  style: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? const TextStyle(fontSize: 17, color: blackColor)
                      : const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: blackColor)),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: Sizing.width(2, 2), top: Sizing().height(2, 10)),
              child: JustTheTooltip(
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'User are allowed to change the configuration password. Current password is mandatory to change with new password',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? const TextStyle(fontSize: 17, color: blackColor)
                          : const TextStyle(fontSize: 12, color: blackColor),
                    ),
                  ),
                  child: Icon(
                    Icons.info,
                    color: greyColor,
                    size: Sizing().height(4, 5),
                  )),
            ),
          ],
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: Sizing.width(15, 20), right: Sizing.width(5, 10)),
              child: SizedBox(
                width: Sizing.width(50, 100),
                child: TextFormField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  obscureText: currentPasswordVisible ? false : true,
                  obscuringCharacter: '*',
                  controller: changePasswordcontroller,
                  cursorColor: primaryColor,
                  style: TextStyle(fontSize: Sizing().height(2, 4)),
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          currentPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                          size: Sizing().height(5, 4),
                        ),
                        onPressed: () {
                          setState(
                            () {
                              currentPasswordVisible = !currentPasswordVisible;
                            },
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryColor,
                        ),
                      ),
                      labelText: 'Current password',
                      labelStyle: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3))),
                  onChanged: (value) {
                    if (value != "" && value == currentPass) {
                      setState(() {
                        passwordVerified = false;
                      });
                    } else {
                      setState(() {
                        passwordVerified = true;
                      });
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: Sizing.width(3, 10), top: Sizing().height(3, 6)),
              child: SizedBox(
                width: Sizing.width(50, 100),
                child: TextFormField(
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  obscureText: newPasswordVisible ? false : true,
                  obscuringCharacter: '*',
                  controller: newPasswordcontroller,
                  cursorColor: primaryColor,
                  style: TextStyle(fontSize: Sizing().height(2, 4)),
                  decoration: InputDecoration(
                      helperText: '*Minimum character length : 5',
                      suffixIcon: IconButton(
                        icon: Icon(
                          newPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                          size: Sizing().height(5, 4),
                        ),
                        onPressed: () {
                          setState(
                            () {
                              newPasswordVisible = !newPasswordVisible;
                            },
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryColor,
                        ),
                      ),
                      labelText: 'New password',
                      labelStyle: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3))),
                  onChanged: (value) {
                    if (value != "") {}
                  },
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  if (newPasswordcontroller.text == "" ||
                      changePasswordcontroller.text == "") {
                    CherryToast.error(
                            title: Text(
                              "All the fields are required",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  } else {
                    if (passwordVerified == false) {
                      if (newPasswordcontroller.text.length >= 5) {
                        PasswordModel passData = PasswordModel();
                        List<PasswordModel> passDataList = [];
                        passData.password = newPasswordcontroller.text;
                        passData.duration = DateTime.now().toString();
                        passDataList.add(passData);
                        bool res =
                            await passwordService.savePassword(passDataList);
                        if (res) {
                          getPassword();
                          setState(() {
                            newPasswordcontroller.text = '';
                            changePasswordcontroller.text = '';
                          });
                        }

                        CherryToast.success(
                                title: Text(
                                  "Password changed successfully",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      } else {
                        CherryToast.error(
                                title: Text(
                                  "New password should have a minimum character length of 5",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      }
                    } else {
                      CherryToast.error(
                              title: Text(
                                "Current password is invalid",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  }
                } on Exception catch (e) {
                  rethrow;
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(7, 8),
                    vertical: Sizing().height(1, 2)),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                ),
              ),
            )
          ],
        ),
        passwordVerified
            ? Row(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Sizing.width(15, 20)),
                    child: Text(
                      'Current password is invalid',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                ],
              )
            : SizedBox(),
        SizedBox(
          height: Sizing().height(5, 3),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: Sizing.width(4, 17), top: Sizing().height(2, 2)),
          child: Text(
            'Last password changed duration :  $passwordChangedDuration',
            style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                ? const TextStyle(fontSize: 17, color: blackColor)
                : const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: blackColor),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}
