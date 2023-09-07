class ErrorLogModel {
  String? errorDescription;
  String? duration;

  ErrorLogModel({this.errorDescription, this.duration});

  ErrorLogModel.fromJson(Map<String, dynamic> json) {
    errorDescription = json['errorDescription'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['errorDescription'] = errorDescription;
    data['duration'] = duration;
    return data;
  }

  static List<ErrorLogModel> fromCSV(List<List<dynamic>>? data) {
    List<ErrorLogModel> errorLogList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          errorLogList.add(ErrorLogModel(
            errorDescription: e[0],
            duration: e[1],
          ));
        }
      }
    } catch (e) {
      rethrow;
    }
    return errorLogList;
  }

  List<dynamic> toList() => [errorDescription, duration];
}
