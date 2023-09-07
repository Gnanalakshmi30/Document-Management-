class FontFamilyModel {
  int? fontFamilyId;
  String? fontFamily;

  FontFamilyModel({this.fontFamilyId, this.fontFamily});

  FontFamilyModel.fromJson(Map<String, dynamic> json) {
    fontFamilyId = json['fontFamilyId'];
    fontFamily = json['fontFamily'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fontFamilyId'] = fontFamilyId;
    data['fontFamily'] = fontFamily;
    return data;
  }

  static List<FontFamilyModel> fromCSV(List<List<dynamic>>? data) {
    List<FontFamilyModel> fontFamilyList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          fontFamilyList.add(FontFamilyModel(
            fontFamilyId: e[0],
            fontFamily: e[1],
          ));
        }
      }
    } catch (e) {
      rethrow;
    }
    return fontFamilyList;
  }

  List<dynamic> toList() => [fontFamilyId, fontFamily];
}
