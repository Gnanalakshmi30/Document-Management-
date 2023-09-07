class TemplateAndCategoryMapModel {
  int? templateID;
  String? templateName;
  int? reportCategory;

  TemplateAndCategoryMapModel(
      {this.templateID, this.templateName, this.reportCategory});

  TemplateAndCategoryMapModel.fromJson(Map<String, dynamic> json) {
    templateID = json['templateID'];
    templateName = json['templateName'];
    reportCategory = json['reportCategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['templateID'] = templateID;
    data['templateName'] = templateName;
    data['reportCategory'] = reportCategory;
    return data;
  }

  static List<TemplateAndCategoryMapModel> fromCSV(List<List<dynamic>>? data) {
    List<TemplateAndCategoryMapModel> reportCatList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[0] != null && e[0] != "") {
            reportCatList.add(TemplateAndCategoryMapModel(
              templateID: e[0],
              templateName: e[1],
              reportCategory: e[2],
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return reportCatList;
  }

  List<dynamic> toList() => [templateID, templateName, reportCategory];
}
