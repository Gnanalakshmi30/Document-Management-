class PasswordModel {
  String? password;
  String? duration;

  PasswordModel({
    this.password,
    this.duration,
  });

  PasswordModel.fromJson(Map<String, dynamic> json) {
    password = json['password'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['password'] = password ?? "";
    data['duration'] = duration ?? "";
    return data;
  }

  static List<PasswordModel> fromCSV(List<List<dynamic>>? data) {
    List<PasswordModel> passwordList = [];

    try {
      if (data != null && data.isNotEmpty) {
        data.removeAt(0);
      }
      if (data != null && data.isNotEmpty) {
        for (var e in data) {
          passwordList.add(
            PasswordModel(
              password: (e[0] ?? '').toString(),
              duration: (e[1] ?? '').toString(),
            ),
          );
        }
      }
    } catch (e) {
      rethrow;
    }
    return passwordList;
  }

  List<dynamic> toList() => [password, duration];
}
