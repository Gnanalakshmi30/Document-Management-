class ProjectAndTemplateMapModel {
  int? id;
  String? project;
  String? templateName;
  String? createdDate;

  ProjectAndTemplateMapModel(
      {this.id, this.project, this.templateName, this.createdDate});

  ProjectAndTemplateMapModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    project = json['project'];
    templateName = json['templateName'];
    createdDate = json['createdDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['project'] = project;
    data['templateName'] = templateName;
    data['createdDate'] = createdDate;
    return data;
  }

  static List<ProjectAndTemplateMapModel> fromCSV(List<List<dynamic>>? data) {
    List<ProjectAndTemplateMapModel> reportCatList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[0] != null && e[0] != "") {
            reportCatList.add(ProjectAndTemplateMapModel(
                id: e[0],
                project: e[1].toString(),
                templateName: e[2],
                createdDate: e[3]));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return reportCatList;
  }

  List<dynamic> toList() => [id, project, templateName, createdDate];
}
