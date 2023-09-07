import 'dart:io';
import 'package:USB_Share/Configuration/Model/reportCategory_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Project/Model/projectModel.dart';
import 'package:USB_Share/Template/Model/templateAndCategoryMapModel.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/Template/Service/templateAndCategoryMapService.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  bool loading = true;
  List<FileSystemEntity> entities = [];
  List<DirectoryInfo> directoryInfo = [];
  List<DirectoryInfo> finaltemplateList = [];
  List<TemplateAndCategoryMapModel> reportAndTemplateMapList = [];
  final templateAndCategoryMapService = TemplateAndCategoryMapService();
  final configurationService = ConfigurationService();
  List<ReportCategoryModel> categoryList = [];
  final projTempService = ProjectAndTemplateMapService();
  String dirFolderName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getTemplate();
    getMappedTemplateAndCategory();
  }

  getMappedTemplateAndCategory() async {
    var res = await templateAndCategoryMapService.getTemplateCategoryMapping();
    var data = await configurationService.getReportCategory();
    setState(() {
      reportAndTemplateMapList = res;
      categoryList = data;
    });
  }

  getTemplate() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory('${directory.path}$dirFolderName/Template');
    if (!await dir.exists()) {
      final storagePermissionStatus = await Permission.storage.request();
      if (storagePermissionStatus.isGranted) {
        await dir.create(recursive: true);
      }
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }

    try {
      entities = await dir.list().toList();
      directoryInfo = [];
      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in entities) {
          var path = Platform.isWindows
              ? entity.path.split('\\').last
              : entity.path.split('/').last;

          final stat = entity.statSync();
          final modifiedDate = stat.modified.toString();
          directoryInfo.add(
              DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
        }
      }
      //Sort the directory by modified date
      directoryInfo.sort((a, b) => b.modifiedDate!.compareTo(a.modifiedDate!));

      //Remove zip file
      var res = directoryInfo
          .where((c) => !(c.path ?? "").split('/').last.contains(".zip"));

      // var data = entities.reversed.toList();
      if (mounted) {
        if (res.isNotEmpty) {
          finaltemplateList = res.toList();
          //Remove .txt file
          finaltemplateList.removeWhere((element) => (element.path ?? "")
              .split('\\')
              .last
              .split('.')
              .last
              .toLowerCase()
              .contains('txt'));
        }
        setState(() {
          loading = false;
        });
      }
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 4,
        child: Container(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [uploadTemp(), templateList()],
              ),
            )));
  }

  uploadTemp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () async {
            try {
              var picked = await FilePicker.platform.pickFiles();
              if (picked != null) {
                File file = File(picked.files.single.path!);
                String filePath = file.path;
                String fileName = file.path.split('\\').last;

                CommonUi().showLoadingDialog(context);
                Directory pythonFileDir = await Constants.getDataDirectory();
                String pythonFilePath = pythonFileDir.path;

                var result = await Process.run('python',
                    ['$pythonFilePath/extractContentFromWord.py', filePath]);
                if (result.stderr.isNotEmpty) {
                  errorLog.add(ErrorLogModel(
                      errorDescription:
                          'An error occurred in Python script: ${result.stderr}',
                      duration: DateTime.now().toString()));
                  errorLogService.saveErrorLog(errorLog);
                  print('An error occurred in Python script: ${result.stderr}');
                }

                String text = result.stdout;

                RegExp exp = RegExp(r"\#{(.*?)\}#");
                Iterable<Match> matches = exp.allMatches(text);
                List<String> placeholders = [];
                for (Match match in matches) {
                  String? placeholder = match.group(1);
                  if (!placeholders.contains(placeholder)) {
                    placeholders.add(placeholder ?? "");
                  }
                }
                if (placeholders.isNotEmpty) {
                  //save the selected file in template folder
                  Directory? newDirectory;
                  Directory directory = await FileMethods.getSaveDirectory();
                  newDirectory = Directory('${directory.path}/$dirFolderName');
                  await Constants.checkExists(newDirectory);
                  newDirectory =
                      Directory('${directory.path}/$dirFolderName/Template');
                  await Constants.checkExists(newDirectory);
                  File templateFile = File('${newDirectory.path}/$fileName');
                  file.copySync(templateFile.path);

                  String keyword = placeholders.join(',');

                  //create keyword text File
                  String keywordFileName = fileName.split('.').first;
                  final File keywordFile = File(
                      '${directory.path}/$dirFolderName/Template/$keywordFileName keyword.txt');
                  keywordFile.writeAsString(keyword, mode: FileMode.write);

                  //extract table content from word file
                  var result = await Process.run('python',
                      ['$pythonFilePath/extractTableData.py', filePath]);
                  if (result.stderr.isNotEmpty) {
                    errorLog.add(ErrorLogModel(
                        errorDescription:
                            'An error occurred in Python script: ${result.stderr}',
                        duration: DateTime.now().toString()));
                    errorLogService.saveErrorLog(errorLog);
                    print(
                        'An error occurred in Python script: ${result.stderr}');
                  }
                  String tableContent = result.stdout;
                  //extract table content from word file

                  //create table content text File
                  final File tableContentFile = File(
                      '${directory.path}/$dirFolderName/Template/$keywordFileName tableContent.txt');
                  tableContentFile.writeAsString(tableContent,
                      mode: FileMode.write);
                  //create table content text File

                  Navigator.pop(context);
                  getTemplate();
                } else {
                  Navigator.pop(context);
                  CherryToast.warning(
                          title: Text(
                            "Please select a valid document",
                            style: TextStyle(fontSize: Sizing().height(5, 3)),
                          ),
                          autoDismiss: true)
                      .show(context);
                }
              }
            } on Exception catch (e) {
              errorLog.add(ErrorLogModel(
                  errorDescription: e.toString(),
                  duration: DateTime.now().toString()));
              errorLogService.saveErrorLog(errorLog);
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Sizing.width(3, 4),
              vertical: Sizing().height(2, 2),
            ),
            margin: EdgeInsets.symmetric(
                horizontal: Sizing.width(2, 4),
                vertical: Sizing().height(5, 1.5)),
            decoration: BoxDecoration(
                color: primaryColor, borderRadius: BorderRadius.circular(7)),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: Sizing.width(1, 2)),
                  child: Text(
                    'Add template',
                    style: TextStyle(
                        color: Colors.white, fontSize: Sizing().height(5, 3)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(3, 3),
                    vertical: Sizing().height(2, 1),
                  ),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 107, 114, 169),
                      borderRadius: BorderRadius.circular(7)),
                  child: Icon(
                    Icons.post_add,
                    color: Colors.white,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  templateList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.only(
                left: Sizing.width(5, 10),
                right: Sizing.width(5, 10),
                top: Sizing().height(5, 10),
                bottom: Sizing().height(5, 5),
              ),
              child: Text('Template list(s)',
                  style: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? TextStyle(fontSize: 17, color: primaryColor)
                      : TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor))),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: Sizing.width(5, 10),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(5, 5),
                  vertical: Sizing().height(5, 2)),
              decoration: BoxDecoration(
                  color: Color(0xfff6f6f6),
                  borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: templateTableData(),
                    ),
                    finaltemplateList.length == 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: Sizing().height(5, 5)),
                                child: Text(
                                  'No template found',
                                  style: TextStyle(
                                      color: Colors.black38,
                                      fontSize: Sizing().height(5, 3.5)),
                                ),
                              )
                            ],
                          )
                        : SizedBox()
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  templateTableData() {
    List<TableRow> templatesList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Template name",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Last modified",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Action",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ]),
    ];

    if (finaltemplateList.length > 0) {
      for (int i = 0; i < finaltemplateList.length; i++) {
        templatesList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.article,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Text(
                    finaltemplateList[i]
                        .path!
                        .split('\\')
                        .last
                        .split('.')
                        .first,
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                Constants.modifiedDateFormat.format(
                    DateTime.parse(finaltemplateList[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Row(
            children: [
              IconButton(
                  tooltip: 'View template',
                  onPressed: () async {
                    try {
                      //  forceWebView: true,
                      //       enableJavaScript: true
                      if (await canLaunch(
                          "file://${finaltemplateList[i].path}")) {
                        await launch(
                          "file://${finaltemplateList[i].path}",
                        );
                      } else {
                        print("cannot launch url ]:");
                      }
                    } on Exception catch (e) {
                      errorLog.add(ErrorLogModel(
                          errorDescription: e.toString(),
                          duration: DateTime.now().toString()));
                      errorLogService.saveErrorLog(errorLog);
                    }
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              IconButton(
                  tooltip: 'Delete template',
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Are you sure, want to delete?',
                                  style: TextStyle(
                                      fontSize: Sizing().height(2, 3.5),
                                      fontWeight: FontWeight.w500),
                                ),
                                SizedBox(
                                  height: Sizing().height(8, 6),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                          color: greyColor,
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                      child: TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            'No',
                                            style: TextStyle(
                                                fontSize: Platform.isWindows
                                                    ? Sizing().height(2, 3)
                                                    : 12,
                                                color: whiteColor),
                                          )),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(
                                          left: Sizing.width(2, 2)),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                      child: TextButton(
                                          onPressed: () async {
                                            try {
                                              CommonUi()
                                                  .showLoadingDialog(context);
                                              deleteFolder(
                                                  finaltemplateList[i].path!);
                                            } on Exception catch (e) {
                                              errorLog.add(ErrorLogModel(
                                                  errorDescription:
                                                      e.toString(),
                                                  duration: DateTime.now()
                                                      .toString()));
                                              errorLogService
                                                  .saveErrorLog(errorLog);
                                            }
                                          },
                                          child: Text(
                                            'Yes',
                                            style: TextStyle(
                                                fontSize: Platform.isWindows
                                                    ? Sizing().height(2, 3)
                                                    : 12,
                                                color: whiteColor),
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
            ],
          )
        ]));
      }
    }
    return templatesList;
  }

  void deleteFolder(String folderPath) async {
    try {
      Directory(folderPath).deleteSync(recursive: true);
      String tempName = Platform.isWindows
          ? folderPath.split('.').first
          : folderPath.split('.').first;
      String keyword = '$tempName keyword.txt';
      String tableContent = '$tempName tableContent.txt';
      File keywordFile = File(keyword);
      if (await keywordFile.exists()) {
        await keywordFile.delete();
      }
      File tableContentFile = File(tableContent);
      if (await tableContentFile.exists()) {
        await tableContentFile.delete();
      }
      setState(() {
        getTemplate();
      });

      Navigator.pop(context);
      Navigator.pop(context);
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      Navigator.pop(context);
    }
  }
}
