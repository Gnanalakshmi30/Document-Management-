class ImageLogModel {
  String? imageName;
  String? syncedDate;

  ImageLogModel({this.imageName, this.syncedDate});

  ImageLogModel.fromJson(Map<String, dynamic> json) {
    imageName = json['imageName'];
    syncedDate = json['syncedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imageName'] = imageName;
    data['syncedDate'] = syncedDate;
    return data;
  }

  static List<ImageLogModel> fromCSV(List<List<dynamic>>? data) {
    List<ImageLogModel> imageList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          if (e[0] != null && e[0] != '') {
            imageList.add(ImageLogModel(
              imageName: e[0],
              syncedDate: e[1],
            ));
          }
        }
      }
    } catch (e) {
      rethrow;
    }
    return imageList;
  }

  List<dynamic> toList() => [imageName, syncedDate];
}
