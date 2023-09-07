class SyncDeviceHistoryModel {
  String? deviceID;

  SyncDeviceHistoryModel({
    this.deviceID,
  });

  SyncDeviceHistoryModel.fromJson(Map<String, dynamic> json) {
    deviceID = json['deviceID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['deviceID'] = deviceID;
    return data;
  }

  static List<SyncDeviceHistoryModel> fromCSV(List<List<dynamic>>? data) {
    List<SyncDeviceHistoryModel> historyList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[0] != null && e[0] != '') {
            historyList.add(SyncDeviceHistoryModel(
              deviceID: e[0],
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return historyList;
  }

  List<dynamic> toList() => [deviceID];
}
