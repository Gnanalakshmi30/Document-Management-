class VersionModel {
  double? version;

  VersionModel({
    this.version,
  });

  VersionModel.fromJson(Map<String, dynamic> json) {
    version = json['version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version'] = version;
    return data;
  }

  static List<VersionModel> fromCSV(List<List<dynamic>>? data) {
    List<VersionModel> versionList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[0] != null && e[0] != '') {
            versionList.add(VersionModel(
              version: e[0],
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return versionList;
  }

  List<dynamic> toList() => [version];
}
