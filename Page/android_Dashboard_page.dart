// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:USB_Share/Dashboard/Model/SyncHistoryModel.dart';
import 'package:USB_Share/Dashboard/Service/dashboard_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:USB_Share/services/photon_sender.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

const channerID = '1000';
const channerName = 'Photo_App';

class AndroidDashboardPage extends StatefulWidget {
  const AndroidDashboardPage({super.key});

  @override
  State<AndroidDashboardPage> createState() => _AndroidDashboardPageState();
}

class _AndroidDashboardPageState extends State<AndroidDashboardPage> {
  bool loading = true;
  List<String> projList = [];
  List<DirectoryInfo> tempList = [];
  List<DirectoryInfo> finalProjList = [];
  String searchValue = "";
  final imageService = ImageService();
  final configurationService = ConfigurationService();
  final syncHistoryService = DashboardService();
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
  bool showUsb = true;
  bool showWifi = false;
  String dirFolderName = "";
  String dirConfigFolderName = "";
  bool isSearching = false;
  String imeiNo = '';
  List<SyncHistoryModel> syncedHistoryList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
      dirConfigFolderName = Constants.dataFolder;
    });
    //getFileAccessPermission();
    getFiles();
    checkSyncStatus();
    getWifiOrUsb();
  }

  getWifiOrUsb() async {
    List<ConfigurationModel> res =
        await configurationService.getConfiguration();
    if (res.isNotEmpty) {
      List<String> temp = res.first.wifiOrUsb!.split('|');
      setState(() {
        showWifi = temp[0] == 'true';
        showUsb = temp[1] == 'true';
      });
    }
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
      await dir.create(recursive: true);
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
              final modifiedDate = Constants.dFormat.format(stat.modified);
              directoryInfo.add(
                  DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
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
              .contains((element.path ?? '').split('/').last);
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
          .contains("photosync"));
      directoryInfo.removeWhere((element) => (element.path ?? "")
          .split('/')
          .last
          .toLowerCase()
          .contains("projectfolderbackup"));
      directoryInfo.removeWhere((element) =>
          (element.path ?? "").split('/').last.toLowerCase().contains(".zip"));

      if (mounted) {
        setState(() {
          if (directoryInfo.isNotEmpty) {
            //take recent 10 project
            recentProj = directoryInfo.take(10).toList();

            if (recentProj != null && recentProj!.isNotEmpty) {
              if (session.editedProjAndroid.isNotEmpty) {
                recentProj!.removeWhere((elem) => session.editedProjAndroid
                    .contains((elem.path ?? "").split('/').last));
              }
            }

            finalProjList = directoryInfo.toList();

            if (finalProjList.isNotEmpty) {
              if (session.editedProjAndroid.isNotEmpty) {
                finalProjList.removeWhere((elem) => session.editedProjAndroid
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
          projList.add(finalProjList[i].path!.split('\\').last);
        } else if (Platform.isAndroid) {
          projList.add(finalProjList[i].path!.split('/').last);
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
      String lastSyncedTime = "";
      String lastsyncedDeviceID = '';
      var configData = await configurationService.getConfiguration();
      var syncedHistoryList = await syncHistoryService.getSyncHistory();
      var deviceList = await syncHistoryService.getSyncDeviceHistory();
      if (deviceList.isNotEmpty) {
        setState(() {
          lastsyncedDeviceID = deviceList.first.deviceID ?? '';
        });
      }

      String deviceId = lastsyncedDeviceID;

      //get lastSynced dateTime for corresponding deviceID
      var data =
          syncedHistoryList.where((element) => element.deviceId == deviceId);
      List<SyncHistoryModel> filteredHistoryList = [];
      if (data.isNotEmpty) {
        filteredHistoryList = data.toList();
        lastSyncedTime = filteredHistoryList.first.syncedTime ?? "";
      } else {
        lastSyncedTime = "";
      }

      DateTime lastSyncTime = lastSyncedTime != ""
          ? DateTime.parse(lastSyncedTime)
          : DateTime(1970);
      //get lastSynced dateTime for corresponding deviceID

      syncAlertPeriod = configData.first.syncExpTime ?? 0;
      int configHour = (configData.first.syncExpTime) ?? 0;

      DateTime checkwithHour = lastSyncTime.add(Duration(hours: configHour));
      DateTime now = DateTime.now();

      int year = now.year;
      int month = now.month;
      int day = now.day;

      DateTime nowDate = DateTime(year, month, day);
      String syncAlertStatus = HiveHelper().getSyncAlertStatus();

      if (syncedHistoryList.isNotEmpty && syncAlertStatus == "" ||
          syncAlertStatus != nowDate.toString()) {
        if (now.isAfter(checkwithHour) || checkwithHour == now) {
          showNotification();
          HiveHelper().saveSyncAlertStatus(nowDate.toString());
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
        enableLights: true,
        playSound: true,
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
      'Your android mobile has not been synced with windows system for more than ${syncAlertPeriod.toString()} hour',
      platform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: drawer(),
        appBar: appBar(),
        body: WillPopScope(
          onWillPop: () async => false,
          child: ListView(
            children: [
              Sizing.spacingHeight,
              isSearching || isSearching && tempList.length > 0
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: Sizing().height(4, 5),
                          horizontal: Sizing.width(7, 5)),
                      child: Text(
                        'Searched project',
                        style: subtitle1,
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: Sizing().height(4, 5),
                          horizontal: Sizing.width(7, 5)),
                      child: Text(
                        'Recent project',
                        style: subtitle1,
                      ),
                    ),
              Sizing.spacingHeight,
              loading
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Center(child: CommonUi().showLoading()),
                    )
                  : searchValue != "" && isSearching
                      ? Padding(
                          padding: Sizing.horizontalPadding,
                          child: searchedProjList(),
                        )
                      : Padding(
                          padding: Sizing.horizontalPadding,
                          child: lastAddedTenProj(),
                        )
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
                  Container(
                      margin: EdgeInsets.only(top: Sizing().height(5, 5)),
                      height: Sizing().height(50, 20),
                      child: Image.asset('assets/images/cardio_icon.png')),
                  Divider(
                    color: Color.fromARGB(32, 0, 0, 0),
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
                PageRouter.androidGenerateReport,
              );
            },
          ),
        ],
      ),
    );
  }

  receiveFromUsb() async {
    try {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        Directory directory = await FileMethods.getWindowsSaveDirectory();
        final dir = Directory(directory.path);
        var destinationPath = dir.path;
        var sourcePath = '/sdcard/Download/$dirFolderName';
        shellCommands('adb', ['pull', sourcePath, destinationPath]);
      }
    } on Exception catch (e) {
      Navigator.pop(context);
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  shellCommands(String cmd, List<String> cmds) async {
    try {
      var result = await Process.run(cmd, cmds);
      var output = result.stdout;
      var err = result.stderr;

      if (result.exitCode == 0) {
        Directory directory = await FileMethods.getWindowsSaveDirectory();
        final dir = Directory('${directory.path}$dirFolderName');
        var sourcePath = dir.path;
        var destinationPath = '/sdcard/Download/';

        var result1 = await Process.run(
            'adb', ['push', '--sync', sourcePath, destinationPath]);
        var output1 = result1.stdout;
        var err1 = result1.stderr;
        if (result1.exitCode == 0) {
          List<ImageLogModel> res = await imageService.getImageLog();
          List<String> imgLogName =
              res.map<String>((e) => e.imageName ?? "").toList();
          setState(() {
            imageData = res;
            imgName = imgLogName;
          });

          Directory directory = await FileMethods.getWindowsSaveDirectory();
          final dir = Directory('${directory.path}$dirFolderName');
          listFiles(dir);
          imageService.saveImagLog(imageLog);
          var sourcePath2 = Directory('${directory.path}$dirConfigFolderName');
          var destinationPath2 = '/sdcard/Download';
          var getcsvFiles = await Process.run(
              'adb', ['push', sourcePath2.path, destinationPath2]);
          var output2 = getcsvFiles.stdout;
          var err2 = getcsvFiles.stderr;
          if (getcsvFiles.exitCode == 0) {
            progressResult = output.toString().split(':').last;
            progressResult = progressResult.replaceAll("pulled", "transfered");
            dashboardBloc.setProgressIconStatus(true);
            dashboardBloc.setProgressPercentage(progressResult);
            dashboardBloc.setProgressText("Sync Completed");
            dashboardBloc.setProgressButtonStatus(true);
          } else if (output2.toString().toLowerCase().contains("no devices")) {
            Navigator.pop(context);

            errorLog.add(ErrorLogModel(
                errorDescription: output2.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
          } else {
            Navigator.pop(context);

            errorLog.add(ErrorLogModel(
                errorDescription: output2.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            errorLog.add(ErrorLogModel(
                errorDescription: err2.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
          }
        } else if (output1.toString().toLowerCase().contains("no devices")) {
          Navigator.pop(context);

          errorLog.add(ErrorLogModel(
              errorDescription: output1.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
        } else {
          Navigator.pop(context);

          errorLog.add(ErrorLogModel(
              errorDescription: output1.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
          errorLog.add(ErrorLogModel(
              errorDescription: err1.toString(),
              duration: DateTime.now().toString()));
          errorLogService.saveErrorLog(errorLog);
        }
      } else if (output.toString().toLowerCase().contains("no devices")) {
        Navigator.pop(context);
        CherryToast.error(
                title: Text(
                  "No device found",
                  style: TextStyle(fontSize: Sizing().height(9, 3)),
                ),
                autoDismiss: true)
            .show(context);
        errorLog.add(ErrorLogModel(
            errorDescription: output.toString(),
            duration: DateTime.now().toString()));
        errorLogService.saveErrorLog(errorLog);
      } else {
        Navigator.pop(context);
        CherryToast.error(
                title: Text(
                  "Please try again, file(s) / folder(s) not synced",
                  style: TextStyle(fontSize: Sizing().height(9, 3)),
                ),
                autoDismiss: true)
            .show(context);
        errorLog.add(ErrorLogModel(
            errorDescription: output.toString(),
            duration: DateTime.now().toString()));
        errorLogService.saveErrorLog(errorLog);
        errorLog.add(ErrorLogModel(
            errorDescription: err.toString(),
            duration: DateTime.now().toString()));
        errorLogService.saveErrorLog(errorLog);
      }
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
        // showWifi ? wifiButton() : const SizedBox(),
        wifiButton(),
        refresh(),
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
        ),
      ),
    );
  }

  searchBox() {
    return Container(
        decoration: BoxDecoration(
          color: whiteColor,
          border: Border.all(color: whiteColor),
          borderRadius: BorderRadius.circular(5),
        ),
        margin: EdgeInsets.symmetric(
            vertical: Sizing.getScreenWidth(context) > 1000
                ? 5
                : Sizing().height(5, 2),
            horizontal: Sizing.width(5, 2)),
        width:
            Sizing.getScreenWidth(context) > 1000 ? 500 : Sizing.width(60, 200),
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
                    if ((element.path ?? '')
                        .split('\\')
                        .last
                        .contains(searchValue)) {
                      if (!plist.contains(element)) plist.add(element);
                    }
                  });
                  if (plist.length == 0) {
                    tempList = [];
                  } else if (!tempList.toSet().containsAll(plist.toSet())) {
                    tempList.addAll(plist);
                  }
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
                  ? 5
                  : Sizing().height(9, 1),
              left: Sizing.width(2, 2),
            ),
            enabledBorder: InputBorder.none,
            suffixIcon: Icon(
              Icons.search,
              color: primaryColor,
            ),
            border: InputBorder.none,
            hintText: 'Search',
            hintStyle: TextStyle(
                color: greyColor,
                fontSize: Sizing().height(10, 3),
                fontWeight: FontWeight.w400),
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
                receiveFromUsb();
              } else {
                Navigator.pop(context);
                CherryToast.error(
                        title: Text(
                          "No device found",
                          style: TextStyle(fontSize: Sizing().height(9, 3)),
                        ),
                        autoDismiss: true)
                    .show(context);
              }
            } on Exception catch (e) {
              Navigator.pop(context);
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

  syncloader() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: Sizing().height(5, 3),
                ),
                StreamBuilder(
                  stream: dashboardBloc.iconProgressStream,
                  initialData: false,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    return snapshot.data ?? false
                        ? CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(
                              Icons.done,
                              color: Colors.white,
                            ),
                          )
                        : LinearProgressIndicator(
                            backgroundColor: greyColor,
                            color: Colors.green,
                            minHeight: Sizing().height(3, 4),
                          );
                  },
                ),
                SizedBox(
                  height: Sizing().height(2, 5),
                ),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: StreamBuilder(
                    stream: dashboardBloc.progressTextStream,
                    initialData: "Sync Started",
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      return Text(
                        snapshot.data ?? "",
                        style: body2.copyWith(fontWeight: FontWeight.normal),
                      );
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: StreamBuilder(
                    stream: dashboardBloc.progressPercentageStream,
                    initialData: "",
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      return Text(
                        snapshot.data ?? "",
                        style: body3.copyWith(fontWeight: FontWeight.normal),
                      );
                    },
                  ),
                )
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
                              margin: EdgeInsets.only(
                                  bottom: Sizing().height(10, 4)),
                              decoration: BoxDecoration(
                                color: primaryColor,
                              ),
                              child: TextButton(
                                  onPressed: () async {
                                    try {
                                      Navigator.of(context).pop(true);
                                      getFiles();
                                    } on Exception catch (e) {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription: e.toString(),
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                    }
                                  },
                                  child: Text(
                                    'Ok',
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
        });
  }

  wifiButton() {
    return PopupMenuButton<int>(
      icon: Icon(
        Icons.wifi,
        size: Sizing().height(20, 6),
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
                      await Future.delayed(Duration(seconds: 2));
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
                receiveFromUsb();
              } else {
                errorLog.add(ErrorLogModel(
                    errorDescription: output.toString(),
                    duration: DateTime.now().toString()));
                errorLogService.saveErrorLog(errorLog);
                Navigator.pop(context);
                CherryToast.error(
                        title: Text(
                          "No device found",
                          style: TextStyle(fontSize: Sizing().height(9, 3)),
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
            receiveFromUsb();
          } else {
            errorLog.add(ErrorLogModel(
                errorDescription: output.toString(),
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            Navigator.pop(context);
            CherryToast.error(
                    title: Text(
                      "No device found",
                      style: TextStyle(fontSize: Sizing().height(9, 3)),
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
    var res;
    if (isSearching && tempList.length > 0) {
      res = SizedBox(
        child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            primary: false,
            physics: ScrollPhysics(),
            itemCount: tempList.length,
            itemBuilder: (context, index) {
              String projectNo;
              var foldername = (tempList[index].path ?? '').split('/').last;

              if (foldername.contains('_')) {
                projectNo = foldername.split('_')[1];
              } else {
                projectNo = foldername;
              }
              return InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(
                      PageRouter.androidSubFolderPage,
                      arguments: {"projName": foldername});
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
                      foldername,
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 20)
                          : TextStyle(),
                    ),
                  ),
                ),
              );
            }),
      );
    } else if (isSearching && tempList.length == 0) {
      res = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No project found'),
        ],
      );
    }
    return res;
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
              var foldername = currentItem.path!.split('/').last;
              String projectNo;
              String projectname;

              if (foldername.contains('_')) {
                projectNo = foldername.split('_')[1];
                projectname = foldername.split('_')[0];
              } else {
                projectNo = foldername;
                projectname = "-";
              }
              return InkWell(
                onTap: () {
                  if (Platform.isWindows) {
                    Navigator.of(context).pushNamed(PageRouter.subFolderPage,
                        arguments: {
                          "projName": currentItem.path!.split('\\').last
                        });
                  } else if (Platform.isAndroid) {
                    Navigator.of(context)
                        .pushNamed(PageRouter.androidSubFolderPage, arguments: {
                      "projName": currentItem.path!.split('/').last
                    });
                  }
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
                          ? currentItem.path!.split('\\').last
                          : foldername,
                      style: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? TextStyle(fontSize: 20)
                          : TextStyle(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
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
                              size: Platform.isAndroid
                                  ? Sizing.getScreenWidth(context) > 1000
                                      ? 35
                                      : Sizing().height(18, 20)
                                  : 25,
                            )),
                        IconButton(
                          tooltip: "Delete Folder",
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
                                                        fontSize: Platform
                                                                .isWindows
                                                            ? Sizing()
                                                                .height(2, 3)
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
                                                          ? currentItem.path!
                                                              .split('\\')
                                                              .last
                                                          : currentItem.path!
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
                                                                recursive:
                                                                    true);
                                                      }
                                                      backupProjectFolderDir =
                                                          Directory(
                                                              '${directory.path}/$dirFolderName/ProjectFolderBackup/$projName');
                                                      if (!await backupProjectFolderDir
                                                          .exists()) {
                                                        await backupProjectFolderDir
                                                            .create(
                                                                recursive:
                                                                    true);
                                                      }
                                                      //create backupFolder in PhotoApp
                                                      copyDirectory(
                                                          newDirectory,
                                                          backupProjectFolderDir);

                                                      //copy the project folder to backup folder

                                                      if (await newDirectory
                                                          .exists()) {
                                                        await newDirectory
                                                            .delete(
                                                                recursive:
                                                                    true);
                                                      }

                                                      //Delete the project in photoSyncFolderDir
                                                      Directory
                                                          photoSyncFolderDir =
                                                          Directory(
                                                              '${directory.path}/$dirFolderName/PhotoSync/$projName');
                                                      if (await photoSyncFolderDir
                                                          .exists()) {
                                                        await photoSyncFolderDir
                                                            .delete(
                                                                recursive:
                                                                    true);
                                                      }
                                                      //Delete the project in photoSyncFolderDir

                                                      setState(() {
                                                        session.deletedProject
                                                            .add(projName);
                                                        getFiles();
                                                      });

                                                      //delete the mapped project in file
                                                      List<ProjectAndTemplateMapModel>
                                                          pData =
                                                          await projTempService
                                                              .getProjectAndTemplateMapping();
                                                      pData.removeWhere(
                                                          (element) =>
                                                              element
                                                                  .project
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
                                                                        .height(
                                                                            9,
                                                                            3)),
                                                              ),
                                                              autoDismiss: true)
                                                          .show(context);
                                                    } on Exception catch (e) {
                                                      errorLog.add(
                                                          ErrorLogModel(
                                                              errorDescription:
                                                                  e.toString(),
                                                              duration: DateTime
                                                                      .now()
                                                                  .toString()));
                                                      errorLogService
                                                          .saveErrorLog(
                                                              errorLog);
                                                    }
                                                  },
                                                  child: Text(
                                                    'Yes',
                                                    style: TextStyle(
                                                        fontSize: Platform
                                                                .isWindows
                                                            ? Sizing()
                                                                .height(2, 3)
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
                      ],
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
  final configurationService = ConfigurationService();
  final TextEditingController _password = TextEditingController();
  bool showErrorMsg = false;
  bool incorrectErrorMsg = false;
  List<ConfigurationModel> passwordconfigData = [];
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
                    fontWeight: FontWeight.w300),
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
                        var res = await configurationService.getConfiguration();
                        if (res.isNotEmpty) {
                          passwordconfigData = res;
                        }
                        if (passwordconfigData.isNotEmpty &&
                            _password.text == passwordconfigData[0].password) {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed(
                            PageRouter.configuration,
                          );
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
    return TextField(
      controller: _password,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(2, 3)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Password',
          labelStyle:
              TextStyle(color: Colors.grey, fontSize: Sizing().height(2, 3))),
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
          incorrectErrorMsg = false;
        });
      },
    );
  }
}
