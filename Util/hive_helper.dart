import 'package:hive/hive.dart';

class HiveHelper {
  static final HiveHelper _singleton = new HiveHelper._internal();
  factory HiveHelper() {
    return _singleton;
  }
  HiveHelper._internal();

  void addProject(Map<String, dynamic> newProj) async {
    var box = Hive.box('appData');
    box.put('proj', newProj);
  }

  Map<String, dynamic> getProject() {
    var box = Hive.box('appData');
    var projList = box.get('proj');
    return projList;
  }

  void saveSyncedTime(String syncTime) async {
    var box = Hive.box('appData');
    box.put('sync', syncTime);
  }

  String getSyncedTime() {
    var box = Hive.box('appData');
    dynamic syncTime = box.get('sync');
    if (syncTime is String) {
      return syncTime;
    } else {
      return "";
    }
  }

  void saveSyncAlertStatus(String alertDateTime) async {
    var box = Hive.box('appData');
    box.put('syncDate', alertDateTime);
  }

  String getSyncAlertStatus() {
    var box = Hive.box('appData');
    dynamic alertDateTime = box.get('syncDate');
    if (alertDateTime is String) {
      return alertDateTime;
    } else {
      return "";
    }
  }

  void saveLicenseKeyStatus(bool success) async {
    var box = Hive.box('appData');
    box.put('licenseKey', success);
  }

  bool getLicenseKeyStatus() {
    var box = Hive.box('appData');
    bool? success = box.get('licenseKey');
    if (success != null) {
      return success;
    } else {
      return false;
    }
  }

  void saveIMEIId(bool syncStatus) async {
    var box = Hive.box('appData');
    box.put('imeiId', syncStatus);
  }

  bool getIMEIId() {
    var box = Hive.box('appData');
    bool? syncStatus = box.get('imeiId');
    if (syncStatus != null) {
      return syncStatus;
    } else {
      return false;
    }
  }

  void saveLicenseExpiryAlertDate(String alertDate) async {
    var box = Hive.box('appData');
    box.put('licens', alertDate);
  }

  String getLicenseExpiryAlertDate() {
    var box = Hive.box('appData');
    dynamic alertDate = box.get('licens');
    if (alertDate is String) {
      return alertDate;
    } else {
      return "";
    }
  }

  void saveLicenseExpired(bool expiryStatus) async {
    var box = Hive.box('appData');
    box.put('expiry', expiryStatus);
  }

  bool getLicenseExpired() {
    var box = Hive.box('appData');
    bool? expiryStatus = box.get('expiry');
    if (expiryStatus != null) {
      return expiryStatus;
    } else {
      return false;
    }
  }
}
