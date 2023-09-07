// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:USB_Share/Configuration/Model/password_model.dart';
import 'package:USB_Share/Configuration/Service/password_service.dart';
import 'package:USB_Share/Configuration/config_page.dart';
import 'package:USB_Share/Dashboard/Model/SyncDeviceHistoryModel.dart';
import 'package:USB_Share/Dashboard/Model/SyncHistoryModel.dart';
import 'package:USB_Share/Dashboard/Service/dashboard_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Splash/Page/LicenseKeyDialog.dart';
import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Page/generateReport.dart';
import 'package:USB_Share/Template/Page/templatePage.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/Util/schedulerLicense.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:USB_Share/services/photon_sender.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:USB_Share/AddImage/Model/addImage_model.dart';
import 'package:USB_Share/AddImage/Service/add_Image_service.dart';
import 'package:USB_Share/Configuration/Model/config_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/Dashboard/Bloc/dashboardBloc.dart';
import 'package:USB_Share/Project/Model/projectModel.dart';
import 'package:USB_Share/Project/Page/project_folder_page.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/hive_helper.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';
import 'package:USB_Share/methods/handle_share.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

const channerID = '1000';
const channerName = 'Photo_App';

class DashboardPage extends StatefulWidget {
  final int index;
  final bool newProjCreated;
  const DashboardPage(
      {super.key, required this.index, required this.newProjCreated});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  List<String> projList = [];
  List<DirectoryInfo>? tempList = [];
  String searchValue = "";
  final imageService = ImageService();
  final configurationService = ConfigurationService();
  int syncAlertPeriod = 0;
  List<ImageLogModel> imageData = [];
  List<String> imgName = [];
  List<ImageLogModel> imageLog = [];
  List<DirectoryInfo> directoryInfo = [];
  bool isSync = false;
  String progressResult = "";
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  final projTempService = ProjectAndTemplateMapService();
  final syncHistoryService = DashboardService();
  List<String> imageTypes = ['jpg', 'jpeg', 'png'];
  int selectedIndex = 0;
  bool showUsb = true;
  bool showWifi = false;
  String lastSyncedTime = "";
  int sharedFileCount = 0;
  int androidSharedFileCount = 0;
  int windowsSharedFileCount = 0;
  int imageFileCount = 0;
  List<SyncHistoryModel> syncedHistoryList = [];
  String lastsyncedDeviceIMEIID = '';
  final List<Duration> sampleSyncTimes = [
    Duration(seconds: 2), // Sample sync time for a small file
    Duration(seconds: 5), // Sample sync time for a medium file
    Duration(seconds: 10), // Sample sync time for a large file
  ];
  String dirFolderName = "";
  String dirConfigFolderName = "";
  List<ConfigurationModel> configDetail = [];
  bool isSearching = false;
  List<DirectoryInfo> finalProjList = [];
  double windowsAppversion = 0.0;
  String fromDate = '';
  String toDate = '';
  String macAdd = '';

