import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:USB_Share/AddImage/Model/addImage_model.dart';
import 'package:USB_Share/Util/DioApiBaseHelper.dart';
import 'package:USB_Share/Util/constant.dart';

class ImageService {
  Future<List<ImageLogModel>> getImageLog() async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();

        var response = await dio.get('ImageLog/GetImageLog');
        if (response.statusCode == 200 && response.data != null) {
          final result = List<Map<String, dynamic>>.from(response.data);
          var dataLst = result.map((x) => ImageLogModel.fromJson(x)).toList();
          return Future.value(dataLst);
        }
        return Future.value([]);
      } else {
        var res =
            await Constants.readFileData(await Constants.getDataFilePath('I'));
        List<ImageLogModel> imageLogList = ImageLogModel.fromCSV(res);
        return imageLogList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveImagLog(List<ImageLogModel> imageLogList) async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();
        var data = imageLogList.map((e) => e.toJson()).toList();
        var response = await dio.post('ImageLog/SaveImagLog', data: data);
        if (response.statusCode == 200 && response.data != null) {
          return Future.value(response.data);
        }
        return Future.value(false);
      } else {
        List<List<dynamic>> data =
            (imageLogList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
          await Constants.getDataFilePath('I'),
          "I",
          data,
        );
        return res;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<int>> getImageLogFile() async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();

        var response = await dio.get('ImageLog/GetImageLogFile');
        if (response.statusCode == 200 && response.data != null) {
          Uint8List res = decodeBase64String(response.data);
          return Future.value(res);
        }
        return Future.value([]);
      } else {
        String fPath = await Constants.getDataFilePath('I');
        File file = File(fPath);
        Uint8List bytes = file.readAsBytesSync();
        return bytes;
      }
    } catch (e) {
      return [];
    }
  }

  Uint8List decodeBase64String(String base64String) {
    List<int> bytes = base64.decode(base64String);
    return Uint8List.fromList(bytes);
  }
}
