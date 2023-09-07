import 'dart:io';

class ProjectModel {
  List<FileSystemEntity>? entityList;
  bool? selectedEntity;

  ProjectModel({this.entityList, this.selectedEntity});

  ProjectModel.fromJson(Map<String, dynamic> json) {
    entityList = json['entityList'];
    selectedEntity = json['selectedEntity'] = false;
  }
}

class DirectoryInfo {
  String? path;
  String? modifiedDate;

  DirectoryInfo({this.path, this.modifiedDate});

  DirectoryInfo.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    modifiedDate = json['modifiedDate'];
  }
}
