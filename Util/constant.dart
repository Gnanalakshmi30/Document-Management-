// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Constants {
  static bool isAPI = false;

  static String basePath = '/sdcard/Download';

  static String dataFolder = '.CardioPunChemical';
  static String directoryFolderName = 'CardioPunChemical';
  static String appName = 'Cardio_Pun_Chemical';

  static String envPath = Platform.environment['USERPROFILE']! + r'\Documents\';

  static DateFormat dFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static DateFormat licenseFormat = DateFormat('yyyy-MM-dd HH:mm');
  static DateFormat dateAloneFormat = DateFormat('yyyy-MM-dd');

  static DateFormat modifiedDateFormat = DateFormat('dd-MM-yyyy hh:mm a');

//Data files
  static String configFile = 'Configuration.csv';
  static String reportCategoryFile = 'ReportCategory.csv';
  static String reportAndTemplateMapFile =
      'TemplateAndReportCategoryMapping.csv';
  static String projectTemplateMappingFile = 'ProjectAndTemplateMapping.csv';
  static String syncHistory = 'SyncHistory.csv';
  static String imageLogFile = 'ImageLog.csv';
  static String errorFile = 'ErrorFile.csv';
  static String templateStyleFile = 'TemplateStyle.csv';
  static String fontFamilyFile = 'FontFamily.csv';
  static String replaceKeywordPythonFile = 'docxEditor.py';
  static String extractContentFromWordPythonFile = 'extractContentFromWord.py';
  static String extractTableDataPythonFile = 'extractTableData.py';
  static String replaceTablePythonFile = 'replaceTable.py';
  static String storeCreatedDateAndroid = 'StoreCreatedDateAndroid.csv';
  static String passwrodFile = 'Password.csv';
  static String decryptKey = 'decryptKey.py';
  static String macAddress = 'macAddress.py';
  static String syncDeviceHistory = 'SyncDeviceHistory.csv';
  static String version = 'version.csv';
  //Added by Prasanna
  static String addrowtotable = 'addrowtotable.py';
  static String modifyTableRow = 'modify_table_row.py';

  static Future<Directory> getDataDirectory() async {
    Directory dir;
    if (Platform.isWindows) {
      Directory winDir = await getApplicationDocumentsDirectory();
      dir = Directory('${winDir.path}/$dataFolder');
    } else {
      dir = Directory('${basePath}/${dataFolder}');
    }
    return dir;
  }

  static Future<String> getDataFilePath(String code) async {
    Directory dir;
    if (Platform.isWindows) {
      Directory winDir = await getApplicationDocumentsDirectory();
      dir = Directory('${winDir.path}/$dataFolder');
    } else {
      dir = Directory('${basePath}/${dataFolder}');
    }

    if (code == 'C') {
      return '${dir.path}/$configFile';
    } else if (code == 'R') {
      return '${dir.path}/$reportCategoryFile';
    } else if (code == 'TM') {
      return '${dir.path}/$reportAndTemplateMapFile';
    } else if (code == 'PTM') {
      return '${dir.path}/$projectTemplateMappingFile';
    } else if (code == 'I') {
      return '${dir.path}/$imageLogFile';
    } else if (code == 'E') {
      return '${dir.path}/$errorFile';
    } else if (code == 'TS') {
      return '${dir.path}/$templateStyleFile';
    } else if (code == 'FF') {
      return '${dir.path}/$fontFamilyFile';
    } else if (code == 'RKP') {
      return '${dir.path}/$replaceKeywordPythonFile';
    } else if (code == 'ECP') {
      return '${dir.path}/$extractContentFromWordPythonFile';
    } else if (code == 'ETDP') {
      return '${dir.path}/$extractTableDataPythonFile';
    } else if (code == 'RTP') {
      return '${dir.path}/$replaceTablePythonFile';
    } else if (code == 'SH') {
      return '${dir.path}/$syncHistory';
    } else if (code == 'SDH') {
      return '${dir.path}/$syncDeviceHistory';
    } else if (code == 'ART') {
      return '${dir.path}/$addrowtotable';
    } else if (code == 'MTR') {
      return '${dir.path}/$modifyTableRow';
    } else if (code == 'DK') {
      return '${dir.path}/$decryptKey';
    } else if (code == 'VF') {
      return '${dir.path}/$version';
    } else if (code == 'MC') {
      return '${dir.path}/$macAddress';
    } else if (code == 'PS') {
      return '${dir.path}/$passwrodFile';
    } else if (code == 'SCDA') {
      return '${dir.path}/$storeCreatedDateAndroid';
    } else {
      return '';
    }
  }

  static Future<List<List>> readFileData(String csvPath) async {
    try {
      String csvData = await File(csvPath).readAsString();
      List<List<dynamic>> csvTable =
          const CsvToListConverter().convert(csvData);

      csvTable = csvTable
          .where((row) =>
              row.any((cell) => cell != null && cell.toString().isNotEmpty))
          .toList();
      return csvTable;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> writeFileData(
      String csvPath, String code, List<List<dynamic>>? data,
      {FileMode m = FileMode.append}) async {
    try {
      if (data != null) {
        List<String> headers = [];
        if (code == 'C') {
          headers = [
            'TargetDays',
            'SyncExpTime',
            'CaptionID',
            'CaptionName',
            'Password',
            'WifiOrUsb'
          ];
        } else if (code == 'R') {
          headers = ['CategoryID', 'CategoryName'];
        } else if (code == 'TM') {
          headers = ['TemplateID', 'TemplateName', 'ReportCategory'];
        } else if (code == 'PTM') {
          headers = ['Id', 'Project', 'ReportCategoryName', 'CreatedDate'];
        } else if (code == 'I') {
          headers = ['ImageName', 'SyncedDate'];
        } else if (code == 'E') {
          headers = ['ErrorDescription', 'Duration'];
        } else if (code == 'TS') {
          headers = ['FontSize', 'FontFamily'];
        } else if (code == 'FF') {
          headers = ['FontFamilyId', 'FontFamily'];
        } else if (code == 'SCD' || code == 'SCDA') {
          headers = ['FolderName', 'CreatedDate'];
        } else if (code == 'PS') {
          headers = ['Password', 'Duration'];
        } else if (code == 'SDH') {
          headers = ['DeviceID'];
        }
        if (m == FileMode.write) {
          data.insert(0, headers);
        } else {
          data.insert(0, ['']);
        }
        File csvFile = File(csvPath);
        String fData = const ListToCsvConverter().convert(data);
        await csvFile.writeAsString(fData, mode: m);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
