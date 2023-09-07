import 'package:USB_Share/Project/Model/projectModel.dart';

class Session {
  List<String> selectedFolders = [];
  bool isProjSelect = false;
  List<DirectoryInfo> newAddedProj = [];
  List<DirectoryInfo> newAddedSubFol = [];
  bool isWifi = false;
  int selectedWidth = 0;
  int selectedHeight = 0;
  String deletedSubFolder = "";
  List<String> deletedProject = [];
  List<String> editedProjAndroid = [];
  List<String> editedProjWindows = [];
  String editedSubfolder = "";
  bool isEdit = false;
  bool needToRenew = false;
  bool isLicenseExpired = false;
}

final session = Session();
