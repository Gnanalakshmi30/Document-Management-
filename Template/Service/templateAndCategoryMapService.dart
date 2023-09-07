import 'dart:io';

import 'package:USB_Share/Template/Model/templateAndCategoryMapModel.dart';
import 'package:USB_Share/Util/constant.dart';

class TemplateAndCategoryMapService {
  Future<List<TemplateAndCategoryMapModel>> getTemplateCategoryMapping() async {
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
        var res =
            await Constants.readFileData(await Constants.getDataFilePath('TM'));
        List<TemplateAndCategoryMapModel> templateMappingList =
            TemplateAndCategoryMapModel.fromCSV(res);
        return templateMappingList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveTemplateCategoryMapping(
      List<TemplateAndCategoryMapModel> templateMappingList,
      {FileMode m = FileMode.append}) async {
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
            (templateMappingList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('TM'), "TM", data,
            m: m);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }
}
