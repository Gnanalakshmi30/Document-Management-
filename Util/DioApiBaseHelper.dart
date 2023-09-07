import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:USB_Share/Util/common_ui.dart';

class DioApiBaseHelper extends ChangeNotifier {
  DioApiBaseHelper() : super();
  Future<Dio> getApiClient() async {
    var _dio = new Dio();
    _dio.interceptors.clear();
    _dio.options.baseUrl = CommonUi().baseURL;
    _dio.options.connectTimeout = 60000; //5s
    _dio.options.receiveTimeout = 13000;
    return _dio;
  }
}
