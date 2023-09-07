class ReportCategoryModel {
  int? categoryID;
  String? categoryName;

  ReportCategoryModel({this.categoryID, this.categoryName});

  ReportCategoryModel.fromJson(Map<String, dynamic> json) {
    categoryID = json['categoryID'];
    categoryName = json['categoryName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['categoryID'] = categoryID;
    data['categoryName'] = categoryName;
    return data;
  }

  static List<ReportCategoryModel> fromCSV(List<List<dynamic>>? data) {
    List<ReportCategoryModel> reportCatList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          reportCatList.add(ReportCategoryModel(
            categoryID: e[0],
            categoryName: e[1],
          ));
        }
      }
    } catch (e) {
      rethrow;
    }
    return reportCatList;
  }

  List<dynamic> toList() => [categoryID, categoryName];
}
