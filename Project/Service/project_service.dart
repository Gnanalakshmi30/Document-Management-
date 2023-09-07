// Future<List<DocumentModel>> getMyDocumentByMobile() async {
//   try {
//     DioApiBaseHelper helper = DioApiBaseHelper();
//     var dio = await helper.getApiClient();

//     var response = await dio.get(
//         'Images/GetMyDocumentByMobile?MobileNumber=${session.mOBILEnumber}&EventID=${session.elcSelectedEvent}');
//     if (response.statusCode == 200 && response.data != null) {
//       final result = List<Map<String, dynamic>>.from(response.data);
//       var dataLst = result.map((x) => DocumentModel.fromJson(x)).toList();
//       var jsonData = jsonEncode(dataLst);
//       print(jsonData);

//       return Future.value(dataLst);
//     } else if (response.statusCode == 500) {
//       return Future.value([]);
//     }

//     return Future.value([]);
//   } catch (e) {
//     return [];
//   }
// }