  @override
  void initState() {
    super.initState();
    getLicenseInfo();
    bool licenseStatus = HiveHelper().getLicenseKeyStatus();
    Timer(const Duration(seconds: 1), () {
      if (licenseStatus == false) {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return CheckLicenseAuthentication(
                isRenewal: false,
              );
            });
      }
    });

    setState(() {
      dirFolderName = Constants.directoryFolderName;
      dirConfigFolderName = Constants.dataFolder;
    });
    //getFileAccessPermission();
    getFiles();
    updateSelectedIndex();
    getWindowsAppVersion();
    getSyncDeviceData();
    checkNewProjAdded();
    if (Platform.isAndroid) {
      Timer(Duration(hours: 1), () {
        checkSyncStatus();
      });
    }
    getWifiOrUsb();
    getLastSyncTime();
    if (licenseStatus) {
      runScheduler();
    }
  }

  runScheduler() async {
    DateTime now = DateTime.now();
    String currentDate = Constants.dateAloneFormat.format(now);
    String licenseAlertDate = HiveHelper().getLicenseExpiryAlertDate();

    if (licenseAlertDate != currentDate || licenseAlertDate == "") {
      await LicenseScheduler().runScheduler(context);
      HiveHelper().saveLicenseExpiryAlertDate(currentDate);
    }
  }

  getLicenseInfo() async {
    Directory dir = await Constants.getDataDirectory();
    String licenseFilePath = '${dir.path}/licenseInfo.txt';
    File file = File(licenseFilePath);
    if (file.existsSync()) {
      String licenceData = await file.readAsString();
      List<String> info = licenceData.split(',');
      fromDate = info[1].replaceAll("'", "").trim().split('.').first;
      toDate = info[2].replaceAll("'", "").trim().split('.').first;
      setState(() {
        macAdd = info[0].trim();
        fromDate =
            Constants.modifiedDateFormat.format(DateTime.parse(fromDate));
        toDate = Constants.modifiedDateFormat.format(DateTime.parse(toDate));
      });
    }
  }

  getLastSyncTime() async {
    var res = await syncHistoryService.getSyncHistory();
    setState(() {
      syncedHistoryList = res;
    });
  }

  getSyncDeviceData() async {
    var res = await syncHistoryService.getSyncDeviceHistory();
    if (res.isNotEmpty) {
      setState(() {
        lastsyncedDeviceIMEIID = res.first.deviceID ?? '';
      });
    }
  }

  getWindowsAppVersion() async {
    var res = await syncHistoryService.getversionHistory();
    if (res.isNotEmpty) {
      setState(() {
        windowsAppversion = res.first.version ?? 0.0;
      });
    }
  }

  getWifiOrUsb() async {
    List<ConfigurationModel> res =
        await configurationService.getConfiguration();
    if (res.isNotEmpty) {
      List<String> temp = res.first.wifiOrUsb!.split('|');
      setState(() {
        configDetail = res;
        showWifi = temp[0] == 'true';
        showUsb = temp[1] == 'true';
      });
    }
  }

  updateSelectedIndex() {
    if (widget.index == 3) {
      setState(() {
        selectedIndex = widget.index;
      });
    } else {
      selectedIndex = selectedIndex;
    }
  }

  checkNewProjAdded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.newProjCreated && session.isEdit) {
        CherryToast.success(
                title: Text(
                  "Project renamed successfully",
                  style: TextStyle(fontSize: Sizing().height(5, 3)),
                ),
                autoDismiss: true)
            .show(context);
      } else if (widget.newProjCreated) {
        CherryToast.success(
                title: Text(
                  "Project created successfully",
                  style: TextStyle(fontSize: Sizing().height(5, 3)),
                ),
                autoDismiss: true)
            .show(context);
      }

      setState(() {
        session.isEdit = false;
      });
    });
  }

  getFileAccessPermission() async {
    var status = await Permission.manageExternalStorage.isGranted;
    if (status == false) {
      await Permission.manageExternalStorage.request();
    }
  }

  List<FileSystemEntity> entities = [];
  List<DirectoryInfo>? recentProj = [];
  void getFiles() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory('${directory.path}$dirFolderName');
    if (!await dir.exists()) {
      final storagePermissionStatus = await Permission.storage.request();
      if (storagePermissionStatus.isGranted) {
        await dir.create(recursive: true);
      }
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
    try {
      directoryInfo = [];
      entities = dir.listSync();
      List<String?> sessionProject =
          session.newAddedProj.map<String?>((e) => e.path).toList();
      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in entities) {
          if (entity is Directory) {
            var path = Platform.isWindows
                ? entity.path.split('\\').last
                : entity.path.split('/').last;
            // check with session list for new added project
            if (!sessionProject.contains(path)) {
              final stat = entity.statSync();
              final modifiedDate = stat.modified;
              directoryInfo.add(DirectoryInfo(
                  modifiedDate: modifiedDate.toString(), path: entity.path));
            }
          }
        }
        directoryInfo.addAll(session.newAddedProj);
      }
      //Sort the directory by modified date
      directoryInfo.sort((a, b) => b.modifiedDate!.compareTo(a.modifiedDate!));

      //Remove deleted project
      if (directoryInfo.isNotEmpty) {
        directoryInfo.removeWhere((element) {
          return session.deletedProject
              .contains((element.path ?? '').split('\\').last);
        });
      }

      //Remove zip file and PhotSync folder
      directoryInfo.removeWhere((element) => (element.path ?? "")
          .split('/')
          .last
          .toLowerCase()
          .contains("template"));
      directoryInfo.removeWhere((element) =>
          (element.path ?? "").split('/').last.toLowerCase().contains(".zip"));

      directoryInfo.removeWhere((element) => (element.path ?? "")
          .split('/')
          .last
          .toLowerCase()
          .contains("projectfolderbackup"));
      directoryInfo.removeWhere((element) => (element.path ?? "")
          .split('/')
          .last
          .toLowerCase()
          .contains("photosync"));

      if (mounted) {
        setState(() {
          if (directoryInfo.isNotEmpty) {
            //take recent 10 project
            recentProj = directoryInfo.take(10).toList();
            //remove template folder
            if (recentProj != null && recentProj!.isNotEmpty) {
              if (session.editedProjWindows.isNotEmpty) {
                recentProj!.removeWhere((elem) => session.editedProjWindows
                    .contains((elem.path ?? "").split('/').last));
              }
            }
            finalProjList = directoryInfo.toList();
            if (finalProjList.isNotEmpty) {
              if (session.editedProjWindows.isNotEmpty) {
                finalProjList.removeWhere((elem) => session.editedProjWindows
                    .contains((elem.path ?? "").split('/').last));
              }
            }
          } else if (directoryInfo.isEmpty) {
            recentProj = [];
            finalProjList = [];
          }
          loading = false;
        });
      }

      for (int i = 0; i < finalProjList.length; i++) {
        if (Platform.isWindows) {
          projList.add((finalProjList[i].path ?? '').split('\\').last);
        } else if (Platform.isAndroid) {
          projList.add((finalProjList[i].path ?? '').split('/').last);
        }
      }
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  checkSyncStatus() async {
    try {
      String syncedTime = HiveHelper().getSyncedTime();
      var configData = await configurationService.getConfiguration();
      syncAlertPeriod = configData.first.syncExpTime ?? 0;
      int configHour = (configData.first.syncExpTime) ?? 0;
      if (syncedTime != "") {
        DateTime checkwithHour =
            DateTime.parse(syncedTime).add(Duration(hours: configHour));
        DateTime now = DateTime.now();
        if (now == checkwithHour) {
          showNotification();
        }
      }
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  Future<void> showNotification() async {
    FlutterLocalNotificationsPlugin flp = FlutterLocalNotificationsPlugin();

    flp.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('notification_badge')),
      onDidReceiveNotificationResponse: (details) {},
    );
    var android = const AndroidNotificationDetails(channerID, channerName,
        priority: Priority.high,
        importance: Importance.max,
        color: primaryColor,
        enableLights: true,
        enableVibration: true,
        setAsGroupSummary: true,
        styleInformation: BigTextStyleInformation(
          "",
          htmlFormatContentTitle: true,
          htmlFormatBigText: true,
        ));
    var platform = NotificationDetails(android: android);

    String heading = CommonUi.capitalize('Sync Alert');
    await flp.show(
      0,
      heading,
      'Device(s) not synced more than ${syncAlertPeriod.toString()} hours',
      platform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: WillPopScope(
            onWillPop: () async => false,
            child: Row(
              children: [
                menuList(),
                selectedIndex == 0
                    ? dashboardList()
                    : selectedIndex == 1
                        ? GenerateReport()
                        : selectedIndex == 2
                            ? TemplatePage()
                            : selectedIndex == 3
                                ? ConfigurationPage()
                                : dashboardList(),
                syncHistory(),
              ],
            )),
      ),
    );
  }

  menuList() {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(color: Color(0xfff6f6f6)),
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                margin: EdgeInsets.only(top: Sizing().height(5, 5)),
                height: Sizing().height(50, 20),
                child: Image.asset('assets/images/cardio_icon.png')),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: Sizing().height(0, 2)),
                  child: Text(
                    '${Constants.appName}',
                    style: TextStyle(
                        color: primaryColor, fontSize: Sizing().height(4, 3)),
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
                              padding:
                                  EdgeInsets.only(right: 10, left: 10, top: 10),
                              child: RichText(
                                text: TextSpan(
                                    text: 'MAC Address : ',
                                    style:
                                        Sizing.getScreenWidth(context) > 1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: greyColor)
                                            : const TextStyle(
                                                fontSize: 12, color: greyColor),
                                    children: [
                                      TextSpan(
                                        text: ' $macAdd',
                                        style: Sizing.getScreenWidth(context) >
                                                    1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: blackColor)
                                            : const TextStyle(
                                                fontSize: 12,
                                                color: blackColor),
                                      )
                                    ]),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 3),
                              child: Divider(),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.only(right: 10, left: 10, top: 7),
                              child: RichText(
                                text: TextSpan(
                                    text: 'From Date      : ',
                                    style:
                                        Sizing.getScreenWidth(context) > 1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: greyColor)
                                            : const TextStyle(
                                                fontSize: 12, color: greyColor),
                                    children: [
                                      TextSpan(
                                        text: ' $fromDate',
                                        style: Sizing.getScreenWidth(context) >
                                                    1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: blackColor)
                                            : const TextStyle(
                                                fontSize: 12,
                                                color: blackColor),
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
                                    style:
                                        Sizing.getScreenWidth(context) > 1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: greyColor)
                                            : const TextStyle(
                                                fontSize: 12, color: greyColor),
                                    children: [
                                      TextSpan(
                                        text: ' $toDate',
                                        style: Sizing.getScreenWidth(context) >
                                                    1000 &&
                                                !Platform.isWindows
                                            ? const TextStyle(
                                                fontSize: 17, color: blackColor)
                                            : const TextStyle(
                                                fontSize: 12,
                                                color: blackColor),
                                      )
                                    ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Sizing.width(3, 6)),
                        child: Icon(Icons.privacy_tip,
                            color: primaryColor,
                            size: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? 25
                                : Sizing().height(20, 5)),
                      )),
                ),
              ],
            ),
            Divider(
              color: Color.fromARGB(32, 0, 0, 0),
            ),
            Container(
              height: Sizing().height(5, 10),
              width: Sizing.width(300, 500),
              margin: selectedIndex == 0 || selectedIndex == 4
                  ? EdgeInsets.symmetric(
                      vertical: Sizing().height(2, 1),
                      horizontal: Sizing.width(2, 5))
                  : EdgeInsets.symmetric(),
              decoration: BoxDecoration(
                color: selectedIndex == 0 || selectedIndex == 4
                    ? Colors.indigo[200]
                    : Color(0xfff6f6f6),
                borderRadius: selectedIndex == 0 || selectedIndex == 4
                    ? BorderRadius.circular(10.0)
                    : BorderRadius.zero,
                boxShadow: [
                  selectedIndex == 0 || selectedIndex == 4
                      ? BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        )
                      : BoxShadow(
                          blurRadius: 0,
                        ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.business_center,
                    color: primaryColor,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
                title: Text('Projects',
                    style: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? TextStyle(
                            fontSize: 17,
                            color: selectedIndex == 0 || selectedIndex == 4
                                ? Colors.white
                                : primaryColor)
                        : TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selectedIndex == 0 || selectedIndex == 4
                                ? Colors.white
                                : primaryColor)),
                onTap: () {
                  setState(() {
                    selectedIndex = 0;
                    getWifiOrUsb();
                  });
                },
              ),
            ),
            // Container(
            //   height: Sizing().height(5, 10),
            //   width: Sizing.width(300, 500),
            //   margin: selectedIndex == 1
            //       ? EdgeInsets.symmetric(
            //           vertical: Sizing().height(2, 1),
            //           horizontal: Sizing.width(2, 5))
            //       : EdgeInsets.symmetric(),
            //   decoration: BoxDecoration(
            //     color:
            //         selectedIndex == 1 ? Colors.indigo[200] : Color(0xfff6f6f6),
            //     borderRadius: selectedIndex == 1
            //         ? BorderRadius.circular(10.0)
            //         : BorderRadius.zero,
            //     boxShadow: [
            //       selectedIndex == 1
            //           ? BoxShadow(
            //               color: Colors.grey,
            //               blurRadius: 5.0,
            //             )
            //           : BoxShadow(
            //               blurRadius: 0,
            //             ),
            //     ],
            //   ),
            //   child: ListTile(
            //     leading: Icon(Icons.edit_document,
            //         color: primaryColor,
            //         size: Sizing.getScreenWidth(context) > 1000 &&
            //                 !Platform.isWindows
            //             ? 25
            //             : Sizing().height(20, 5)),
            //     title: Text('Prepare Report',
            //         style: Sizing.getScreenWidth(context) > 1000 &&
            //                 !Platform.isWindows
            //             ? TextStyle(
            //                 fontSize: 17,
            //                 color: selectedIndex == 1
            //                     ? Colors.white
            //                     : primaryColor)
            //             : TextStyle(
            //                 fontSize: 12,
            //                 fontWeight: FontWeight.w500,
            //                 color: selectedIndex == 1
            //                     ? Colors.white
            //                     : primaryColor)),
            //     onTap: () {
            //       setState(() {
            //         selectedIndex = 1;
            //       });
            //     },
            //   ),
            // Container(
            //   height: Sizing().height(5, 10),
            //   width: Sizing.width(300, 500),
            //   margin: selectedIndex == 2
            //       ? EdgeInsets.symmetric(
            //           vertical: Sizing().height(2, 1),
            //           horizontal: Sizing.width(2, 5))
            //       : EdgeInsets.symmetric(),
            //   decoration: BoxDecoration(
            //     color:
            //         selectedIndex == 2 ? Colors.indigo[200] : Color(0xfff6f6f6),
            //     borderRadius: selectedIndex == 2
            //         ? BorderRadius.circular(10.0)
            //         : BorderRadius.zero,
            //     boxShadow: [
            //       selectedIndex == 2
            //           ? BoxShadow(
            //               color: Colors.grey,
            //               blurRadius: 5.0,
            //             )
            //           : BoxShadow(
            //               blurRadius: 0,
            //             ),
            //     ],
            //   ),
            //   child: ListTile(
            //     leading: Icon(Icons.article,
            //         color: primaryColor,
            //         size: Sizing.getScreenWidth(context) > 1000 &&
            //                 !Platform.isWindows
            //             ? 25
            //             : Sizing().height(20, 5)),
            //     title: Text('Report Template',
            //         style: Sizing.getScreenWidth(context) > 1000 &&
            //                 !Platform.isWindows
            //             ? TextStyle(
            //                 fontSize: 17,
            //                 color: selectedIndex == 2
            //                     ? Colors.white
            //                     : primaryColor)
            //             : TextStyle(
            //                 fontSize: 12,
            //                 fontWeight: FontWeight.w500,
            //                 color: selectedIndex == 2
            //                     ? Colors.white
            //                     : primaryColor)),
            //     onTap: () async {
            //       setState(() {
            //         selectedIndex = 2;
            //       });
            //     },
            //   ),
            // ),
            Container(
              height: Sizing().height(5, 10),
              width: Sizing.width(300, 500),
              margin: selectedIndex == 3
                  ? EdgeInsets.symmetric(
                      vertical: Sizing().height(2, 1),
                      horizontal: Sizing.width(2, 5))
                  : EdgeInsets.symmetric(),
              decoration: BoxDecoration(
                color:
                    selectedIndex == 3 ? Colors.indigo[200] : Color(0xfff6f6f6),
                borderRadius: selectedIndex == 3
                    ? BorderRadius.circular(10.0)
                    : BorderRadius.zero,
                boxShadow: [
                  selectedIndex == 3
                      ? BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        )
                      : BoxShadow(
                          blurRadius: 0,
                        ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.settings,
                    color: primaryColor,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
                title: Text('Configuration',
                    style: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? TextStyle(
                            fontSize: 17,
                            color: selectedIndex == 3
                                ? Colors.white
                                : primaryColor)
                        : TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selectedIndex == 3
                                ? Colors.white
                                : primaryColor)),
                onTap: selectedIndex != 3
                    ? () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return configPasswordCheck();
                            });
                      }
                    : () {},
              ),
            ),

            Container(
              height: Sizing().height(5, 10),
              width: Sizing.width(300, 500),
              decoration: BoxDecoration(
                color: Color(0xfff6f6f6),
              ),
              child: ListTile(
                leading: Icon(Icons.info,
                    color: primaryColor,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
                title: Text('About',
                    style: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? TextStyle(fontSize: 17, color: primaryColor)
                        : TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: primaryColor)),
                onTap: () async {
                  setState(() {
                    selectedIndex = 4;
                  });
                  final scriptPath = Platform.script.toFilePath();
                  final installationDirectory =
                      Directory(scriptPath).parent.path;
                  // final installationDirectory =
                  //     'C:\\Gnanalakshmi\\Svn\\Release\\Release Documents';
                  final dir = installationDirectory.replaceAll('\\', '/');
                  if (await canLaunch("file:///$dir/index.html")) {
                    await launch(
                      "file:///$dir/index.html",
                    );
                  } else {
                    print("cannot launch url ]:");
                  }
                },
              ),
            ),
            session.needToRenew
                ? Container(
                    height: Sizing().height(5, 10),
                    width: Sizing.width(300, 500),
                    margin: selectedIndex == 5
                        ? EdgeInsets.symmetric(
                            vertical: Sizing().height(2, 1),
                            horizontal: Sizing.width(2, 5))
                        : EdgeInsets.symmetric(),
                    decoration: BoxDecoration(
                      color: selectedIndex == 5
                          ? Colors.indigo[200]
                          : Color(0xfff6f6f6),
                      borderRadius: selectedIndex == 5
                          ? BorderRadius.circular(10.0)
                          : BorderRadius.zero,
                      boxShadow: [
                        selectedIndex == 5
                            ? BoxShadow(
                                color: Colors.grey,
                                blurRadius: 5.0,
                              )
                            : BoxShadow(
                                blurRadius: 0,
                              ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(Icons.help_center,
                          color: primaryColor,
                          size: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? 25
                              : Sizing().height(20, 5)),
                      title: Text('Renew license',
                          style: Sizing.getScreenWidth(context) > 1000 &&
                                  !Platform.isWindows
                              ? TextStyle(
                                  fontSize: 17,
                                  color: selectedIndex == 5
                                      ? Colors.white
                                      : primaryColor)
                              : TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selectedIndex == 5
                                      ? Colors.white
                                      : primaryColor)),
                      onTap: () {
                        setState(() {
                          selectedIndex = 5;
                        });
                        showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return CheckLicenseAuthentication(
                                isRenewal: true,
                              );
                            });
                      },
                    ),
                  )
                : SizedBox(),

            Platform.isWindows
                ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              var res = await imageService.getImageLogFile();
                              var dir = await getDownloadsDirectory();

                              if (await Permission.storage
                                  .request()
                                  .isGranted) {
                                final filePath =
                                    '${dir!.path}/Cardio_ImageLog.csv';
                                File imgLogFile = File(filePath);
                                await imgLogFile.create(recursive: true);
                                imgLogFile.writeAsBytesSync(res);

                                CherryToast.success(
                                        title: Text(
                                          "Downloaded successfully",
                                          style: TextStyle(
                                              fontSize: Sizing().height(5, 3)),
                                        ),
                                        autoDismiss: true)
                                    .show(context);
                                try {
                                  await OpenFile.open(filePath);
                                } on Exception catch (e) {
                                  CherryToast.warning(
                                          title: Text(
                                            "No application found that can open CSV / Excel files",
                                            style: TextStyle(
                                                fontSize:
                                                    Sizing().height(5, 3)),
                                          ),
                                          autoDismiss: true)
                                      .show(context);
                                }
                              } else {
                                print(
                                    'Permission to access directory not granted');
                              }
                            } on Exception catch (e) {
                              CherryToast.error(
                                      title: Text(
                                        "Download Failed",
                                        style: TextStyle(
                                            fontSize: Sizing().height(5, 3)),
                                      ),
                                      autoDismiss: true)
                                  .show(context);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: Sizing.width(10, 33),
                                vertical: Sizing().height(5, 5)),
                            decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(7)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: Sizing.width(1, 2)),
                                  child: Text(
                                    'Sync log',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: Sizing().height(5, 3)),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Sizing.width(3, 4),
                                    vertical: Sizing().height(2, 2),
                                  ),
                                  margin: EdgeInsets.symmetric(
                                      vertical: Sizing().height(5, 1.5)),
                                  decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 107, 114, 169),
                                      borderRadius: BorderRadius.circular(7)),
                                  child: Icon(
                                    Icons.download,
                                    color: Colors.white,
                                    size:
                                        Sizing.getScreenWidth(context) > 1000 &&
                                                !Platform.isWindows
                                            ? 25
                                            : Sizing().height(20, 4),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }

  Future<String> getBase64ImageData() async {
    final file = File('assets/data/assets/Cardio - BLR Logo.png');
    final imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  dashboardList() {
    return Expanded(
      flex: 4,
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: projectList(),
        ),
      ),
    );
  }

  addProjectButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return AddProject(
                  isEdit: false,
                  dirFolderName: dirFolderName,
                );
              });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Sizing.width(3, 4),
            vertical: Sizing().height(2, 2),
          ),
          margin: EdgeInsets.symmetric(
              horizontal: Sizing.width(2, 4),
              vertical: Sizing().height(5, 1.5)),
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(7)),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: Sizing.width(1, 2)),
                child: Text(
                  'Add project',
                  style: TextStyle(
                      color: Colors.white, fontSize: Sizing().height(5, 3)),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(3, 3),
                  vertical: Sizing().height(2, 1),
                ),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 107, 114, 169),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(
                  Icons.create_new_folder,
                  color: Colors.white,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  projectList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            searchBox(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Refresh for project list',
                    child: Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            CommonUi().showLoadingDialog(context);
                            Timer(const Duration(seconds: 1), () {
                              getFiles();
                              Navigator.pop(context);
                            });
                          } on Exception catch (e) {
                            errorLog.add(ErrorLogModel(
                                errorDescription: e.toString(),
                                duration: DateTime.now().toString()));
                            errorLogService.saveErrorLog(errorLog);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Sizing.width(3, 6),
                            vertical: Sizing().height(2, 3),
                          ),
                          margin: EdgeInsets.symmetric(
                              horizontal: Sizing.width(2, 4),
                              vertical: Sizing().height(5, 1.5)),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 107, 114, 169),
                              borderRadius: BorderRadius.circular(7)),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? 25
                                : Sizing().height(20, 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Add project',
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: Sizing.width(2, 12), top: 3),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AddProject(
                                  isEdit: false,
                                  dirFolderName: dirFolderName,
                                );
                              });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Sizing.width(3, 6),
                            vertical: Sizing().height(2, 3),
                          ),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 107, 114, 169),
                              borderRadius: BorderRadius.circular(7)),
                          child: Icon(
                            Icons.create_new_folder,
                            color: Colors.white,
                            size: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? 25
                                : Sizing().height(20, 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.only(
                left: Sizing.width(5, 10),
                right: Sizing.width(5, 10),
                top: Sizing().height(5, 7.5)),
            padding: EdgeInsets.symmetric(
                horizontal: Sizing.width(5, 5),
                vertical: Sizing().height(5, 2)),
            decoration: BoxDecoration(
                color: Color(0xfff6f6f6),
                borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Sizing().height(5, 3),
                    ),
                    child: isSearching ||
                            isSearching &&
                                tempList != null &&
                                tempList!.length > 0
                        ? Text('Searched project list',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? TextStyle(fontSize: 17, color: primaryColor)
                                : TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor))
                        : Text('Recent projects',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? TextStyle(fontSize: 17, color: primaryColor)
                                : TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor)),
                  ),
                  Table(
                    columnWidths: {
                      0: FlexColumnWidth(3),
                      // 1: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2)
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: projListData(),
                  ),
                  recentProj == null || recentProj!.length == 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: Sizing().height(5, 5)),
                              child: Text(
                                'No project found',
                                style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: Sizing().height(5, 3.5)),
                              ),
                            )
                          ],
                        )
                      : SizedBox()
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  projListData() {
    List<TableRow> projectList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Project",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Last modified",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Actions",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ]),
    ];
    if (isSearching && tempList != null && tempList!.length > 0) {
      for (int i = 0; i < tempList!.length; i++) {
        var foldername = (tempList![i].path ?? '').split('\\').last;
        String projectNo;
        String projectname;
        if (foldername.contains('_')) {
          projectNo = foldername.split('_')[1];
          projectname = foldername.split('_')[0];
        } else {
          projectNo = foldername;
          projectname = "-";
        }
        projectList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.folder,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Container(
                  width: 150,
                  child: Text(
                    foldername,
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                Constants.modifiedDateFormat.format(
                    DateTime.parse((tempList ?? [])[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Row(
            children: [
              IconButton(
                  tooltip: 'View folder',
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed(PageRouter.subFolderPage, arguments: {
                      "projName": Platform.isWindows
                          ? ((tempList ?? [])[i].path ?? '').split('\\').last
                          : ((tempList ?? [])[i].path ?? '').split('/').last
                    });
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              IconButton(
                  tooltip: 'Rename folder',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AddProject(
                            projName: projectname,
                            projNo: projectNo,
                            isEdit: true,
                            dirFolderName: dirFolderName,
                          );
                        });
                  },
                  icon: Icon(
                    Icons.edit,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              IconButton(
                  tooltip: 'Delete folder',
                  onPressed: () {
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
                                              String projName =
                                                  ((tempList ?? [])[i].path ??
                                                          '')
                                                      .split('\\')
                                                      .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();
                                              Directory newDirectory = Directory(
                                                  '${directory.path}/$dirFolderName/$projName');
                                              //create backupFolder in PhotoApp
                                              Directory backupProjectFolderDir =
                                                  Directory(
                                                      '${directory.path}/$dirFolderName/ProjectFolderBackup');
                                              if (!await backupProjectFolderDir
                                                  .exists()) {
                                                await backupProjectFolderDir
                                                    .create(recursive: true);
                                              }

                                              backupProjectFolderDir = Directory(
                                                  '${directory.path}/$dirFolderName/ProjectFolderBackup/$projName');
                                              if (!await backupProjectFolderDir
                                                  .exists()) {
                                                await backupProjectFolderDir
                                                    .create(recursive: true);
                                              }
                                              //create backupFolder in PhotoApp

                                              //copy the project folder to backup folder
                                              copyDirectory(newDirectory,
                                                  backupProjectFolderDir);
                                              //copy the project folder to backup folder

                                              // //copy the project folder to backup folder
                                              // newDirectory
                                              //     .listSync(
                                              //         recursive: true,
                                              //         followLinks: false)
                                              //     .forEach((FileSystemEntity
                                              //         entity) {
                                              //   if (entity is File) {
                                              //     final String newPath =
                                              //         backupProjectFolderDir
                                              //                 .path +
                                              //             '/' +
                                              //             entity.path
                                              //                 .split('/')
                                              //                 .last;
                                              //     entity.copySync(newPath);
                                              //   } else if (entity
                                              //       is Directory) {
                                              //     final String newPath =
                                              //         backupProjectFolderDir
                                              //                 .path +
                                              //             '/' +
                                              //             entity.path
                                              //                 .split('/')
                                              //                 .last;
                                              //     if (!backupProjectFolderDir
                                              //         .existsSync()) {
                                              //       backupProjectFolderDir
                                              //           .createSync(
                                              //               recursive: true);
                                              //     }
                                              //   }
                                              // });
                                              // //copy the project folder to backup folder
                                              if (await newDirectory.exists()) {
                                                await newDirectory.delete(
                                                    recursive: true);
                                              }
                                              (tempList ?? []).removeWhere(
                                                  (r) => (r.path ?? "")
                                                      .split('\\')
                                                      .last
                                                      .contains(projName));
                                              setState(() {
                                                tempList = tempList;
                                                session.deletedProject
                                                    .add(projName);
                                                session.newAddedProj
                                                    .removeWhere((element) =>
                                                        element.path ==
                                                        projName);
                                                getFiles();
                                              });

                                              //delete the mapped project in file
                                              List<ProjectAndTemplateMapModel>
                                                  pData = await projTempService
                                                      .getProjectAndTemplateMapping();
                                              pData.removeWhere((element) =>
                                                  element.project
                                                      .toString()
                                                      .toLowerCase()
                                                      .trim() ==
                                                  projName
                                                      .toLowerCase()
                                                      .trim());

                                              projTempService
                                                  .saveProjectAndTemplateMapping(
                                                      pData);

                                              Navigator.pop(context);
                                              CherryToast.success(
                                                      title: Text(
                                                        "Deleted successfully",
                                                        style: TextStyle(
                                                            fontSize: Sizing()
                                                                .height(5, 3)),
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
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
            ],
          )
        ]));
      }
    } else if ((isSearching && tempList == null) ||
        (isSearching && tempList!.length == 0)) {
      projectList.add(TableRow(children: [Text(''), Text(''), Text('')]));
      projectList.add(TableRow(children: [
        Text(''),
        Text('No projects found',
            style: TextStyle(
                color: Colors.black38, fontSize: Sizing().height(5, 3.5))),
        Text('')
      ]));
    }
    if ((isSearching == false && tempList == null) ||
        (isSearching == false &&
            tempList!.length <= 0 &&
            recentProj != null &&
            recentProj!.length > 0)) {
      for (int i = 0; i < recentProj!.length; i++) {
        var foldername = (recentProj![i].path ?? '').split('\\').last;
        String projectNo;
        String projectname;
        if (foldername.contains('_')) {
          projectNo = foldername.split('_')[1];
          projectname = foldername.split('_')[0];
        } else {
          projectNo = foldername;
          projectname = "-";
        }
        projectList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.folder,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Container(
                  width: 150,
                  child: Text(
                    foldername,
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                Constants.modifiedDateFormat.format(
                    DateTime.parse((recentProj ?? [])[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Row(
            children: [
              IconButton(
                  tooltip: 'View folder',
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed(PageRouter.subFolderPage, arguments: {
                      "projName": Platform.isWindows
                          ? ((recentProj ?? [])[i].path ?? '').split('\\').last
                          : ((recentProj ?? [])[i].path ?? '').split('/').last
                    });
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              IconButton(
                  tooltip: 'Rename folder',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AddProject(
                            projName: projectname,
                            projNo: projectNo,
                            isEdit: true,
                            dirFolderName: dirFolderName,
                          );
                        });
                  },
                  icon: Icon(
                    Icons.edit,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              IconButton(
                  tooltip: 'Delete folder',
                  onPressed: () {
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
                                              String projName =
                                                  ((recentProj ?? [])[i].path ??
                                                          '')
                                                      .split('\\')
                                                      .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();
                                              Directory newDirectory = Directory(
                                                  '${directory.path}/$dirFolderName/$projName');
                                              //create backupFolder in PhotoApp
                                              Directory backupProjectFolderDir =
                                                  Directory(
                                                      '${directory.path}/$dirFolderName/ProjectFolderBackup');
                                              if (!await backupProjectFolderDir
                                                  .exists()) {
                                                await backupProjectFolderDir
                                                    .create(recursive: true);
                                              }
                                              backupProjectFolderDir = Directory(
                                                  '${directory.path}/$dirFolderName/ProjectFolderBackup/$projName');
                                              if (!await backupProjectFolderDir
                                                  .exists()) {
                                                await backupProjectFolderDir
                                                    .create(recursive: true);
                                              }
                                              //create backupFolder in PhotoApp

                                              copyDirectory(newDirectory,
                                                  backupProjectFolderDir);
                                              //copy the project folder to backup folder
                                              if (await newDirectory.exists()) {
                                                await newDirectory.delete(
                                                    recursive: true);
                                              }
                                              setState(() {
                                                session.deletedProject
                                                    .add(projName);
                                                session.newAddedProj
                                                    .removeWhere((element) =>
                                                        element.path ==
                                                        projName);
                                                getFiles();
                                              });

                                              //delete the mapped project in file
                                              List<ProjectAndTemplateMapModel>
                                                  pData = await projTempService
                                                      .getProjectAndTemplateMapping();
                                              pData.removeWhere((element) =>
                                                  element.project
                                                      .toString()
                                                      .toLowerCase()
                                                      .trim() ==
                                                  projName
                                                      .toLowerCase()
                                                      .trim());

                                              projTempService
                                                  .saveProjectAndTemplateMapping(
                                                      pData);

                                              Navigator.pop(context);
                                              CherryToast.success(
                                                      title: Text(
                                                        "Deleted successfully",
                                                        style: TextStyle(
                                                            fontSize: Sizing()
                                                                .height(5, 3)),
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
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
            ],
          )
        ]));
      }
    }
    return projectList;
  }

  void copyFolder(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    // Copy the source folder itself
    String sourceFolderName = path.basename(source.path);
    String destinationFolderPath =
        path.join(destination.path, sourceFolderName);
    Directory destinationFolder = Directory(destinationFolderPath);
    destinationFolder.createSync();

    source.listSync(recursive: true).forEach((FileSystemEntity entity) {
      if (!isHidden(entity)) {
        if (entity is File) {
          File file = File(entity.path);
          String relativePath = path.relative(file.path, from: source.path);
          String newPath = path.join(destinationFolder.path, relativePath);
          file.copySync(newPath);
        } else if (entity is Directory) {
          Directory subDirectory = Directory(entity.path);
          String relativePath =
              path.relative(subDirectory.path, from: source.path);
          if (relativePath.isNotEmpty) {
            String newPath = path.join(destinationFolder.path, relativePath);
            Directory newDirectory = Directory(newPath);
            newDirectory.createSync();
          }
          copyFolder(subDirectory, destinationFolder);
        }
      }
    });
  }

  bool isHidden(FileSystemEntity entity) {
    String entityName = path.basename(entity.path);
    return entityName.startsWith('.');
  }

  syncHistory() {
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          selectedIndex == 0 ? syncAndRefresh() : SizedBox(),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: Sizing.width(2, 5),
                  vertical: Sizing().height(1, 2)),
              decoration: BoxDecoration(
                  color: Color(0xfff6f6f6),
                  borderRadius: BorderRadius.circular(10)),
              height: Sizing().height(50, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Sizing.width(5, 5),
                        vertical: Sizing().height(5, 3)),
                    child: Text('Sync history',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                  Expanded(
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Sizing.width(5, 5),
                            vertical: Sizing().height(5, 3)),
                        child: FutureBuilder(
                            future: syncHistoryService.getSyncHistory(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: primaryColor));
                              } else if (snapshot.hasData) {
                                List<SyncHistoryModel>? syncData =
                                    snapshot.data;
                                if (syncData != null && syncData.isNotEmpty) {
                                  SyncHistoryModel data;
                                  syncData.reversed;
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: syncData.length,
                                    itemBuilder: (context, index) {
                                      data = syncData[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: Icon(
                                                data.syncMode == 'USB'
                                                    ? Icons.cable
                                                    : Icons.wifi,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    DateFormat(
                                                            'dd-MM-yyy hh:mm aa')
                                                        .format(DateTime.parse(
                                                            (data.syncedTime ??
                                                                ''))),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    )),
                                                Text(
                                                    '${data.imageFiles} File(s) synced',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ))
                                              ],
                                            ))
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Text(
                                  'You can find your sync history here',
                                  style: TextStyle(
                                      color: Colors.black38,
                                      fontSize: Sizing().height(5, 3)),
                                );
                              } else {
                                return Text(
                                  'You can find your sync history here',
                                  style: TextStyle(
                                      color: Colors.black38,
                                      fontSize: Sizing().height(5, 3)),
                                );
                              }
                            })),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  syncAndRefresh() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        showUsb ? startSyncButton() : const SizedBox(),
        showWifi ? wifiButton() : const SizedBox(),
      ],
    );
  }

  startSyncButton() {
    return Tooltip(
      message: 'USB sync',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            try {
              session.isWifi = true;
              CommonUi().showLoadingDialog(context);
              String syncedTime = DateTime.now().toString();
              HiveHelper().saveSyncedTime(syncedTime);
              String currentAndroidVersion = '';
              String imei = '';

              final rest = await Process.run('adb', ['devices']);
              if (rest.exitCode == 0) {
                final output = rest.stdout.toString();
                final lines = LineSplitter.split(output).toList();
                if (lines[1] != "") {
                  final ProcessResult result = await Process.run('adb', [
                    'shell',
                    'cat',
                    '/sdcard/Download/$dirConfigFolderName/Version.csv'
                  ]);
                  if (result.exitCode == 0) {
                    String content = result.stdout;
                    List<String> lines = content.trim().split('\n');
                    currentAndroidVersion = lines[1];
                  }

                  final ProcessResult result1 = await Process.run('adb', [
                    'shell',
                    'getprop',
                    'ro.serialno',
                  ]);
                  if (result1.exitCode == 0) {
                    imei = result1.stdout.toString().replaceAll('"', ' ');
                  }

                  if (currentAndroidVersion == windowsAppversion.toString()) {
                    // var box = await Hive.openBox('appData');
                    // await box.clear();
                    bool isImeiIdStored = HiveHelper().getIMEIId();
                    if (lastsyncedDeviceIMEIID == '' &&
                        isImeiIdStored == false) {
                      List<SyncDeviceHistoryModel> syncDevicHistory = [
                        SyncDeviceHistoryModel(
                          deviceID: imei.trim(),
                        )
                      ];
                      syncHistoryService
                          .saveSyncDeviceHistory(syncDevicHistory);
                      HiveHelper().saveIMEIId(true);
                      Navigator.pop(context);

                      syncloader();
                      receiveFromUsb(imei.trim());
                    } else if (isImeiIdStored && lastsyncedDeviceIMEIID != '') {
                      if (lastsyncedDeviceIMEIID == imei.trim()) {
                        Navigator.pop(context);
                        syncloader();
                        receiveFromUsb(imei.trim());
                      } else {
                        Navigator.pop(context);
                        CherryToast.error(
                                title: Text(
                                  "Connected android device is not found in the history",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      }
                    }
                  } else {
                    Navigator.pop(context);
                    CherryToast.warning(
                            title: Text(
                              "Android application version does not matched with windows application version",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
                  }
                } else {
                  errorLog.add(ErrorLogModel(
                      errorDescription: output.toString(),
                      duration: DateTime.now().toString()));
                  errorLogService.saveErrorLog(errorLog);
                  Navigator.pop(context);
                  CherryToast.error(
                          title: Text(
                            "No device found",
                            style: TextStyle(fontSize: Sizing().height(5, 3)),
                          ),
                          autoDismiss: true)
                      .show(context);
                }
              } else {
                Navigator.pop(context);
                CherryToast.error(
                        title: Text(
                          "Kindly install the dependencies of USB sync and try again!",
                          style: TextStyle(fontSize: Sizing().height(5, 3)),
                        ),
                        autoDismiss: true)
                    .show(context);
              }
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
              Navigator.pop(context);
            }
          },
          child: Container(
            width: Sizing.width(20, 35),
            height: Sizing().height(10, 20),
            margin: EdgeInsets.only(
                top: Sizing().height(5, 2), right: Sizing.width(2, 2)),
            decoration: BoxDecoration(
                color: primaryColor, borderRadius: BorderRadius.circular(7)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'USB sync',
                  style: TextStyle(
                      color: Colors.white, fontSize: Sizing().height(5, 3)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(3, 4),
                    vertical: Sizing().height(2, 2),
                  ),
                  margin: EdgeInsets.symmetric(
                      horizontal: Sizing.width(2, 4),
                      vertical: Sizing().height(5, 1.5)),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 107, 114, 169),
                      borderRadius: BorderRadius.circular(7)),
                  child: Icon(
                    Icons.cable,
                    color: Colors.white,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  startRefresh() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          try {
            CommonUi().showLoadingDialog(context);
            Timer(const Duration(seconds: 1), () {
              getFiles();
              Navigator.pop(context);
            });
          } on Exception catch (e) {
            errorLog.add(ErrorLogModel(
                errorDescription: e.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
          }
        },
        child: Container(
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(7)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 4)),
                child: Text(
                  'Refresh for project list',
                  style: TextStyle(
                      color: Colors.white, fontSize: Sizing().height(5, 3)),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(3, 4),
                  vertical: Sizing().height(2, 2),
                ),
                margin: EdgeInsets.symmetric(
                    horizontal: Sizing.width(2, 4),
                    vertical: Sizing().height(5, 1.5)),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 107, 114, 169),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  drawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      height: Sizing().height(50, 15),
                      child: Image.asset('assets/images/cardio_icon.png')),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: Sizing().height(10, 3),
                        left: Sizing.width(4, 3)),
                    child: Text(
                      'Cardio',
                      style: Platform.isWindows
                          ? subtitle2.copyWith(color: whiteColor)
                          : Sizing.getScreenWidth(context) > 1000
                              ? subtitle1.copyWith(color: whiteColor)
                              : title2.copyWith(color: whiteColor),
                    ),
                  ),
                ],
              )),
          ListTile(
            leading: Icon(Icons.add_box,
                size:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
            title: Text('Add Project',
                style:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? TextStyle(fontSize: 17)
                        : TextStyle()),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AddProject(
                      isEdit: false,
                      dirFolderName: dirFolderName,
                    );
                  });
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_document,
                size:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
            title: Text('Prepare Report',
                style:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? TextStyle(fontSize: 17)
                        : TextStyle()),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                PageRouter.generateReport,
              );
            },
          ),
          Platform.isWindows
              ? ListTile(
                  leading: Icon(Icons.download,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 30
                          : Sizing().height(10, 5)),
                  title: Text('Image log',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 17)
                          : TextStyle()),
                  onTap: () async {
                    try {
                      var res = await imageService.getImageLogFile();
                      var dir = await getDownloadsDirectory();

                      if (await Permission.storage.request().isGranted) {
                        final filePath = '${dir!.path}/Cardio_ImageLog.csv';
                        File imgLogFile = File(filePath);
                        await imgLogFile.create(recursive: true);
                        imgLogFile.writeAsBytesSync(res);

                        CherryToast.success(
                                title: Text(
                                  "Download Successfully",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                animationType: AnimationType.fromRight,
                                autoDismiss: true)
                            .show(context);

                        try {
                          await OpenFile.open(filePath);
                        } on Exception catch (e) {
                          CherryToast.warning(
                                  title: Text(
                                    "No application found that can open CSV / Excel files",
                                    style: TextStyle(
                                        fontSize: Sizing().height(5, 3)),
                                  ),
                                  autoDismiss: true)
                              .show(context);
                        }
                      } else {
                        print('Permission to access directory not granted');
                      }
                    } on Exception catch (e) {
                      CherryToast.error(
                              title: Text(
                                "Download Failed",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  },
                )
              : SizedBox(),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Release details V1.0',
              style: TextStyle(
                  color: primaryColor, fontSize: Sizing().height(5, 5)),
            ),
          ),
          Platform.isWindows
              ? ListTile(
                  leading: Icon(Icons.article,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 30
                          : Sizing().height(10, 5)),
                  title: Text('Report Template',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 17)
                          : TextStyle()),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(
                      PageRouter.template,
                    );
                  },
                )
              : SizedBox(),
          Platform.isWindows
              ? ListTile(
                  leading: Icon(Icons.settings,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 30
                          : Sizing().height(10, 5)),
                  title: Text('Application Configuration',
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 17)
                          : TextStyle()),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return configPasswordCheck();
                        });
                  },
                )
              : SizedBox(),
        ],
      ),
    );
  }

  receiveFromUsb(String imei) async {
    try {
      var status = await Permission.storage.request();

      if (status.isGranted) {
        dashboardBloc.setStepperIndexCount(0);
        Directory directory = await FileMethods.getWindowsSaveDirectory();

        final dir = Directory(directory.path);
        var destinationPath = '${dir.path}\\$dirFolderName';
        var sourcePath = '/sdcard/Download/$dirFolderName/PhotoSync';

        final String deviceId = imei;

        //get lastSynced dateTime for corresponding deviceID
        if (deviceId != '') {
          var data = syncedHistoryList
              .where((element) => element.deviceId == deviceId);
          List<SyncHistoryModel> filteredHistoryList = [];
          if (data.isNotEmpty) {
            filteredHistoryList = data.toList();
            lastSyncedTime = filteredHistoryList.first.syncedTime ?? "";
          } else {
            lastSyncedTime = "";
          }
        } else {
          lastSyncedTime = "";
        }
        DateTime lastSyncTime = lastSyncedTime != ""
            ? DateTime.parse(lastSyncedTime)
            : DateTime(1970);

        //sync only modified files and folders
        ProcessResult syncResult = await Process.run(
          'adb',
          ['shell', 'ls', '-R', sourcePath],
        );
        final stderrString = syncResult.stderr.toString();
        if (stderrString.contains('PhotoSync: No such file or directory')) {
          await Process.run(
              'adb', ['shell', 'mkdir', '/sdcard/Download/$dirFolderName']);
          final ProcessResult result = await Process.run('adb',
              ['shell', 'mkdir', '/sdcard/Download/$dirFolderName/PhotoSync']);
          if (result.exitCode == 0) {
            syncResult = await Process.run(
              'adb',
              ['shell', 'ls', '-R', sourcePath],
            );
          }
        }
        if (syncResult.exitCode == 0) {
          final String output = syncResult.stdout as String;
          List<String> lines = output.split('\n');
          List<String> finalLines = [];
          String curntDir = '';
          var filteredLines = lines.where((element) => !(element.trim() == "" ||
              element.trim().toLowerCase().contains('projectfolderbackup') ||
              element.trim().toLowerCase().contains('.photoapp.txt')));
          DateTime syncStartTime = DateTime.now();
          if (filteredLines.isNotEmpty) {
            finalLines = filteredLines.toList();
            finalLines = finalLines.sublist(1);

            for (final String line in finalLines) {
              final String trimmedLine = line.trim();
              String currentDirectory =
                  '/sdcard/Download/$dirFolderName/PhotoSync';
              dashboardBloc.setStepperIndexCount(1);

              // Check if the line represents a file or directory
              if (trimmedLine.endsWith(':')) {
                // This line represents a directory
                currentDirectory =
                    trimmedLine.substring(0, trimmedLine.length - 1);
                curntDir = trimmedLine.substring(0, trimmedLine.length - 1);

                String projName = curntDir.split('PhotoSync/').last;

                if (projName != '') {
                  if (session.deletedProject.isNotEmpty) {
                    session.deletedProject.removeWhere((element) {
                      return element.toLowerCase() == projName.toLowerCase();
                    });
                  }

                  if (session.editedProjAndroid.isNotEmpty) {
                    session.editedProjAndroid.removeWhere((element) {
                      return element.toLowerCase() == projName.toLowerCase();
                    });
                  }
                  if (session.editedProjWindows.isNotEmpty) {
                    session.editedProjWindows.removeWhere((element) {
                      return element.toLowerCase() == projName.toLowerCase();
                    });
                  }
                }
                final DateTime modifiedTime =
                    await getModifiedTime(currentDirectory);
                if (lastSyncTime != DateTime(1970)) {
                  if (modifiedTime.isAfter(lastSyncTime)) {
                    List<String> directories = path.split(currentDirectory);
                    if (directories.isNotEmpty &&
                        directories.last != 'PhotoSync') {
                      directories.removeLast();
                    }

                    String modifiedPath = path.joinAll(directories);
                    String parentDirectoryName =
                        modifiedPath.split('PhotoSync').last;
                    parentDirectoryName = parentDirectoryName != ""
                        ? parentDirectoryName.replaceAll('/', '\\')
                        : parentDirectoryName;
                    String modifiedDestinationPath = parentDirectoryName == ''
                        ? "$destinationPath"
                        : '$destinationPath$parentDirectoryName';
                    await Process.run(
                      'adb',
                      ['pull', currentDirectory, modifiedDestinationPath],
                    );
                  }
                } else {
                  List<String> directories = path.split(currentDirectory);
                  if (directories.isNotEmpty &&
                      directories.last != 'PhotoSync') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('PhotoSync').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('/', '\\')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ""
                      ? '$destinationPath'
                      : '$destinationPath$parentDirectoryName';
                  await Process.run(
                    'adb',
                    ['pull', currentDirectory, modifiedDestinationPath],
                  );
                }
              } else {
                // This line represents a file
                curntDir = curntDir == "" ? currentDirectory : curntDir;

                if (trimmedLine != '') {
                  if (session.deletedProject.isNotEmpty) {
                    session.deletedProject.removeWhere((element) {
                      return element.toLowerCase() == trimmedLine.toLowerCase();
                    });
                  }

                  if (session.editedProjAndroid.isNotEmpty) {
                    session.editedProjAndroid.removeWhere((element) {
                      return element.toLowerCase() == trimmedLine.toLowerCase();
                    });
                  }
                  if (session.editedProjWindows.isNotEmpty) {
                    session.editedProjWindows.removeWhere((element) {
                      return element.toLowerCase() == trimmedLine.toLowerCase();
                    });
                  }
                }

                String currentFile =
                    path.join(sourcePath, curntDir, trimmedLine);
                currentFile = currentFile.replaceAll('\\', '/');

                // final String currentFile = '$currentDirectory/$trimmedLine';
                final DateTime modifiedTime =
                    await getModifiedTime(currentFile);
                if (lastSyncTime != DateTime(1970)) {
                  if (modifiedTime.isAfter(lastSyncTime)) {
                    List<String> directories = path.split(currentFile);
                    if (directories.isNotEmpty &&
                        directories.last != 'PhotoSync') {
                      directories.removeLast();
                    }

                    String modifiedPath = path.joinAll(directories);
                    String parentDirectoryName =
                        modifiedPath.split('PhotoSync').last;
                    parentDirectoryName = parentDirectoryName != ""
                        ? parentDirectoryName.replaceAll('/', '\\')
                        : parentDirectoryName;
                    String modifiedDestinationPath = parentDirectoryName == ''
                        ? '$destinationPath'
                        : '$destinationPath$parentDirectoryName';

                    await Process.run(
                      'adb',
                      ['pull', currentFile, modifiedDestinationPath],
                    );

                    if (!currentFile
                        .toLowerCase()
                        .contains('generatedreport')) {
                      sharedFileCount += 1;
                      String filename =
                          currentFile.split('/').last.toLowerCase();
                      if (filename.contains('.')) {
                        String fileExtension =
                            filename.split('.').last.toLowerCase();
                        if (imageTypes.contains(fileExtension)) {
                          imageFileCount += 1;
                          androidSharedFileCount += 1;
                          dashboardBloc.setAndroidFileCount(
                              androidSharedFileCount.toString());
                        }
                      }
                    }
                  }
                } else {
                  List<String> directories = path.split(currentFile);
                  if (directories.isNotEmpty &&
                      directories.last != 'PhotoSync') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('PhotoSync').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('/', '\\')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ''
                      ? "$destinationPath"
                      : '$destinationPath$parentDirectoryName';
                  await Process.run(
                    'adb',
                    ['pull', currentFile, modifiedDestinationPath],
                  );

                  if (!currentFile.toLowerCase().contains('generatedreport')) {
                    sharedFileCount += 1;

                    String filename = currentFile.split('/').last.toLowerCase();
                    if (filename.contains('.')) {
                      String fileExtension =
                          filename.split('.').last.toLowerCase();
                      if (imageTypes.contains(fileExtension)) {
                        imageFileCount += 1;
                        androidSharedFileCount += 1;
                        dashboardBloc.setAndroidFileCount(
                            androidSharedFileCount.toString());
                      }
                    }
                  }
                }
              }
            }
            await Process.run('adb', [
              'shell',
              'rm',
              '-r',
              '/sdcard/Download/$dirFolderName/PhotoSync'
            ]);
            shellCommands(imageFileCount, sharedFileCount, lastSyncedTime,
                deviceId, syncStartTime);
          } else {
            await Process.run('adb', [
              'shell',
              'rm',
              '-r',
              '/sdcard/Download/$dirFolderName/PhotoSync'
            ]);
            shellCommands(imageFileCount, sharedFileCount, lastSyncedTime,
                deviceId, syncStartTime);
          }
        } else {
          Navigator.pop(context);
          CherryToast.error(
                  title: Text(
                    "Please try reconnecting your android device to windows",
                    style: TextStyle(fontSize: Sizing().height(5, 3)),
                  ),
                  autoDismiss: false)
              .show(context);

          errorLog.add(ErrorLogModel(
              errorDescription: syncResult.stderr.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
          errorLog.add(ErrorLogModel(
              errorDescription: syncResult.stdout.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
        }
        //sync only modified files and folders
      }
    } on Exception catch (e) {
      Navigator.pop(context);
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  Future<String> getFingerprint() async {
    final ProcessResult result =
        await Process.run('adb', ['shell', 'getprop', 'ro.build.fingerprint']);

    if (result.exitCode == 0) {
      final String output = result.stdout as String;
      return output.trim();
    } else {
      // Handle errors here if needed.
      return ''; // Return an empty string or null in case of an error.
    }
  }

  Future<DateTime> getModifiedTime(String directoryPath) async {
    final ProcessResult result = await Process.run(
      'adb',
      ['shell', 'stat', '-c', '%Y', directoryPath],
    );

    if (result.exitCode == 0) {
      final String output = result.stdout as String;
      final int modifiedTimestamp = int.parse(output);

      final DateTime modifiedTime =
          DateTime.fromMillisecondsSinceEpoch(modifiedTimestamp * 1000);
      return modifiedTime;
    }
    return DateTime(1970);
  }

  shellCommands(imageFileCount, sharedFileCount, lastSyncedTime, deviceId,
      syncStartTime) async {
    try {
      dashboardBloc.setStepperIndexCount(2);
      int autoDelTargetDay = 0;
      DateTime currentDateTime = DateTime.now();
      Directory directory = await FileMethods.getWindowsSaveDirectory();
      final dir = Directory('${directory.path}$dirFolderName');
      var sourcePath = dir.path;
      var destinationPath = '/sdcard/Download/$dirFolderName';

      //sync only modified files and folders
      DateTime lastSyncTime = lastSyncedTime != ""
          ? DateTime.parse(lastSyncedTime)
          : DateTime(1970);
      final Directory syncDirectory = Directory(sourcePath);

      //get autoDelete target days

      if (configDetail.isNotEmpty) {
        autoDelTargetDay = (configDetail.first.targetDays) ?? 0;
      }

      if (syncDirectory.existsSync()) {
        final List<FileSystemEntity> entities =
            syncDirectory.listSync(recursive: true);
        for (final FileSystemEntity entity in entities) {
          if (!entity.path
                  .split('/')
                  .last
                  .toLowerCase()
                  .contains('projectfolderbackup') &&
              !entity.path.split('/').last.contains('.PhotoApp.txt')) {
            String projName = entity.path.split('$dirFolderName\\').last;
            if (projName != '') {
              if (session.deletedProject.isNotEmpty) {
                session.deletedProject.removeWhere((element) {
                  return element.toLowerCase() == projName.toLowerCase();
                });
              }

              if (session.editedProjAndroid.isNotEmpty) {
                session.editedProjAndroid.removeWhere((element) {
                  return element.toLowerCase() == projName.toLowerCase();
                });
              }
              if (session.editedProjWindows.isNotEmpty) {
                session.editedProjWindows.removeWhere((element) {
                  return element.toLowerCase() == projName.toLowerCase();
                });
              }
            }
            if (entity is File) {
              final File file = entity;
              final DateTime modifiedTime = file.lastModifiedSync();
              DateTime checkExpiryDay =
                  modifiedTime.add(Duration(hours: autoDelTargetDay * 24));
              if (lastSyncTime != DateTime(1970)) {
                if (modifiedTime.isAfter(lastSyncTime) &&
                    modifiedTime.isBefore(syncStartTime) &&
                    checkExpiryDay.isAfter(currentDateTime)) {
                  List<String> directories = path.split(file.path);
                  if (directories.isNotEmpty &&
                      directories.last != '$dirFolderName') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('$dirFolderName').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('\\', '/')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ''
                      ? '$destinationPath'
                      : '$destinationPath$parentDirectoryName';
                  await Process.run('adb',
                      ['push', '--sync', file.path, modifiedDestinationPath]);
                  if (!file.path.toLowerCase().contains('generatedreport')) {
                    sharedFileCount += 1;

                    String filename = file.path.split('/').last.toLowerCase();
                    if (filename.contains('.')) {
                      String fileExtension =
                          filename.split('.').last.toLowerCase();
                      if (imageTypes.contains(fileExtension)) {
                        imageFileCount += 1;
                        windowsSharedFileCount += 1;
                        dashboardBloc.setWindowsFileCount(
                            windowsSharedFileCount.toString());
                      }
                    }
                  }
                }
              } else {
                if (modifiedTime.isBefore(syncStartTime) &&
                    checkExpiryDay.isAfter(currentDateTime)) {
                  List<String> directories = path.split(file.path);
                  if (directories.isNotEmpty &&
                      directories.last != '$dirFolderName') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('$dirFolderName').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('\\', '/')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ''
                      ? '$destinationPath'
                      : '$destinationPath$parentDirectoryName';
                  await Process.run('adb',
                      ['push', '--sync', file.path, modifiedDestinationPath]);
                  if (!file.path.toLowerCase().contains('generatedreport')) {
                    sharedFileCount += 1;

                    String filename = file.path.split('/').last.toLowerCase();
                    if (filename.contains('.')) {
                      String fileExtension =
                          filename.split('.').last.toLowerCase();
                      if (imageTypes.contains(fileExtension)) {
                        imageFileCount += 1;
                        windowsSharedFileCount += 1;
                        dashboardBloc.setWindowsFileCount(
                            windowsSharedFileCount.toString());
                      }
                    }
                  }
                }
              }
            } else if (entity is Directory) {
              final Directory subdirectory = entity;
              final DateTime modifiedTime = subdirectory.statSync().modified;
              DateTime checkExpiryDay =
                  modifiedTime.add(Duration(hours: autoDelTargetDay * 24));
              if (lastSyncTime != DateTime(1970)) {
                if (modifiedTime.isAfter(lastSyncTime) &&
                    modifiedTime.isBefore(syncStartTime) &&
                    checkExpiryDay.isAfter(currentDateTime)) {
                  List<String> directories = path.split(subdirectory.path);
                  if (directories.isNotEmpty &&
                      directories.last != '$dirFolderName') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('$dirFolderName').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('\\', '/')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ''
                      ? '$destinationPath'
                      : '$destinationPath$parentDirectoryName';

                  await Process.run('adb', [
                    'push',
                    '--sync',
                    subdirectory.path,
                    modifiedDestinationPath
                  ]);
                }
              } else {
                if (modifiedTime.isBefore(syncStartTime) &&
                    checkExpiryDay.isAfter(currentDateTime)) {
                  List<String> directories = path.split(subdirectory.path);
                  if (directories.isNotEmpty &&
                      directories.last != '$dirFolderName') {
                    directories.removeLast();
                  }

                  String modifiedPath = path.joinAll(directories);
                  String parentDirectoryName =
                      modifiedPath.split('$dirFolderName').last;
                  parentDirectoryName = parentDirectoryName != ""
                      ? parentDirectoryName.replaceAll('\\', '/')
                      : parentDirectoryName;
                  String modifiedDestinationPath = parentDirectoryName == ''
                      ? '$destinationPath'
                      : '$destinationPath$parentDirectoryName';
                  await Process.run('adb', [
                    'push',
                    '--sync',
                    subdirectory.path,
                    modifiedDestinationPath
                  ]);
                }
              }
            }
          }
        }
      }
      //sync only modified files and folders

      List<ImageLogModel> res = await imageService.getImageLog();
      List<String> imgLogName =
          res.map<String>((e) => e.imageName ?? "").toList();
      setState(() {
        imageData = res;
        imgName = imgLogName;
      });

      Directory directoryy = await FileMethods.getWindowsSaveDirectory();
      final dirr = Directory('${directoryy.path}$dirFolderName');
      listFiles(dirr);
      imageService.saveImagLog(imageLog);
      List<SyncHistoryModel> syncHistory = [
        SyncHistoryModel(
          deviceId: deviceId,
          syncedTime: DateTime.now().toLocal().toString(),
          syncMode: 'USB',
          noOfFiles: sharedFileCount,
          imageFiles: imageFileCount,
        )
      ];
      syncHistoryService.saveSyncHistory(syncHistory);
      var sourcePath2 = Directory('${directory.path}$dirConfigFolderName');
      var destinationPath2 = '/sdcard/Download';
      if (sourcePath2.existsSync()) {
        final List<FileSystemEntity> entities =
            sourcePath2.listSync(recursive: true);
        for (final FileSystemEntity entity in entities) {
          if (entity is File) {
            final File file = entity;
            final String fileName =
                file.path.split('$dirConfigFolderName\\').last;
            final Directory destinationFile =
                Directory('$destinationPath2/$dirConfigFolderName/$fileName');
            final ProcessResult result =
                await Process.run('adb', ['shell', 'ls', destinationFile.path]);

            if (result.exitCode == 0 &&
                !fileName.toLowerCase().contains('errorfile')) {
              await Process.run('adb', [
                'shell',
                'rm',
                '$destinationPath2/$dirConfigFolderName/$fileName'
              ]);
            }

            await Process.run('adb',
                ['push', file.path, '$destinationPath2/$dirConfigFolderName']);
          }
        }
      }
      int totalImageFileCount = androidSharedFileCount + windowsSharedFileCount;
      dashboardBloc.setStepperIndexCount(3);
      progressResult = 'Total no.of file(s) shared : $sharedFileCount ';
      dashboardBloc.setProgressIconStatus(true);
      dashboardBloc.setProgressPercentage(progressResult);
      dashboardBloc.setProgressText("USB synchronization completed");
      dashboardBloc.setProgressButtonStatus(true);
      dashboardBloc.setImageFileText(
          'Total no. of image file(s) shared: $totalImageFileCount');

      if (mounted) {
        setState(() {
          sharedFileCount = 0;
          imageFileCount = 0;
          windowsSharedFileCount = 0;
          androidSharedFileCount = 0;
        });
      }
      getLastSyncTime();
    } on Exception catch (e) {
      Navigator.pop(context);
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  void listFiles(Directory dir) {
    List<FileSystemEntity> contents = dir.listSync();
    for (FileSystemEntity content in contents) {
      if (content is File) {
        if (!imgName.contains(content.path.split('/').last)) {
          imageLog.add(ImageLogModel(
              imageName: content.path.split('/').last,
              syncedDate: DateTime.now().toString()));
        }
      } else if (content is Directory) {
        listFiles(Directory(content.path));
      }
    }
  }

  Future<File> saveStreamToFile(
      Stream<List<int>> stream, String filePath) async {
    final file = File(filePath);
    IOSink? sink;

    try {
      sink = file.openWrite();
      await stream.forEach((data) {
        sink!.add(data);
      });
    } catch (e) {
      rethrow;
    } finally {
      await sink!.flush();
      await sink.close();
    }

    return file;
  }

  appBar() {
    return AppBar(
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          );
        },
      ),
      backgroundColor: primaryColor,
      actions: [
        searchBox(),

        //wifi nd usb syncing
        //Platform.isWindows ? usbAndWifi() : SizedBox(),
        //Platform.isAndroid ? wifiButton() : SizedBox(),

        //usb sync
        Platform.isWindows ? usbSync() : SizedBox(),
        refresh(),

        // usb sync alone
        // Platform.isWindows ? syncButton() : SizedBox(),
      ],
    );
  }

  refresh() {
    return Tooltip(
      message: 'Refresh',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: IconButton(
          icon: Icon(
            Icons.refresh,
            size: Sizing().height(20, 6),
          ),
          onPressed: () async {
            try {
              getFiles();
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
            }
          },
        ),
      ),
    );
  }

  searchBox() {
    return Container(
        margin: EdgeInsets.only(
          top: Sizing().height(5, 2),
          bottom: Sizing().height(5, 2),
          left: Sizing.width(5, 10),
        ),
        decoration: BoxDecoration(
          color: Color(0xfff6f6f6),
          border: Border.all(color: Color.fromARGB(0, 246, 246, 246)),
          borderRadius: BorderRadius.circular(10),
        ),
        width:
            Sizing.getScreenWidth(context) > 1000 ? 300 : Sizing.width(60, 200),
        child: TextFormField(
          onChanged: (val) {
            try {
              List<DirectoryInfo> plist = [];
              setState(() {
                searchValue = val;
                isSearching = true;
                if (searchValue == "") {
                  tempList = [];
                  isSearching = false;
                } else if (searchValue != "") {
                  finalProjList.forEach((element) {
                    if ((element.path ?? "")
                        .split('\\')
                        .last
                        .contains(searchValue)) {
                      plist.add(element);
                    }
                  });
                  if (plist.length == 0) {
                    setState(() {
                      tempList = [];
                    });
                  } else if (!(tempList ?? [])
                      .toSet()
                      .containsAll(plist.toSet())) {
                    setState(() {
                      (tempList ?? []).addAll(plist);
                    });
                  }
                  // else {
                  //   setState(() {
                  //     tempList = [];
                  //   });
                  // }
                }
              });
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
            }
          },
          style: TextStyle(
              fontSize: Sizing().height(12, 4), fontWeight: FontWeight.w300),
          cursorColor: blackColor,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(
              top: Sizing.getScreenWidth(context) > 1000
                  ? 15
                  : Sizing().height(9, 1),
              left: Sizing.width(2, 5),
            ),
            enabledBorder: InputBorder.none,
            suffixIcon: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizing.width(3, 4),
                vertical: Sizing().height(2, 2),
              ),
              margin: EdgeInsets.symmetric(
                  horizontal: Sizing.width(2, 5),
                  vertical: Sizing().height(5, 2)),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 107, 114, 169),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(
                Icons.search,
                color: Colors.white,
                size:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
              ),
            ),
            border: InputBorder.none,
            hintText: 'Search project',
            hintStyle: TextStyle(
                color: greyColor,
                fontSize: Sizing().height(10, 3),
                fontWeight: FontWeight.w600),
          ),
        ));
  }

  syncButton() {
    return Tooltip(
      message: 'Sync',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: IconButton(
          icon: Icon(
            Icons.sync,
            size: Sizing().height(5, 6),
          ),
          onPressed: () async {
            try {
              CommonUi().showLoadingDialog(context);
              String syncedTime = DateTime.now().toString();
              HiveHelper().saveSyncedTime(syncedTime);

              final rest = await Process.run('adb', ['devices']);
              final output = rest.stdout.toString();
              final lines = LineSplitter.split(output).toList();
              if (lines[1] != "") {
                Navigator.pop(context);
                syncloader();
                receiveFromUsb("");
              } else {
                Navigator.pop(context);
                CherryToast.error(
                        title: Text(
                          "No device found",
                          style: TextStyle(fontSize: Sizing().height(5, 3)),
                        ),
                        autoDismiss: true)
                    .show(context);
              }
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  syncloader() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return SyncStatusDialog();
        });
  }

  wifiButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Select wifi mode',
        child: Container(
          width: Sizing.width(20, 35),
          height: Sizing().height(10, 20),
          margin: EdgeInsets.only(
              top: Sizing().height(5, 2), right: Sizing.width(2, 2)),
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(7)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'Wifi sync',
              style: TextStyle(
                  color: Colors.white, fontSize: Sizing().height(5, 3)),
            ),
            PopupMenuButton<int>(
              icon: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(1, 2),
                  vertical: Sizing().height(1, 1),
                ),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 107, 114, 169),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(
                  Icons.wifi,
                  color: Colors.white,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 11,
                  child: Text(
                    "Share",
                    style: TextStyle(
                        color: blackColor, fontSize: Sizing().height(5, 3)),
                  ),
                ),
                PopupMenuItem(
                  value: 12,
                  child: Text(
                    "Receive",
                    style: TextStyle(
                        color: blackColor, fontSize: Sizing().height(5, 3)),
                  ),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 11:
                    session.isWifi = true;

                    CommonUi().showLoadingDialog(context);
                    await Future.delayed(Duration(seconds: 1));
                    await PhotonSender.handleSharing();
                    break;
                  case 12:
                    session.isWifi = true;
                    receiveFiles();
                    break;
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  usbAndWifi() {
    return PopupMenuButton<int>(
      tooltip: 'Sync',
      icon: CircleAvatar(
        radius: 30,
        backgroundColor: whiteColor,
        child: Icon(
          Icons.sync,
          color: primaryColor,
          size: Sizing().height(5, 4),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                Icons.cable,
                size: Sizing().height(5, 6),
                color: primaryColor,
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text("USB"),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton(
                tooltip: "Select sync mode",
                icon: Icon(
                  Icons.wifi,
                  size: Sizing().height(5, 6),
                  color: primaryColor,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 11,
                    child: Text("Share"),
                  ),
                  PopupMenuItem(
                    value: 12,
                    child: Text("Receive"),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 11:
                      session.isWifi = true;
                      CommonUi().showLoadingDialog(context);
                      await Future.delayed(Duration(seconds: 1));
                      await PhotonSender.handleSharing();
                      break;
                    case 12:
                      session.isWifi = true;
                      receiveFiles();
                      break;
                  }
                },
              ),
              Text("Wifi"),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 1:
            try {
              session.isWifi = true;
              CommonUi().showLoadingDialog(context);
              String syncedTime = DateTime.now().toString();
              HiveHelper().saveSyncedTime(syncedTime);

              final rest = await Process.run('adb', ['devices']);
              final output = rest.stdout.toString();
              final lines = LineSplitter.split(output).toList();
              if (lines[1] != "") {
                Navigator.pop(context);
                syncloader();
                receiveFromUsb("");
              } else {
                errorLog.add(ErrorLogModel(
                    errorDescription: output.toString(),
                    duration: DateTime.now().toString()));
                errorLogService.saveErrorLog(errorLog);
                Navigator.pop(context);
                CherryToast.error(
                        title: Text(
                          "No device found",
                          style: TextStyle(fontSize: Sizing().height(5, 3)),
                        ),
                        autoDismiss: true)
                    .show(context);
              }
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
              Navigator.pop(context);
            }
            break;
          case 2:
            break;
        }
      },
    );
  }

  usbSync() {
    return IconButton(
      tooltip: "Sync",
      onPressed: () async {
        try {
          session.isWifi = true;
          CommonUi().showLoadingDialog(context);
          String syncedTime = DateTime.now().toString();
          HiveHelper().saveSyncedTime(syncedTime);

          final rest = await Process.run('adb', ['devices']);
          final output = rest.stdout.toString();
          final lines = LineSplitter.split(output).toList();
          if (lines[1] != "") {
            Navigator.pop(context);
            syncloader();
            receiveFromUsb("");
          } else {
            errorLog.add(ErrorLogModel(
                errorDescription: output.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            Navigator.pop(context);
            CherryToast.error(
                    title: Text(
                      "No device found",
                      style: TextStyle(fontSize: Sizing().height(5, 3)),
                    ),
                    autoDismiss: true)
                .show(context);
          }
        } on Exception catch (e) {
          errorLog.add(ErrorLogModel(
              errorDescription: e.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
          Navigator.pop(context);
        }
      },
      icon: Icon(
        Icons.cable,
        size: Sizing().height(20, 6),
        color: whiteColor,
      ),
    );
  }

  searchedProjList() {
    var x = tempList != null && tempList!.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            primary: false,
            physics: ScrollPhysics(),
            itemCount: tempList!.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(PageRouter.subFolderPage,
                      arguments: {"projName": tempList![index].path});
                },
                child: Card(
                  color: whiteColor,
                  child: ListTile(
                    leading: Icon(
                      Icons.business_center,
                      color: Colors.yellow[600],
                      size: Platform.isAndroid
                          ? Sizing.getScreenWidth(context) > 1000
                              ? 40
                              : Sizing().height(30, 35)
                          : 30,
                    ),
                    title: Text(
                      (tempList ?? [])[index].modifiedDate ?? "",
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 20)
                          : TextStyle(),
                    ),
                  ),
                ),
              );
            })
        : SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: Text(
              'No projects',
              style: subtitle3,
              textAlign: TextAlign.center,
            )),
          );

    return x;
  }

  receiveFiles() {
    if (Platform.isAndroid || Platform.isIOS) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  onPressed: () async {
                    HandleShare(context: context).onNormalScanTap();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minWidth: MediaQuery.of(context).size.width / 2,
                  color: primaryColor,
                  child: const Text(
                    'Normal mode',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: whiteColor),
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                MaterialButton(
                  onPressed: () {
                    HandleShare(context: context).onQrScanTap();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minWidth: MediaQuery.of(context).size.width / 2,
                  color: primaryColor,
                  child: const Text(
                    'QR code mode',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: whiteColor),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
              ],
            );
          });
    } else if (Platform.isWindows) {
      HandleShare(context: context).onNormalScanTap();
    }
  }

  lastAddedTenProj() {
    var x = recentProj != null && recentProj!.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            primary: false,
            itemCount: recentProj!.length,
            itemBuilder: (context, index) {
              final currentItem = recentProj![index];
              return InkWell(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(PageRouter.subFolderPage, arguments: {
                    "projName": Platform.isWindows
                        ? (currentItem.path ?? '').split('\\').last
                        : (currentItem.path ?? '').split('/').last
                  });
                },
                child: Card(
                  color: whiteColor,
                  child: ListTile(
                    leading: Icon(
                      Icons.business_center,
                      color: Colors.yellow[600],
                      size: Platform.isAndroid
                          ? Sizing.getScreenWidth(context) > 1000
                              ? 40
                              : Sizing().height(30, 35)
                          : 30,
                    ),
                    title: Text(
                      Platform.isWindows
                          ? (currentItem.path ?? '').split('\\').last
                          : (currentItem.path ?? '').split('/').last,
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 20)
                          : TextStyle(),
                    ),
                    trailing: IconButton(
                      tooltip: "Delete folder",
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Are you sure, want to delete?',
                                      style: Platform.isWindows
                                          ? body3
                                          : subtitle1,
                                    ),
                                    SizedBox(
                                      height: Sizing().height(8, 6),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: Sizing().height(1, 1),
                                            horizontal: Sizing.width(2, 3),
                                          ),
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
                                          padding: EdgeInsets.symmetric(
                                            vertical: Sizing().height(1, 1),
                                            horizontal: Sizing.width(2, 3),
                                          ),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(2)),
                                          child: TextButton(
                                              onPressed: () async {
                                                try {
                                                  String projName = Platform
                                                          .isWindows
                                                      ? (currentItem.path ?? '')
                                                          .split('\\')
                                                          .last
                                                      : (currentItem.path ?? '')
                                                          .split('/')
                                                          .last;
                                                  Directory directory =
                                                      await FileMethods
                                                          .getSaveDirectory();
                                                  Directory newDirectory =
                                                      Directory(
                                                          '${directory.path}/$dirFolderName/$projName');
                                                  //create backupFolder in PhotoApp
                                                  Directory
                                                      backupProjectFolderDir =
                                                      Directory(
                                                          '${directory.path}/$dirFolderName/ProjectFolderBackup');
                                                  if (!await backupProjectFolderDir
                                                      .exists()) {
                                                    await backupProjectFolderDir
                                                        .create(
                                                            recursive: true);
                                                  }

                                                  //create backupFolder in PhotoApp

                                                  backupProjectFolderDir =
                                                      Directory(
                                                          '${directory.path}/$dirFolderName/ProjectFolderBackup/$projName');
                                                  if (!await backupProjectFolderDir
                                                      .exists()) {
                                                    await backupProjectFolderDir
                                                        .create(
                                                            recursive: true);
                                                  }

                                                  copyDirectory(newDirectory,
                                                      backupProjectFolderDir);
                                                  if (await newDirectory
                                                      .exists()) {
                                                    await newDirectory.delete(
                                                        recursive: true);
                                                  }
                                                  setState(() {
                                                    session.deletedProject
                                                        .add(projName);
                                                    session.newAddedProj
                                                        .removeWhere(
                                                            (element) =>
                                                                element.path ==
                                                                projName);
                                                    getFiles();
                                                  });

                                                  //delete the mapped project in file
                                                  List<ProjectAndTemplateMapModel>
                                                      pData =
                                                      await projTempService
                                                          .getProjectAndTemplateMapping();
                                                  pData.removeWhere((element) =>
                                                      element.project
                                                          .toString()
                                                          .toLowerCase()
                                                          .trim() ==
                                                      projName
                                                          .toLowerCase()
                                                          .trim());

                                                  projTempService
                                                      .saveProjectAndTemplateMapping(
                                                          pData);

                                                  Navigator.pop(context);
                                                  CherryToast.success(
                                                          title: Text(
                                                            "Deleted successfully",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    Sizing()
                                                                        .height(
                                                                            5,
                                                                            3)),
                                                          ),
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
                        size: Platform.isAndroid
                            ? Sizing.getScreenWidth(context) > 1000
                                ? 35
                                : Sizing().height(18, 20)
                            : 25,
                      ),
                    ),
                  ),
                ),
              );
            })
        : SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: Text(
              'No projects',
              style: subtitle3,
              textAlign: TextAlign.center,
            )),
          );

    return x;
  }
}

