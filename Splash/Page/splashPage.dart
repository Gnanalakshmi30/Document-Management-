import 'dart:async';
import 'dart:io';
import 'package:USB_Share/Configuration/Model/config_model.dart';
import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/Util/hive_helper.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    if (Platform.isAndroid) {
      getFileAccessPermission();
    }
    if (Platform.isWindows) {
      getConfigData();
      checkDataFileExist();
      bool licenseStatus = HiveHelper().getLicenseKeyStatus();
      if (licenseStatus) {
        checkLicenseValidity();
      }
    }
    session.deletedProject = [];
    session.editedProjAndroid = [];
    session.editedProjWindows = [];

    super.initState();

    Timer(const Duration(seconds: 5), () {
      if (Platform.isWindows) {
        bool expiryStatus = HiveHelper().getLicenseExpired();
        if (expiryStatus) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              PageRouter.licenseExpied, (Route<dynamic> route) => false);
        } else {
          Navigator.of(context)
              .pushReplacementNamed(PageRouter.dashboard, arguments: {
            "index": 0,
            "newProjCreated": false,
          });
        }
      } else if (Platform.isAndroid) {
        Navigator.of(context).pushNamed(
          PageRouter.androidDashboardPage,
        );
      }
    });
  }

  final configurationService = ConfigurationService();
  final projTempService = ProjectAndTemplateMapService();
  List<ConfigurationModel> configData = [];
  String dirFolderName = "";

  checkLicenseValidity() async {
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
          String currentDate = Constants.licenseFormat.format(now);

          Duration difference =
              toDateDateTime.difference(DateTime.parse(currentDate));
          if (difference.inDays <= 30) {
            setState(() {
              session.needToRenew = true;
            });
          }

          if (difference.isNegative ||
              toDateDateTime == DateTime.parse(currentDate)) {
            //toDateDateTime is in the past.
            HiveHelper().saveLicenseExpired(true);
            Navigator.of(context).pushNamedAndRemoveUntil(
                PageRouter.licenseExpied, (Route<dynamic> route) => false);
          }
        }
      }
    }
  }

  getFileAccessPermission() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var release = androidInfo.version.release;
    int androidVersion = int.parse(release);

    final storagePermissionStatus = Platform.isAndroid && androidVersion < 11
        ? await Permission.storage.status
        : await Permission.manageExternalStorage.status;

    if (storagePermissionStatus.isGranted) {
      HiveHelper().saveSyncAlertStatus("");
      autoDelete();
      getConfigData();
      checkDataFileExist();
    } else if (storagePermissionStatus.isDenied) {
      Platform.isAndroid && androidVersion < 11
          ? await Permission.storage.request()
          : await Permission.manageExternalStorage.request();
      HiveHelper().saveSyncAlertStatus("");
      autoDelete();
      getConfigData();
      checkDataFileExist();
    } else if (storagePermissionStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  autoDelete() async {
    try {
      Directory directory = await FileMethods.getSaveDirectory();
      final dir = Directory('${directory.path}$dirFolderName');
      if (await dir.exists()) {
        printDirectoryCreationDate(dir.path);
      }
    } on Exception catch (e) {
      throw e;
    }
  }

  void printDirectoryCreationDate(String directoryPath) {
    try {
      final directory = Directory(directoryPath);
      directory.listSync().forEach((entity) async {
        if (entity is Directory) {
          if (!entity.path.contains('ProjectFolderBackup') &&
              !entity.path.contains('Template')) {
            loopFolder(entity, directoryPath);
          }
        } else if (entity is File) {
          String dirName = entity.path.split('/').last;
          if (!dirName.contains('ProjectFolderBackup') &&
              !dirName.contains('Template')) {
            final stat = entity.statSync();
            DateTime modifiedDate = stat.modified;
            var configData = await configurationService.getConfiguration();
            if (configData.isNotEmpty) {
              int targetDay = (configData.first.targetDays) ?? 0;
              DateTime checkDay =
                  modifiedDate.add(Duration(hours: targetDay * 24));
              DateTime now = DateTime.now();

              if (checkDay.isBefore(now)) {
                if (await entity.exists()) {
                  //delete the mapped project in file
                  List<ProjectAndTemplateMapModel> pData =
                      await projTempService.getProjectAndTemplateMapping();

                  pData.removeWhere((element) =>
                      element.project.toString().toLowerCase().trim() ==
                      dirName.toLowerCase().trim());
                  projTempService.saveProjectAndTemplateMapping(pData);
                  //delete the mapped project in file
                  await entity.delete(recursive: true);
                }
                directory.listSync().remove(entity);
              }
            }
          }
        }
      });
    } on Exception catch (e) {
      throw e;
    }
  }

  loopFolder(Directory sourcePath, String directoryPath) {
    try {
      sourcePath.listSync().forEach((entity) async {
        if (entity is Directory) {
          loopFolder(entity, directoryPath);
        } else if (entity is File) {
          String dirName = entity.path.split('/').last;
          if (!dirName.contains('ProjectFolderBackup') &&
              !dirName.contains('Template')) {
            final stat = entity.statSync();
            DateTime modifiedDate = stat.modified;
            var configData = await configurationService.getConfiguration();
            if (configData.isNotEmpty) {
              int targetDay = (configData.first.targetDays) ?? 0;
              DateTime checkDay =
                  modifiedDate.add(Duration(hours: targetDay * 24));
              DateTime now = DateTime.now();

              if (checkDay.isBefore(now)) {
                if (await entity.exists()) {
                  //delete the mapped project in file
                  List<ProjectAndTemplateMapModel> pData =
                      await projTempService.getProjectAndTemplateMapping();

                  pData.removeWhere((element) =>
                      element.project.toString().toLowerCase().trim() ==
                      dirName.toLowerCase().trim());
                  projTempService.saveProjectAndTemplateMapping(pData);
                  //delete the mapped project in file

                  await entity.delete(recursive: true);
                }
                sourcePath.listSync().remove(entity);
              }
            }
          }
        }
      });
    } on Exception catch (e) {
      rethrow;
    }
  }

  getConfigData() async {
    List<ConfigurationModel> res =
        await configurationService.getConfiguration();
    setState(() {
      configData = res;
    });
  }

  checkDataFileExist() async {
    try {
      Directory dir = await Constants.getDataDirectory();

      if (!await dir.exists()) {
        await dir.create(recursive: true);

        //Create config files
        File config = File(await Constants.getDataFilePath('C'));
        ByteData data = await rootBundle.load('assets/data/configuration.csv');
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await config.writeAsBytes(bytes);

        //Create release file
        String destinationFolder = '${dir.path}';
        ByteData dataa =
            await rootBundle.load('assets/data/Release & Review.pdf');
        List<int> bytess =
            dataa.buffer.asUint8List(dataa.offsetInBytes, dataa.lengthInBytes);
        String fileName = 'Release & Review.pdf';
        String destinationPath = path.join(destinationFolder, fileName);
        Directory(destinationFolder).createSync(recursive: true);
        await File(destinationPath).writeAsBytes(bytess);
        //

        //Create projectTemplateMapping file
        File projectTemplateMap = File(await Constants.getDataFilePath('PTM'));
        data =
            await rootBundle.load('assets/data/ProjectAndTemplateMapping.csv');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await projectTemplateMap.writeAsBytes(bytes);

        //Create image log file
        File imageLog = File(await Constants.getDataFilePath('I'));
        data = await rootBundle.load('assets/data/ImageLog.csv');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await imageLog.writeAsBytes(bytes);

        //Create error log file
        File errorLog = File(await Constants.getDataFilePath('E'));
        data = await rootBundle.load('assets/data/ErrorLog.csv');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await errorLog.writeAsBytes(bytes);

        //Create Sync History file
        File syncHistory = File(await Constants.getDataFilePath('SH'));
        data = await rootBundle.load('assets/data/SyncHistory.csv');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await syncHistory.writeAsBytes(bytes);

        //Create ExtractContentFromWord python script file
        File extractContentFromWordPythonFile =
            File(await Constants.getDataFilePath('ECP'));

        data = await rootBundle.load('assets/extractContentFromWord.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        extractContentFromWordPythonFile.writeAsBytesSync(bytes, flush: true);

        //Create docxEditor python script file
        File replaceKeywordPythonFile =
            File(await Constants.getDataFilePath('RKP'));

        data = await rootBundle.load('assets/docxEditor.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        replaceKeywordPythonFile.writeAsBytesSync(bytes, flush: true);

        //Create extractTableData python script file
        File extractTableDataPythonFile =
            File(await Constants.getDataFilePath('ETDP'));

        data = await rootBundle.load('assets/extractTableData.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        extractTableDataPythonFile.writeAsBytesSync(bytes, flush: true);

        //Create replaceTable python script file
        File replaceTable = File(await Constants.getDataFilePath('RTP'));

        data = await rootBundle.load('assets/replaceTable.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        replaceTable.writeAsBytesSync(bytes, flush: true);

        //Create addrowtoTable python script file
        File addrowTable = File(await Constants.getDataFilePath('ART'));

        data = await rootBundle.load('assets/addrowtotable.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        addrowTable.writeAsBytesSync(bytes, flush: true);

        //Create modifyrow python script file
        File modifyTableRow = File(await Constants.getDataFilePath('MTR'));

        data = await rootBundle.load('assets/modify_table_row.py');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        modifyTableRow.writeAsBytesSync(bytes, flush: true);

        //Create password file
        File passwordFile = File(await Constants.getDataFilePath('PS'));
        data = await rootBundle.load('assets/data/Password.csv');
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await passwordFile.writeAsBytes(bytes);

        if (Platform.isWindows) {
          //Create decryptKey python script file
          File decryptKey = File(await Constants.getDataFilePath('DK'));

          data = await rootBundle.load('assets/data/decryptKey.py');
          bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          decryptKey.writeAsBytesSync(bytes, flush: true);

          //Create macAddress python script file
          File macAddress = File(await Constants.getDataFilePath('MC'));

          data = await rootBundle.load('assets/data/macAddress.py');
          bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          macAddress.writeAsBytesSync(bytes, flush: true);
        }

        //Create Version file
        ByteData date = await rootBundle.load('assets/data/Version.csv');
        List<int> byta =
            date.buffer.asUint8List(date.offsetInBytes, date.lengthInBytes);
        String fileeName = 'Version.csv';
        String destinationnPath = path.join(destinationFolder, fileeName);
        Directory(destinationFolder).createSync(recursive: true);
        await File(destinationnPath).writeAsBytes(byta);

        //Create SyncDeviceHistory file
        if (Platform.isWindows) {
          File syncDeviceHistory = File(await Constants.getDataFilePath('SDH'));
          data = await rootBundle.load('assets/data/SyncDeviceHistory.csv');
          bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await syncDeviceHistory.writeAsBytes(bytes);
        }

        //
      } else if (await dir.exists()) {
        //Create ExtractContentFromWord python script file
        File extractContentFromWordPythonFile =
            File(await Constants.getDataFilePath('ECP'));
        if (await extractContentFromWordPythonFile.exists()) {
          ByteData data =
              await rootBundle.load('assets/extractContentFromWord.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          extractContentFromWordPythonFile.writeAsBytesSync(bytes, flush: true);
        }

        //Create docxEditor python script file
        File replaceKeywordPythonFile =
            File(await Constants.getDataFilePath('RKP'));
        if (await replaceKeywordPythonFile.exists()) {
          ByteData data = await rootBundle.load('assets/docxEditor.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          replaceKeywordPythonFile.writeAsBytesSync(bytes, flush: true);
        }

        //Create extractTableData python script file
        File extractTableDataPythonFile =
            File(await Constants.getDataFilePath('ETDP'));
        if (await extractTableDataPythonFile.exists()) {
          ByteData data = await rootBundle.load('assets/extractTableData.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          extractTableDataPythonFile.writeAsBytesSync(bytes, flush: true);
        }

        //Create replaceTable python script file
        File replaceTable = File(await Constants.getDataFilePath('RTP'));
        if (await replaceTable.exists()) {
          ByteData data = await rootBundle.load('assets/replaceTable.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          replaceTable.writeAsBytesSync(bytes, flush: true);
        }

        //Create addrowtoTable python script file
        File addrowTable = File(await Constants.getDataFilePath('ART'));
        if (await addrowTable.exists()) {
          ByteData data = await rootBundle.load('assets/addrowtotable.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          addrowTable.writeAsBytesSync(bytes, flush: true);
        }

        //Create modifyrow python script file
        File modifyTableRow = File(await Constants.getDataFilePath('MTR'));
        if (await modifyTableRow.exists()) {
          ByteData data = await rootBundle.load('assets/modify_table_row.py');
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          modifyTableRow.writeAsBytesSync(bytes, flush: true);
        }

        if (Platform.isWindows) {
          //Create release file
          String destinationFolder = '${dir.path}';
          ByteData dataa =
              await rootBundle.load('assets/data/Release & Review.pdf');
          List<int> bytess = dataa.buffer
              .asUint8List(dataa.offsetInBytes, dataa.lengthInBytes);
          String fileName = 'Release & Review Version 1.4.pdf';
          String destinationPath = path.join(destinationFolder, fileName);
          Directory(destinationFolder).createSync(recursive: true);
          await File(destinationPath).writeAsBytes(bytess);

          //Create decryptKey python script file
          File decryptKey = File(await Constants.getDataFilePath('DK'));
          if (await decryptKey.exists()) {
            ByteData data = await rootBundle.load('assets/data/decryptKey.py');
            List<int> bytes =
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            decryptKey.writeAsBytesSync(bytes, flush: true);
          } else {
            ByteData data = await rootBundle.load('assets/data/decryptKey.py');
            List<int> bytes =
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            decryptKey.writeAsBytesSync(bytes, flush: true);
          }

          //Create macAddress python script file
          File macAddress = File(await Constants.getDataFilePath('MC'));
          if (await macAddress.exists()) {
            ByteData data = await rootBundle.load('assets/data/macAddress.py');
            List<int> bytes =
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            macAddress.writeAsBytesSync(bytes, flush: true);
          } else {
            ByteData data = await rootBundle.load('assets/data/macAddress.py');
            List<int> bytes =
                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            macAddress.writeAsBytesSync(bytes, flush: true);
          }
        }

        //Create Version file
        String destinationFolder = '${dir.path}';
        ByteData dataa = await rootBundle.load('assets/data/Version.csv');
        List<int> bytess =
            dataa.buffer.asUint8List(dataa.offsetInBytes, dataa.lengthInBytes);
        String fileName = 'Version.csv';
        String destinationPath = path.join(destinationFolder, fileName);
        Directory(destinationFolder).createSync(recursive: true);
        await File(destinationPath).writeAsBytes(bytess);
        //
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Color(0xfff6f6f6),
          body: Center(
            child: SizedBox(
              height: Sizing().height(200, 100),
              child: Lottie.asset('assets/images/splashLottie.json'),
            ),
          )),
    );
  }
}
