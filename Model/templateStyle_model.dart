class TemplateStyleModel {
  int? fontSize;
  String? fontFamily;

  TemplateStyleModel({this.fontSize, this.fontFamily});

  TemplateStyleModel.fromJson(Map<String, dynamic> json) {
    fontSize = json['fontSize'];
    fontFamily = json['fontFamily'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['fontSize'] = fontSize;
    data['fontFamily'] = fontFamily;
    return data;
  }

  static List<TemplateStyleModel> fromCSV(List<List<dynamic>>? data) {
    List<TemplateStyleModel> tempStyleList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          tempStyleList.add(TemplateStyleModel(
            fontSize: e[0],
            fontFamily: e[1],
          ));
        }
      }
    } catch (e) {
      rethrow;
    }
    return tempStyleList;
  }

  List<dynamic> toList() => [fontSize, fontFamily];
}