void copyDirectory(Directory source, Directory destination) {
  source.listSync(recursive: true, followLinks: false).forEach((entity) {
    if (entity is File) {
      final String relativePath = entity.path.substring(source.path.length + 1);
      final String newPath = '${destination.path}/$relativePath';
      final File newFile = File(newPath);
      newFile.createSync(recursive: true);
      entity.copySync(newPath);
      // final String newPath =
      //     '${destination.path}/${entity.path.split('/').last}';
      // entity.copySync(newPath);
    } else if (entity is Directory) {
      final String relativePath = entity.path.substring(source.path.length + 1);
      final String newPath = '${destination.path}/$relativePath';
      // final String newPath =
      //     '${destination.path}/${entity.path.split('/').last}';
      Directory newSubDirectory = Directory(newPath);
      if (!newSubDirectory.existsSync()) {
        newSubDirectory.createSync(recursive: true);
      }
      copyDirectory(entity, newSubDirectory);
    }
  });
}

class configPasswordCheck extends StatefulWidget {
  const configPasswordCheck({super.key});

  @override
  State<configPasswordCheck> createState() => _configPasswordCheckState();
}

class _configPasswordCheckState extends State<configPasswordCheck> {
  final passwordService = PasswordService();
  final TextEditingController _password = TextEditingController();
  bool showErrorMsg = false;
  bool incorrectErrorMsg = false;
  List<PasswordModel> passwordconfigData = [];
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 180),
              child: Text(
                'Enter password',
                style: TextStyle(
                    fontSize: Sizing().height(2, 3.5),
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: Sizing().height(3, 3)),
            passwordField(),
            incorrectErrorMsg || showErrorMsg
                ? SizedBox(height: Sizing().height(2, 2))
                : SizedBox(),
            showErrorMsg
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Password is required',
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3), color: Colors.red),
                      ),
                    ],
                  )
                : SizedBox(),
            incorrectErrorMsg
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Password is incorrect',
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3), color: Colors.red),
                      ),
                    ],
                  )
                : SizedBox(),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
                color: greyColor, borderRadius: BorderRadius.circular(5)),
            child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                )),
          ),
          Container(
              decoration: BoxDecoration(
                  color: primaryColor, borderRadius: BorderRadius.circular(5)),
              child: TextButton(
                  onPressed: () async {
                    try {
                      if (_password.text != "") {
                        var res = await passwordService.getConfiguration();
                        if (res.isNotEmpty) {
                          passwordconfigData = res;
                        }
                        if (passwordconfigData.isNotEmpty &&
                            _password.text == passwordconfigData[0].password) {
                          Navigator.pop(context);
                          Navigator.of(context)
                              .pushNamed(PageRouter.dashboard, arguments: {
                            "index": 3,
                            "newProjCreated": false,
                          });
                        } else {
                          setState(() {
                            incorrectErrorMsg = true;
                          });
                        }
                      } else {
                        setState(() {
                          showErrorMsg = true;
                        });
                      }
                    } on Exception catch (e) {
                      throw e;
                    }
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(
                        fontSize: Sizing().height(2, 3), color: whiteColor),
                  )))
        ]);
  }

  passwordField() {
    _password.selection =
        TextSelection.collapsed(offset: _password.text.length);
    return TextFormField(
      onFieldSubmitted: (val) async {
        try {
          if (_password.text != "") {
            var res = await passwordService.getConfiguration();
            if (res.isNotEmpty) {
              passwordconfigData = res;
            }
            if (passwordconfigData.isNotEmpty &&
                _password.text == passwordconfigData[0].password) {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(PageRouter.dashboard, arguments: {
                "index": 3,
                "newProjCreated": false,
              });
            } else {
              setState(() {
                incorrectErrorMsg = true;
              });
            }
          } else {
            setState(() {
              showErrorMsg = true;
            });
          }
        } on Exception catch (e) {
          throw e;
        }
      },
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      obscureText: passwordVisible ? false : true,
      obscuringCharacter: '*',
      controller: _password,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(2, 4)),
      decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
              size: Sizing().height(5, 4),
            ),
            onPressed: () {
              setState(
                () {
                  passwordVisible = !passwordVisible;
                },
              );
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Password',
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(2, 3))),
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
          incorrectErrorMsg = false;
        });
      },
    );
  }
}

