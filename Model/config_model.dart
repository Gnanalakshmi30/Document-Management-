class ConfigurationModel {
  int? targetDays;
  int? syncExpTime;
  int? captionID;
  String? captionName;
  String? password;
  String? wifiOrUsb;

  ConfigurationModel(
      {this.targetDays,
      this.syncExpTime,
      this.captionID,
      this.captionName,
      this.password,
      this.wifiOrUsb});

  ConfigurationModel.fromJson(Map<String, dynamic> json) {
    targetDays = json['targetDays'];
    syncExpTime = json['syncExpTime'];
    captionID = json['captionID'];
    captionName = json['captionName'];
    password = json['password'];
    wifiOrUsb = json['wifiOrUsb'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['targetDays'] = targetDays;
    data['syncExpTime'] = syncExpTime;
    data['captionID'] = captionID;
    data['captionName'] = captionName;
    data['password'] = password ?? "";
    data['wifiOrUsb'] = wifiOrUsb ?? '';
    return data;
  }

  static List<ConfigurationModel> fromCSV(List<List<dynamic>>? data) {
    List<ConfigurationModel> configList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          configList.add(
            ConfigurationModel(
                targetDays: e[0],
                syncExpTime: e[1],
                captionID: e[2],
                captionName: e[3],
                password: (e[4] ?? '').toString(),
                wifiOrUsb: e[5]),
          );
        }
      }
    } catch (e) {
      rethrow;
    }
    return configList;
  }

  List<dynamic> toList() =>
      [targetDays, syncExpTime, captionID, captionName, password, wifiOrUsb];
}
