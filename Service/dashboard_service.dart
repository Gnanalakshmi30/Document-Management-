import 'dart:io';

import 'package:USB_Share/Dashboard/Model/SyncDeviceHistoryModel.dart';
import 'package:USB_Share/Dashboard/Model/SyncHistoryModel.dart';
import 'package:USB_Share/Dashboard/Model/versionModel.dart';
import 'package:USB_Share/Util/constant.dart';

class DashboardService {
  Future<List<SyncHistoryModel>> getSyncHistory() async {
    try {
      var res =
          await Constants.readFileData(await Constants.getDataFilePath('SH'));
      List<SyncHistoryModel> configList = SyncHistoryModel.fromCSV(res);
      configList.sort((a, b) => b.syncedTime!.compareTo(a.syncedTime!));
      return configList;
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveSyncHistory(List<SyncHistoryModel> configlist) async {
    try {
      List<List<dynamic>> data = (configlist).map((e) => e.toList()).toList();
      var res = await Constants.writeFileData(
          await Constants.getDataFilePath('SH'), "SH", data,
          m: FileMode.append);
      return res;
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<List<SyncDeviceHistoryModel>> getSyncDeviceHistory() async {
    try {
      var res =
          await Constants.readFileData(await Constants.getDataFilePath('SDH'));
      List<SyncDeviceHistoryModel> historylist =
          SyncDeviceHistoryModel.fromCSV(res);
      historylist.sort((a, b) => b.deviceID!.compareTo(a.deviceID!));
      return historylist;
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveSyncDeviceHistory(
      List<SyncDeviceHistoryModel> historylist) async {
    try {
      List<List<dynamic>> data = (historylist).map((e) => e.toList()).toList();
      var res = await Constants.writeFileData(
          await Constants.getDataFilePath('SDH'), "SDH", data,
          m: FileMode.write);
      return res;
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<List<VersionModel>> getversionHistory() async {
    try {
      var res =
          await Constants.readFileData(await Constants.getDataFilePath('VF'));
      List<VersionModel> versionlist = VersionModel.fromCSV(res);
      versionlist.sort((a, b) => b.version!.compareTo(a.version!));
      return versionlist;
    } catch (e) {
      return [];
    }
  }
}
