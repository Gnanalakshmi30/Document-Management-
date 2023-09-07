class SyncHistoryModel {
  String? deviceId;
  String? syncedTime;
  String? syncMode;
  int? noOfFiles;
  int? imageFiles;

  SyncHistoryModel(
      {this.deviceId,
      this.noOfFiles,
      this.syncMode,
      this.syncedTime,
      this.imageFiles});

  SyncHistoryModel.fromJson(Map<String, dynamic> json) {
    deviceId = json['deviceId'];
    syncedTime = json['syncedTime'];
    syncMode = json['syncMode'];
    noOfFiles = json['noOfFiles'];
    imageFiles = json["imageFiles"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['deviceId'] = deviceId;
    data['syncedTime'] = syncedTime;
    data['syncMode'] = syncMode;
    data['noOfFiles'] = noOfFiles;
    data['imageFiles'] = imageFiles;
    return data;
  }

  static List<SyncHistoryModel> fromCSV(List<List<dynamic>>? data) {
    List<SyncHistoryModel> configList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[1] != null && e[1] != '') {
            configList.add(
              SyncHistoryModel(
                  deviceId: e[0],
                  syncedTime: e[1],
                  syncMode: e[2],
                  noOfFiles: e[3] == null || e[3] == '' ? 0 : e[3],
                  imageFiles: e[4] == null || e[4] == '' ? 0 : e[4]),
            );
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return configList;
  }

  List<dynamic> toList() =>
      [deviceId, syncedTime, syncMode, noOfFiles, imageFiles];
}
