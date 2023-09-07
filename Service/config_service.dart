import 'dart:convert';
import 'dart:io';

import 'package:USB_Share/Configuration/Model/config_model.dart';
import 'package:USB_Share/Configuration/Model/fontFamily_model.dart';
import 'package:USB_Share/Configuration/Model/reportCategory_model.dart';
import 'package:USB_Share/Configuration/Model/saveCreatedDate_model.dart';
import 'package:USB_Share/Configuration/Model/templateStyle_model.dart';
import 'package:USB_Share/Util/DioApiBaseHelper.dart';
import 'package:USB_Share/Util/constant.dart';

class ConfigurationService {
  Future<List<ConfigurationModel>> getConfiguration() async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();

        var response = await dio.get('Configuration/GetConfiguration');
        if (response.statusCode == 200 && response.data != null) {
          final result = List<Map<String, dynamic>>.from(response.data);
          var dataLst =
              result.map((x) => ConfigurationModel.fromJson(x)).toList();
          return dataLst;
        }
        return [];
      } else {
        var res =
            await Constants.readFileData(await Constants.getDataFilePath('C'));
        List<ConfigurationModel> configList = ConfigurationModel.fromCSV(res);
        return configList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveConfig(List<ConfigurationModel> configlist) async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();
        var data = configlist.map((e) => e.toJson()).toList();
        var response =
            await dio.post('Configuration/SaveConfiguration', data: data);
        if (response.statusCode == 200 && response.data != null) {
          return Future.value(response.data);
        }
        return Future.value(false);
      } else {
        List<List<dynamic>> data = (configlist).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('C'), "C", data,
            m: FileMode.write);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<List<ReportCategoryModel>> getReportCategory() async {
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
            await Constants.readFileData(await Constants.getDataFilePath('R'));
        List<ReportCategoryModel> categoryList =
            ReportCategoryModel.fromCSV(res);
        return categoryList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveReportCategory(
      List<ReportCategoryModel> categoryList) async {
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
            (categoryList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('R'), "R", data,
            m: FileMode.write);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<List<TemplateStyleModel>> getTemplateStyleData() async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();

        // var response = await dio.get('Configuration/GetConfiguration');
        // if (response.statusCode == 200 && response.data != null) {
        //   final result = List<Map<String, dynamic>>.from(response.data);
        //   var dataLst =
        //       result.map((x) => ConfigurationModel.fromJson(x)).toList();
        //   return dataLst;
        // }
        return [];
      } else {
        var res =
            await Constants.readFileData(await Constants.getDataFilePath('TS'));
        List<TemplateStyleModel> tempStyleList =
            TemplateStyleModel.fromCSV(res);
        return tempStyleList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveTemplateStyle(List<TemplateStyleModel> tempStyleList) async {
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
            (tempStyleList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('TS'), "TS", data,
            m: FileMode.write);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<List<FontFamilyModel>> getFontFamily() async {
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
            await Constants.readFileData(await Constants.getDataFilePath('FF'));
        List<FontFamilyModel> fontFamilyList = FontFamilyModel.fromCSV(res);
        return fontFamilyList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveFontFamily(List<FontFamilyModel> fontFamilyList) async {
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
            (fontFamilyList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
            await Constants.getDataFilePath('FF'), "FF", data,
            m: FileMode.write);
        return res;
      }
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<bool> saveCreatedDAte(
      List<SaveCreatedDateModel> saveCreatedDateList) async {
    try {
      if (Constants.isAPI) {
        // DioApiBaseHelper helper = DioApiBaseHelper();
        // var dio = await helper.getApiClient();
        // var data = saveCreatedDateList.map((e) => e.toJson()).toList();
        // var response = await dio.post('ImageLog/SaveErrorLog', data: data);
        // if (response.statusCode == 200 && response.data != null) {
        //   return Future.value(response.data);
        // }
        return Future.value(false);
      } else {
        List<List<dynamic>> data =
            (saveCreatedDateList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
          await Constants.getDataFilePath('SCD'),
          "SCD",
          data,
        );
        return res;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<SaveCreatedDateModel>> getCreatedDAte() async {
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
            await Constants.getDataFilePath('SCD'));
        List<SaveCreatedDateModel> createdDateList =
            SaveCreatedDateModel.fromCSV(res);
        return createdDateList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveCreatedDAteAndroid(
      List<SaveCreatedDateModel> saveCreatedDateList) async {
    try {
      if (Constants.isAPI) {
        // DioApiBaseHelper helper = DioApiBaseHelper();
        // var dio = await helper.getApiClient();
        // var data = saveCreatedDateList.map((e) => e.toJson()).toList();
        // var response = await dio.post('ImageLog/SaveErrorLog', data: data);
        // if (response.statusCode == 200 && response.data != null) {
        //   return Future.value(response.data);
        // }
        return Future.value(false);
      } else {
        List<List<dynamic>> data =
            (saveCreatedDateList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
          await Constants.getDataFilePath('SCDA'),
          "SCDA",
          data,
        );
        return res;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<SaveCreatedDateModel>> getCreatedDAteAndroid() async {
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
            await Constants.getDataFilePath('SCDA'));
        List<SaveCreatedDateModel> createdDateList =
            SaveCreatedDateModel.fromCSV(res);
        return createdDateList;
      }
    } catch (e) {
      return [];
    }
  }
}
