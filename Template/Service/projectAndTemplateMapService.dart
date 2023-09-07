import 'dart:io';

import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Model/templateAndCategoryMapModel.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:path_provider/path_provider.dart';

class ProjectAndTemplateMapService {
  Future<List<ProjectAndTemplateMapModel>>
      getProjectAndTemplateMapping() async {
    try {
      if (Constants.isAPI) {
        // DioApiBaseHelper helper = DioApiBaseHelper();
        // var dio = await helper.getApiClient();

        // var response = await dio.get('Configuration/GetConfiguration');
        // if (response.statusCode == 200 && response.data != null) {
        //   final result = List<Map<String, dynamic>>.from(response.data);
        //   var dataLst =
        //       result.map((x) => ReportCategoryModel.fromJson(x)).toList();
        //   return dataLst;
        // }
        return [];
      } else {
        var res = await Constants.readFileData(
            await Constants.getDataFilePath('PTM'));
        List<ProjectAndTemplateMapModel> projectTemplateMappingList =
            ProjectAndTemplateMapModel.fromCSV(res);
        return projectTemplateMappingList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveProjectAndTemplateMapping(
      List<ProjectAndTemplateMapModel> projectTemplateMappingList) async {
    try {
      if (Constants.isAPI) {
        // DioApiBaseHelper helper = DioApiBaseHelper();
        // var dio = await helper.getApiClient();
        // var data = categoryList.map((e) => e.toJson()).toList();
        // var response =
        //     await dio.post('Configuration/SaveConfiguration', data: data);
        // if (response.statusCode == 200 && response.data != null) {
        //   return Future.value(response.data);
        // }
        return Future.value(false);
      } else {
        List<List<dynamic>> data =
            (projectTemplateMappingList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('PTM'), "PTM", data,
            m: FileMode.write);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<Map<String, String>> getImageFiles(Directory path) async {
    Map<String, String> imageMap = {};

    // Get the list of files in the directory
    Directory directory = Directory(path.path);
    List<FileSystemEntity> fileList =
        directory.listSync(recursive: true, followLinks: false);

    // Iterate through the files and filter for images
    for (FileSystemEntity entity in fileList) {
      if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
        String fileName = entity.path.split('/').last;
        fileName.replaceAll('/', '\\');
        if (fileName.contains('\\')) {
          fileName = fileName.split('\\').last;
        }

        imageMap[fileName] = entity.path;
      }
    }

    return imageMap;
  }
}
