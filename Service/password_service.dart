import 'dart:io';

import 'package:USB_Share/Configuration/Model/password_model.dart';
import 'package:USB_Share/Util/DioApiBaseHelper.dart';
import 'package:USB_Share/Util/constant.dart';

class PasswordService {
  Future<List<PasswordModel>> getConfiguration() async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();

        var response = await dio.get('Configuration/GetConfiguration');
        if (response.statusCode == 200 && response.data != null) {
          final result = List<Map<String, dynamic>>.from(response.data);
          var dataLst = result.map((x) => PasswordModel.fromJson(x)).toList();
          return dataLst;
        }
        return [];
      } else {
        var res =
            await Constants.readFileData(await Constants.getDataFilePath('PS'));
        List<PasswordModel> passwordList = PasswordModel.fromCSV(res);
        return passwordList;
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> savePassword(List<PasswordModel> passData) async {
    try {
      List<List<dynamic>> data = (passData).map((e) => e.toList()).toList();
      var res = await Constants.writeFileData(
          await Constants.getDataFilePath('PS'), "PS", data,
          m: FileMode.write);
      return res;
    } catch (e) {
      return Future.value(false);
    }
  }
}
