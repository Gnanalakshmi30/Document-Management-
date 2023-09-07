class SaveCreatedDateModel {
  String? folderName;
  String? createdDate;

  SaveCreatedDateModel({this.folderName, this.createdDate});

  SaveCreatedDateModel.fromJson(Map<String, dynamic> json) {
    folderName = json['folderName'];
    createdDate = json['createdDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['folderName'] = folderName;
    data['createdDate'] = createdDate;
    return data;
  }

  static List<SaveCreatedDateModel> fromCSV(List<List<dynamic>>? data) {
    List<SaveCreatedDateModel> saveCreatedDateList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          saveCreatedDateList.add(SaveCreatedDateModel(
            folderName: e[0],
            createdDate: e[1],
          ));
        }
      }
    } catch (e) {
      rethrow;
    }
    return saveCreatedDateList;
  }

  List<dynamic> toList() => [folderName, createdDate];
}