class SyncStatusDialog extends StatefulWidget {
  const SyncStatusDialog({super.key});

  @override
  State<SyncStatusDialog> createState() => _SyncStatusDialogState();
}

class _SyncStatusDialogState extends State<SyncStatusDialog> {
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: Sizing().height(5, 3),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: Sizing().height(5, 5)),
            child: StreamBuilder(
              stream: dashboardBloc.stepperIndexStream,
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
                return EasyStepper(
                  enableStepTapping: false,
                  activeStep: snapshot.data ?? 0,
                  lineLength: 50,
                  stepShape: StepShape.circle,
                  stepBorderRadius: 15,
                  borderThickness: 3,
                  stepRadius: 28,
                  unreachedLineColor: Colors.grey,
                  unreachedStepBackgroundColor: Colors.grey[200],
                  unreachedStepBorderColor: Colors.grey[300],
                  unreachedStepTextColor: Colors.white,
                  unreachedStepIconColor: Colors.grey,
                  unreachedStepBorderType: BorderType.normal,
                  finishedStepBorderColor: primaryColor,
                  finishedStepTextColor: Colors.white,
                  finishedStepBackgroundColor: Colors.indigo[200],
                  finishedStepIconColor: Colors.white,
                  activeStepIconColor: Colors.green,
                  showLoadingAnimation:
                      (snapshot.data ?? 0) == 3 ? false : false,
                  steps: [
                    EasyStep(
                      customStep: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                            opacity: (snapshot.data ?? 0) >= 0 ? 1 : 0.3,
                            child: (snapshot.data ?? 0) != 0
                                ? Icon(Icons.update, color: Colors.white)
                                : Center(
                                    child: SizedBox(
                                      height: Sizing().height(2, 30),
                                      child: Lottie.asset(
                                          'assets/lottie/analyzing.json'),
                                    ),
                                  )),
                      ),
                      customTitle: Text(
                        (snapshot.data ?? 0) != 0 ? 'Analyzed' : 'Analyzing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3),
                            fontWeight: (snapshot.data ?? 0) != 0
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                    EasyStep(
                      customStep: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                            opacity: (snapshot.data ?? 0) >= 1 ? 1 : 0.3,
                            child: (snapshot.data ?? 0) != 1
                                ? Icon(Icons.phone_android, color: Colors.white)
                                : Center(
                                    child: Container(
                                      padding: EdgeInsets.all(3),
                                      height: Sizing().height(2, 20),
                                      child: Lottie.asset(
                                          'assets/lottie/AndroidToWindows.json'),
                                    ),
                                  )),
                      ),
                      customTitle: Text(
                        '  Android - Windows',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3),
                            fontWeight: (snapshot.data ?? 0) != 0 &&
                                    (snapshot.data ?? 0) != 1
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                    EasyStep(
                      customStep: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                            opacity: (snapshot.data ?? 0) >= 2 ? 1 : 0.3,
                            child: (snapshot.data ?? 0) != 2
                                ? Icon(Icons.desktop_windows,
                                    color: Colors.white)
                                : Center(
                                    child: Container(
                                      padding: EdgeInsets.all(3),
                                      height: Sizing().height(2, 20),
                                      child: Lottie.asset(
                                          'assets/lottie/WindowsToAndroid.json'),
                                    ),
                                  )),
                      ),
                      customTitle: Text(
                        '  Windows - Android',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3),
                            fontWeight: (snapshot.data ?? 0) != 0 &&
                                    (snapshot.data ?? 0) != 1 &&
                                    (snapshot.data ?? 0) != 2
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                    EasyStep(
                      customStep: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                            opacity: (snapshot.data ?? 0) >= 3 ? 1 : 0.3,
                            child: (snapshot.data ?? 0) != 3
                                ? Icon(Icons.published_with_changes,
                                    color: Colors.white)
                                : Center(
                                    child: SizedBox(
                                      height: Sizing().height(2, 50),
                                      child: Lottie.asset(
                                          'assets/lottie/done.json'),
                                    ),
                                  )),
                      ),
                      customTitle: Text(
                        'Completed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3),
                            fontWeight: (snapshot.data ?? 0) != 0 &&
                                    (snapshot.data ?? 0) != 1 &&
                                    (snapshot.data ?? 0) != 2
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 10),
            child: StreamBuilder(
              stream: dashboardBloc.progressTextStream,
              initialData: "USB synchronization started",
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                return Text(
                  snapshot.data ?? "",
                  style: body2.copyWith(fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          SizedBox(
            height: Sizing().height(2, 2),
          ),
          Container(
            margin: EdgeInsets.only(left: 10),
            child: StreamBuilder(
              stream: dashboardBloc.androidFileCountStream,
              initialData: "",
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                return Text(
                  "No. of file(s) shared from Android : ${(snapshot.data ?? "0") == "" ? "0" : (snapshot.data ?? "0")}",
                  style: body2.copyWith(fontWeight: FontWeight.normal),
                );
              },
            ),
          ),
          SizedBox(
            height: Sizing().height(2, 2),
          ),
          Container(
            margin: EdgeInsets.only(left: 10),
            child: StreamBuilder(
              stream: dashboardBloc.windowsFileCountStream,
              initialData: "",
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                return Text(
                  "No. of file(s) shared from Windows : ${(snapshot.data ?? "0") == "" ? "0" : (snapshot.data ?? "0")}",
                  style: body2.copyWith(fontWeight: FontWeight.normal),
                );
              },
            ),
          ),
          SizedBox(
            height: Sizing().height(2, 2),
          ),
          Container(
            margin: EdgeInsets.only(left: 10),
            child: StreamBuilder(
              stream: dashboardBloc.imageFileTextStream,
              initialData: "",
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                return Text(
                  snapshot.data ?? "",
                  style: body2.copyWith(fontWeight: FontWeight.normal),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        StreamBuilder(
          stream: dashboardBloc.buttonProgressStream,
          initialData: false,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return !(snapshot.data ?? false)
                ? SizedBox()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: Sizing().height(30, 8),
                        margin: EdgeInsets.only(bottom: Sizing().height(10, 4)),
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(5)),
                        child: TextButton(
                            onPressed: () async {
                              try {
                                Navigator.of(context).pop(true);

                                Navigator.of(context).pushReplacementNamed(
                                    PageRouter.dashboard,
                                    arguments: {
                                      "index": 0,
                                      "newProjCreated": false,
                                    });
                              } on Exception catch (e) {
                                errorLog.add(ErrorLogModel(
                                    errorDescription: e.toString(),
                                    duration: DateTime.now().toString()));
                                errorLogService.saveErrorLog(errorLog);
                              }
                            },
                            child: Text(
                              'Close',
                              style: TextStyle(
                                  fontSize: Sizing().height(10, 3),
                                  color: whiteColor),
                            )),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }
}
