import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/Util/DioApiBaseHelper.dart';
import 'package:USB_Share/Util/constant.dart';

class ErrorLogService {
  Future<bool> saveErrorLog(List<ErrorLogModel> errorLogList) async {
    try {
      if (Constants.isAPI) {
        DioApiBaseHelper helper = DioApiBaseHelper();
        var dio = await helper.getApiClient();
        var data = errorLogList.map((e) => e.toJson()).toList();
        var response = await dio.post('ImageLog/SaveErrorLog', data: data);
        if (response.statusCode == 200 && response.data != null) {
          return Future.value(response.data);
        }
        return Future.value(false);
      } else {
        List<List<dynamic>> data =
            (errorLogList).map((e) => e.toList()).toList();
        var res = await Constants.writeFileData(
          await Constants.getDataFilePath('E'),
          "E",
          data,
        );
        return res;
      }
    } catch (e) {
      return false;
    }
  }
}
