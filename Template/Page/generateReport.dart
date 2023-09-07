import 'dart:io';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Model/templateAndCategoryMapModel.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/Template/Service/templateAndCategoryMapService.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class GenerateReport extends StatefulWidget {
  const GenerateReport({super.key});

  @override
  State<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends State<GenerateReport> {
  List<FileSystemEntity> entities = [];
  List<FileSystemEntity> templateEntities = [];
  List<String> projectList = [];
  List<String> templateList = [];
  String? selectedProject;
  String? selectedTemplate;
  String? selectedTemplateName;
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  final projectAndTemplateMapService = ProjectAndTemplateMapService();
  List<ProjectAndTemplateMapModel> mappedProjectTempData = [];
  int selectedIndex = -1;
  List<TemplateAndCategoryMapModel> reportCategoryData = [];
  final templateAndCategoryMapService = TemplateAndCategoryMapService();
  final configurationService = ConfigurationService();
  Directory? saveDirectory;
  String dirFolderName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getProjectList();
    getTemplateList();
    getSaveDir();
  }

  clearDropdown() {
    setState(() {
      selectedTemplate = null;
      selectedProject = null;
    });
  }

  getProjectList() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory('${directory.path}$dirFolderName');
    if (!await dir.exists()) {
      final storagePermissionStatus = await Permission.storage.request();
      if (storagePermissionStatus.isGranted) {
        await dir.create(recursive: true);
      }
    }
    try {
      entities = await dir.list().toList();
      var data = entities.reversed.toList();
      if (mounted) {
        setState(() {
          entities = data;
        });
      }
      List<String> tempProjList = [];

      entities.forEach((element) {
        String projectNo;
        var path = Platform.isWindows
            ? element.path.split('\\').last
            : element.path.split('/').last;
        if (!path.toLowerCase().contains('template') &&
            !path.toLowerCase().contains('projectfolderbackup')) {
          if (path.contains('_')) {
            projectNo = path.split('_')[1];
          } else {
            projectNo = path;
          }
          if (!tempProjList.contains(path)) {
            tempProjList.add(path);
          }
        }
      });
      tempProjList.sort(((a, b) => b.compareTo(a)));
      setState(() {
        projectList = tempProjList;
      });
      getProjTemplateMappedData();
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  getTemplateList() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory('${directory.path}$dirFolderName/Template');
    if (!await dir.exists()) {
      final storagePermissionStatus = await Permission.storage.request();
      if (storagePermissionStatus.isGranted) {
        await dir.create(recursive: true);
      }
    }

    try {
      templateEntities = await dir.list().toList();
      var data = templateEntities.reversed.toList();
      if (mounted) {
        setState(() {
          templateEntities = data;
        });
      }
      templateEntities.removeWhere((element) => !element.path
          .split('\\')
          .last
          .split('.')
          .last
          .toLowerCase()
          .contains('docx'));

      templateEntities.forEach((element) {
        var path = Platform.isWindows
            ? element.path.split('\\').last.split('.').first
            : element.path.split('/').last.split('.').first;

        templateList.add(path);
      });
    } on Exception catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
    }
  }

  getProjTemplateMappedData() async {
    List<ProjectAndTemplateMapModel> data = [];
    List<ProjectAndTemplateMapModel> res =
        await projectAndTemplateMapService.getProjectAndTemplateMapping();
    if (res.isNotEmpty) {
      res.forEach((e) {
        if (projectList.contains(e.project.toString())) {
          data.add(e);
        }
      });
    }

    setState(() {
      mappedProjectTempData = data;
    });

    mappedProjectTempData.removeWhere((re) {
      return session.deletedProject.contains(re.project.toString());
    });
    mappedProjectTempData.sort((a, b) => b.id!.compareTo(a.id!));
  }

  getSaveDir() async {
    Directory directory = await FileMethods.getSaveDirectory();
    setState(() {
      saveDirectory = directory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return saveDirectory == null
        ? SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(child: CommonUi().showLoading()),
          )
        : Expanded(
            flex: 4,
            child: Container(
                height: MediaQuery.of(context).size.height,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
                        child: Text('Template mapping',
                            style: Sizing.getScreenWidth(context) > 1000 &&
                                    !Platform.isWindows
                                ? TextStyle(fontSize: 17, color: primaryColor)
                                : TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor)),
                      ),
                      Platform.isWindows ? dropDownAndButton() : SizedBox(),
                      projectAndTempList(),
                    ],
                  ),
                )));
  }

  dropDownAndButton() {
    bool isExist = false;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizing.width(15, 10)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                width: Sizing.width(100, 100),
                height: Sizing().height(10, 10.6),
                child: DropdownButton<String>(
                  focusColor: Colors.white,
                  hint: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'Select project',
                      style: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3)),
                    ),
                  ),
                  isExpanded: true,
                  iconSize: 25,
                  iconEnabledColor: Colors.grey[600],
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      selectedProject = value;
                    });
                  },
                  value: selectedProject,
                  items: projectList.map((String value) {
                    String projectNo;
                    if (value.contains('_')) {
                      projectNo = value.split('_')[1];
                    } else {
                      projectNo = value;
                    }

                    return DropdownMenuItem<String>(
                      value: value.toString(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(value,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: Sizing().height(2, 3))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizing.width(15, 5)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                width: Sizing.width(100, 100),
                height: Sizing().height(10, 10.6),
                child: DropdownButton<String>(
                  focusColor: Colors.white,
                  hint: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'Select template',
                      style: TextStyle(
                          color: Colors.grey, fontSize: Sizing().height(2, 3)),
                    ),
                  ),
                  isExpanded: true,
                  iconSize: 25,
                  iconEnabledColor: Colors.grey[600],
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      selectedTemplate = value;
                    });
                  },
                  value: selectedTemplate,
                  items: templateList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value.toString(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(value.toString(),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: Sizing().height(2, 3))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                try {
                  if (selectedProject != null &&
                      selectedProject != "" &&
                      selectedTemplate != null &&
                      selectedTemplate != "") {
                    List<ProjectAndTemplateMapModel> mappedTemplateList = [];
                    int id;

                    var res = await projectAndTemplateMapService
                        .getProjectAndTemplateMapping();
                    mappedTemplateList = res;
                    mappedTemplateList.sort((a, b) => b.id!.compareTo(a.id!));

                    //check proj already exists
                    if (selectedIndex == -1) {
                      mappedTemplateList.forEach((p) {
                        if (selectedProject == p.project.toString()) {
                          isExist = true;
                        }
                      });
                    }
                    //check proj already exists
                    if (isExist == false) {
                      CommonUi().showLoadingDialog(context);

                      //copy and save  keyword file
                      Directory? newDirectory2;
                      Directory directory2 =
                          await FileMethods.getSaveDirectory();
                      Directory? mainfolderDirectory;

                      newDirectory2 =
                          Directory('${directory2.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory2);
                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/Template');
                      await Constants.checkExists(newDirectory2);
                      File selectedKeywordFile = File(
                          '${newDirectory2.path}/$selectedTemplate keyword.txt');

                      File tableContentFile = File(
                          '${newDirectory2.path}/$selectedTemplate tableContent.txt');

                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/$selectedProject');
                      await Constants.checkExists(newDirectory2);

                      mainfolderDirectory = Directory(
                          '${directory2.path}/$dirFolderName/$selectedProject');

                      Map<String, String> imageFiles =
                          await projectAndTemplateMapService
                              .getImageFiles(mainfolderDirectory);

                      List<String> imageNameList = [];
                      imageFiles.forEach((key, value) {
                        // print('File Name: $key');
                        // print('File Path: $value');
                        imageNameList.add(key);
                      });
                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/$selectedProject/GeneratedReport');

                      await Constants.checkExists(newDirectory2);

                      String tempprojTempFile =
                          '${newDirectory2.path}/$selectedTemplate temp.docx';
                      if (await File(tempprojTempFile).exists()) {
                        await File(tempprojTempFile).delete();
                      } else {
                        await File(tempprojTempFile).create();
                      }

                      String projTempFile =
                          '${newDirectory2.path}/$selectedTemplate.docx';

                      if (await File(projTempFile).exists()) {
                        await File(projTempFile).delete();
                      } else {
                        await File(projTempFile).create();
                      }
                      Directory tempnewDirectory =
                          Directory('${directory2.path}/$dirFolderName');
                      await Constants.checkExists(tempnewDirectory);

                      tempnewDirectory = Directory(
                          '${directory2.path}/$dirFolderName/Template');
                      await Constants.checkExists(tempnewDirectory);
                      File templateFile = File(
                          '${tempnewDirectory.path}/$selectedTemplate.docx');

                      templateFile.copySync(projTempFile);
                      templateFile.copySync(tempprojTempFile);

                      File paseteKeywordFile = File(
                          '${newDirectory2.path}/$selectedTemplate keyword.txt');
                      paseteKeywordFile.createSync();
                      File pasteTableContentFile = File(
                          '${newDirectory2.path}/$selectedTemplate tableContent.txt');
                      //copy and save  keyword file

                      //copy and save  tableContent file
                      tableContentFile.copySync(pasteTableContentFile.path);
                      //copy and save  tableContent file

                      String selectedTemplateKeyword =
                          await selectedKeywordFile.readAsString();
                      List<String> keywordList =
                          selectedTemplateKeyword.split(',');

                      if (mappedTemplateList.isNotEmpty) {
                        id = mappedTemplateList.length;
                      } else {
                        id = 0;
                      }

                      //save project and template mapped file

                      if (selectedIndex == -1) {
                        mappedTemplateList.add(ProjectAndTemplateMapModel(
                            id: id + 1,
                            project: selectedProject ?? "0",
                            templateName: selectedTemplate,
                            createdDate: DateTime.now().toString()));
                      } else {
                        mappedTemplateList[selectedIndex].project =
                            selectedProject ?? "";

                        mappedTemplateList[selectedIndex].templateName =
                            selectedTemplate ?? "";
                      }

                      projectAndTemplateMapService
                          .saveProjectAndTemplateMapping(mappedTemplateList);

                      await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return GetTemplateDataForm(
                                dirPath: paseteKeywordFile.path,
                                keywordList: keywordList,
                                clearDropdown: clearDropdown,
                                imageList: imageFiles,
                                imageNameList: imageNameList
                                // imageList: {},
                                // imageNameList: [],
                                );
                          });

                      getProjTemplateMappedData();
                      Navigator.pop(context);
                    } else {
                      CherryToast.warning(
                              title: Text(
                                "Project already exists",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  } else {
                    CherryToast.error(
                            title: Text(
                              "Please select the options",
                              style: TextStyle(fontSize: Sizing().height(5, 3)),
                            ),
                            autoDismiss: true)
                        .show(context);
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
                margin: EdgeInsets.only(left: Sizing.width(5, 7)),
                padding: EdgeInsets.symmetric(
                    horizontal: Sizing.width(15, 10),
                    vertical: Sizing().height(8, 2)),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(7)),
                child: Text(
                  'Prepare report',
                  style: TextStyle(
                      color: Colors.white, fontSize: Sizing().height(5, 3)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  projectAndTempList() {
    return Expanded(
      flex: 1,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: Sizing.width(5, 10), vertical: Sizing().height(3, 5)),
        padding: EdgeInsets.symmetric(
            horizontal: Sizing.width(5, 5), vertical: Sizing().height(5, 2)),
        decoration: BoxDecoration(
            color: Color(0xfff6f6f6), borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Table(
                columnWidths: {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: mappedTempTableData(),
              ),
              mappedProjectTempData.length == 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Sizing().height(5, 5)),
                          child: Text(
                            'No data',
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
    );
  }

  mappedTempTableData() {
    Directory? downloadDir;
    List<TableRow> mappedTempList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8.0,
          ),
          child: Text(
            "Project",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
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
          child: Text("Actions",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ]),
    ];

    if (mappedProjectTempData.length > 0) {
      for (int i = 0; i < mappedProjectTempData.length; i++) {
        String projectNo;
        if (mappedProjectTempData[i].project.toString().contains('_')) {
          projectNo = mappedProjectTempData[i].project.toString().split('_')[1];
        } else {
          projectNo = mappedProjectTempData[i].project.toString();
        }
        mappedTempList.add(TableRow(children: [
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
                child: Container(
                  width: 150,
                  child: Text(
                    mappedProjectTempData[i].project.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(mappedProjectTempData[i].templateName ?? "",
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Row(
            children: [
              Platform.isAndroid
                  ? SizedBox()
                  : IconButton(
                      tooltip: 'View template',
                      onPressed: () async {
                        try {
                          CommonUi().showLoadingDialog(context);
                          String pName =
                              mappedProjectTempData[i].project.toString();
                          String tempName =
                              mappedProjectTempData[i].templateName.toString();

                          //copy and save template file
                          Directory? newDirectory;
                          Directory directory =
                              await FileMethods.getSaveDirectory();

                          newDirectory =
                              Directory('${directory.path}/$dirFolderName');
                          await Constants.checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/$dirFolderName/$pName');
                          await Constants.checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport');
                          await Constants.checkExists(newDirectory);

                          String projTempFile =
                              '${newDirectory.path}/$tempName.docx';

                          if (await File(projTempFile).exists()) {
                            await File(projTempFile).delete();
                          }

                          File templateFile =
                              File('${newDirectory.path}/$tempName temp.docx');

                          templateFile.copySync(projTempFile);

                          //get keyword file path
                          Directory keywordFileDir = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport/$tempName keyword.txt');

                          Directory tableContentDir = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport/$tempName tableContent.txt');

                          final tableContentfile = File(tableContentDir.path);
                          final selectedTableContent =
                              await tableContentfile.readAsString();
                          //get keyword file path

                          // replace the text in projTemp file
                          Directory pythonFileDir =
                              await Constants.getDataDirectory();
                          String pythonFilePath = pythonFileDir.path;

                          var result = await Process.run('python', [
                            '$pythonFilePath/docxEditor.py',
                            projTempFile,
                            keywordFileDir.path
                          ]);
                          if (result.stderr.isNotEmpty) {
                            errorLog.add(ErrorLogModel(
                                errorDescription:
                                    'An error occurred in Python script: ${result.stderr}',
                                duration: DateTime.now().toString()));
                            errorLogService.saveErrorLog(errorLog);
                            print(
                                'An error occurred in Python script: ${result.stderr}');
                          }
                          // replace the text in projTemp file

                          //replace the table in downloaded file
                          // var result1 = await Process.run('python', [
                          //   '$pythonFilePath/replaceTable.py',
                          //   projTempFile,
                          //   selectedTableContent
                          // ]);
                          // if (result1.stderr.isNotEmpty) {
                          //   errorLog.add(ErrorLogModel(
                          //       errorDescription:
                          //           'An error occurred in Python script: ${result1.stderr}',
                          //       duration: DateTime.now().toString()));
                          //   errorLogService.saveErrorLog(errorLog);
                          //   print(
                          //       'An error occurred in Python script: ${result1.stderr}');
                          // }
                          // var result2 = await Process.run('python', [
                          //   '$pythonFilePath/replaceTable.py',
                          //   templateFile.path.toString(),
                          //   selectedTableContent
                          // ]);
                          // if (result2.stderr.isNotEmpty) {
                          //   errorLog.add(ErrorLogModel(
                          //       errorDescription:
                          //           'An error occurred in Python script: ${result1.stderr}',
                          //       duration: DateTime.now().toString()));
                          //   errorLogService.saveErrorLog(errorLog);
                          //   print(
                          //       'An error occurred in Python script: ${result1.stderr}');
                          // }
                          //replace the table in downloaded file

                          projTempFile = projTempFile.replaceAll('\\', '/');
                          projTempFile = projTempFile.replaceAll('//', '/');

                          if (await canLaunch("file://$projTempFile")) {
                            await launch(
                              "file://$projTempFile",
                            );
                          } else {
                            print("cannot launch url ]:");
                          }
                          Navigator.pop(context);
                        } on Exception catch (e) {
                          errorLog.add(ErrorLogModel(
                              errorDescription: e.toString(),
                              duration: DateTime.now().toString()));
                          errorLogService.saveErrorLog(errorLog);
                          Navigator.pop(context);
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
                  tooltip: 'Edit template',
                  onPressed: () async {
                    try {
                      CommonUi().showLoadingDialog(context);
                      Directory? mainfolderDirectory;
                      Directory? newDirectory2;
                      Directory directory2 =
                          await FileMethods.getSaveDirectory();
                      newDirectory2 =
                          Directory('${directory2.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory2);
                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/Template');
                      await Constants.checkExists(newDirectory2);
                      File templateFolderKeywordFile = File(
                          '${newDirectory2.path}/${mappedProjectTempData[i].templateName} keyword.txt');

                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[i].project}');
                      await Constants.checkExists(newDirectory2);

                      mainfolderDirectory = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[i].project}');

                      Map<String, String> imageFiles =
                          await projectAndTemplateMapService
                              .getImageFiles(mainfolderDirectory);

                      List<String> imageNameList = [];
                      imageFiles.forEach((key, value) {
                        // print('File Name: $key');
                        // print('File Path: $value');
                        imageNameList.add(key);
                      });
                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[i].project}/GeneratedReport');
                      await Constants.checkExists(newDirectory2);
                      File paseteKeywordFile = File(
                          '${newDirectory2.path}/${mappedProjectTempData[i].templateName} keyword.txt');
                      paseteKeywordFile.createSync();

                      String templateFolderKeyword =
                          await templateFolderKeywordFile.readAsString();
                      List<String> keywordList =
                          templateFolderKeyword.split(',');

                      await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return GetTemplateDataForm(
                                dirPath: paseteKeywordFile.path,
                                keywordList: keywordList,
                                clearDropdown: clearDropdown,
                                imageList: imageFiles,
                                imageNameList: imageNameList);
                          });

                      getProjTemplateMappedData();
                      Navigator.pop(context);
                    } on Exception catch (e) {
                      errorLog.add(ErrorLogModel(
                          errorDescription: e.toString(),
                          duration: DateTime.now().toString()));
                      errorLogService.saveErrorLog(errorLog);
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.edit,
                    color: Colors.grey,
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
                                  style: Platform.isWindows ? body3 : subtitle1,
                                ),
                                SizedBox(
                                  height: Sizing().height(8, 6),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: Sizing().height(1, 1),
                                        horizontal: Sizing.width(2, 3),
                                      ),
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
                                      padding: EdgeInsets.symmetric(
                                        vertical: Sizing().height(1, 1),
                                        horizontal: Sizing.width(2, 3),
                                      ),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                      child: TextButton(
                                          onPressed: () async {
                                            try {
                                              List<ProjectAndTemplateMapModel>
                                                  deletTemp = [];
                                              var temp = mappedProjectTempData
                                                  .where((d) =>
                                                      d.id !=
                                                      mappedProjectTempData[i]
                                                          .id);
                                              if (temp.isNotEmpty) {
                                                deletTemp = temp.toList();
                                              }

                                              bool res =
                                                  await projectAndTemplateMapService
                                                      .saveProjectAndTemplateMapping(
                                                          deletTemp);
                                              if (res) {
                                                getProjTemplateMappedData();
                                              }
                                              Directory newDirectory = Directory(
                                                  '${saveDirectory!.path}/$dirFolderName/${mappedProjectTempData[i].project}/GeneratedReport');
                                              if (await newDirectory.exists()) {
                                                await newDirectory.delete(
                                                    recursive: true);
                                              }

                                              Navigator.pop(context);
                                              CherryToast.success(
                                                      title: Text(
                                                        "Deleted successfully",
                                                        style: TextStyle(
                                                            fontSize: Sizing()
                                                                .height(5, 3)),
                                                      ),
                                                      autoDismiss: true)
                                                  .show(context);
                                            } on Exception catch (e) {
                                              errorLog.add(ErrorLogModel(
                                                  errorDescription:
                                                      e.toString(),
                                                  duration: DateTime.now()
                                                      .toString()));
                                              errorLogService
                                                  .saveErrorLog(errorLog);
                                              Navigator.pop(context);
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
              IconButton(
                  tooltip: 'Update table value',
                  onPressed: () async {
                    try {
                      Directory pythonFileDir =
                          await Constants.getDataDirectory();
                      String pythonFilePath = pythonFileDir.path;
                      CommonUi().showLoadingDialog(context);
                      String pName =
                          mappedProjectTempData[i].project.toString();
                      String tempName =
                          mappedProjectTempData[i].templateName.toString();
                      //select tableContentFile
                      Directory? newDirectory;

                      Directory directory =
                          await FileMethods.getSaveDirectory();
                      newDirectory =
                          Directory('${directory.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory);

                      newDirectory =
                          Directory('${directory.path}/$dirFolderName/$pName');
                      await Constants.checkExists(newDirectory);
                      newDirectory = Directory(
                          '${directory.path}/$dirFolderName/$pName/GeneratedReport');
                      await Constants.checkExists(newDirectory);

                      File tableContentFile = File(
                          '${newDirectory.path}/$tempName tableContent.txt');
                      File keyContentPath =
                          File('${newDirectory.path}/$tempName keyword.txt');

                      Directory? newDirectory2;
                      newDirectory2 =
                          Directory('${directory.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory2);
                      newDirectory2 = Directory(
                          '${directory.path}/$dirFolderName/Template');
                      await Constants.checkExists(newDirectory2);
                      //extract table content from word file

                      File templateFolderKeywordFile =
                          File('${newDirectory2.path}/$tempName keyword.txt');

                      String tableTempFile =
                          '${newDirectory.path}/$tempName temp.docx';
                      var result = await Process.run('python', [
                        '$pythonFilePath/extractTableData.py',
                        tableTempFile
                      ]);
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
                      await tableContentFile.writeAsString(tableContent,
                          mode: FileMode.write);

                      String templateFilePath =
                          '${newDirectory.path}/$tempName temp.docx';

                      templateFilePath = templateFilePath.replaceAll('\\', '/');
                      templateFilePath = templateFilePath.replaceAll('//', '/');

                      String actualtemplatePath =
                          '${newDirectory.path}/$tempName.docx';
                      actualtemplatePath =
                          actualtemplatePath.replaceAll('\\', '/');
                      actualtemplatePath =
                          actualtemplatePath.replaceAll('//', '/');
                      //select tableContentFile

                      //extract the htmlcontent from the file
                      String tableHtmlContent =
                          await tableContentFile.readAsString();
                      String templateFolderKeyword =
                          await templateFolderKeywordFile.readAsString();
                      List<String> keywordList =
                          templateFolderKeyword.split(',');
                      //extract the htmlcontent from the file
                      Navigator.pop(context);

                      Navigator.of(context)
                          .pushNamed(PageRouter.tableWebview, arguments: {
                        "htmlString": tableHtmlContent,
                        "tableContentFilePath": tableContentFile,
                        "templateFilePath": templateFilePath,
                        "actualtemplatePath": actualtemplatePath,
                        "keywordList": keywordList,
                        "keyContentPath": keyContentPath
                      });
                    } on Exception catch (e) {
                      errorLog.add(ErrorLogModel(
                          errorDescription: e.toString(),
                          duration: DateTime.now().toString()));
                      errorLogService.saveErrorLog(errorLog);
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.table_view_rounded,
                    size: Sizing.getScreenWidth(context) > 1000 &&
                            !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 4),
                  )),
              Platform.isAndroid
                  ? SizedBox()
                  : IconButton(
                      tooltip: 'Download template',
                      onPressed: () async {
                        try {
                          CommonUi().showLoadingDialog(context);
                          String pName =
                              mappedProjectTempData[i].project.toString();
                          String tempName =
                              mappedProjectTempData[i].templateName.toString();
                          //copy and save template file
                          Directory? newDirectory;
                          Directory directory =
                              await FileMethods.getSaveDirectory();
                          newDirectory =
                              Directory('${directory.path}/$dirFolderName');
                          await Constants.checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/$dirFolderName/$pName');
                          await Constants.checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport');
                          await Constants.checkExists(newDirectory);

                          File templateFile =
                              File('${newDirectory.path}/$tempName temp.docx');

                          //get keyword file path and table content file path
                          Directory keywordFileDir = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport/$tempName keyword.txt');

                          Directory tableContentDir = Directory(
                              '${directory.path}/$dirFolderName/$pName/GeneratedReport/$tempName tableContent.txt');

                          final tableContentfile = File(tableContentDir.path);
                          final selectedTableContent =
                              await tableContentfile.readAsString();
                          //get keyword file path and table content file path

                          if (Platform.isAndroid) {
                            String basePath = '/sdcard/Download';
                            downloadDir = Directory(basePath);
                          } else if (Platform.isWindows) {
                            downloadDir = await getDownloadsDirectory();
                          }
                          String filename = pName + '_' + tempName;

                          String downloadTemplateFilePath =
                              '${downloadDir!.path}/$filename.docx';
                          templateFile.copySync(downloadTemplateFilePath);
                          //copy and save template file

                          // replace the text in downloaded file
                          Directory pythonFileDir =
                              await Constants.getDataDirectory();
                          String pythonFilePath = pythonFileDir.path;

                          var result = await Process.run('python', [
                            '$pythonFilePath/docxEditor.py',
                            downloadTemplateFilePath,
                            keywordFileDir.path
                          ]);
                          if (result.stderr.isNotEmpty) {
                            errorLog.add(ErrorLogModel(
                                errorDescription:
                                    'An error occurred in Python script: ${result.stderr}',
                                duration: DateTime.now().toString()));
                            errorLogService.saveErrorLog(errorLog);
                            print(
                                'An error occurred in Python script: ${result.stderr}');
                          }
                          // replace the text in downloaded file

                          //replace the table in downloaded file
                          // var result1 = await Process.run('python', [
                          //   '$pythonFilePath/replaceTable.py',
                          //   downloadTemplateFilePath,
                          //   selectedTableContent
                          // ]);
                          // if (result1.stderr.isNotEmpty) {
                          //   errorLog.add(ErrorLogModel(
                          //       errorDescription:
                          //           'An error occurred in Python script: ${result1.stderr}',
                          //       duration: DateTime.now().toString()));
                          //   errorLogService.saveErrorLog(errorLog);
                          //   print(
                          //       'An error occurred in Python script: ${result1.stderr}');
                          // }
                          //replace the table in downloaded file

                          Navigator.pop(context);
                          CherryToast.success(
                                  title: Text(
                                    "Downloaded successfully",
                                    style: TextStyle(
                                        fontSize: Sizing().height(5, 3)),
                                  ),
                                  autoDismiss: true)
                              .show(context);

                          String openPath =
                              downloadDir!.path.replaceAll('/', '\\');

                          await Process.run('explorer.exe', [openPath]);
                        } on Exception catch (e) {
                          errorLog.add(ErrorLogModel(
                              errorDescription: e.toString(),
                              duration: DateTime.now().toString()));
                          errorLogService.saveErrorLog(errorLog);
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        Icons.download,
                        color: Colors.green,
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
    return mappedTempList;
  }
}

class GetTemplateDataForm extends StatefulWidget {
  final String dirPath;
  final List<String>? keywordList;
  final Function? clearDropdown;
  final Map<String, String> imageList;
  final List<String> imageNameList;

  const GetTemplateDataForm(
      {super.key,
      this.keywordList,
      required this.dirPath,
      required this.imageList,
      required this.clearDropdown,
      required this.imageNameList});

  @override
  State<GetTemplateDataForm> createState() => _GetTemplateDataFormState();
}

class _GetTemplateDataFormState extends State<GetTemplateDataForm> {
  Map<String, String> keyStore = {};

  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  List<String> keyWordList = [];
  Map<String, String> imageList = {};

  List<String> imageNameList = [];

  // List<String> imageList = [];

  @override
  void initState() {
    super.initState();

    if (widget.keywordList != null && widget.keywordList!.isNotEmpty) {
      File keyfile = File(widget.dirPath);
      List<String> values = [];
      String content = keyfile.readAsStringSync();
      if (content != '') {
        values = content.split(',');
      }

      if (values.isNotEmpty && values.length == widget.keywordList!.length) {
        for (String i in values) {
          var keyVal = i.split('|');
          keyStore[keyVal[0]] = keyVal[1];
          keyWordList.add(keyVal[0]);
        }
      } else {
        for (String i in widget.keywordList!) {
          if (content != '') {}
          keyStore[i] = '';
          keyWordList.add(i);
        }
      }
    }

    if (widget.imageList.isNotEmpty) {
      imageList = widget.imageList;
    }
    if (widget.imageNameList != null && widget.imageNameList.isNotEmpty) {
      imageNameList = widget.imageNameList;
    }
  }

  bool showValidation = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Template Data",
            style: TextStyle(
                fontSize: Sizing().height(2, 3.5), fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: Sizing.width(10, 20),
          ),
          showValidation
              ? Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.width(2, 5),
                      vertical: Sizing().height(4, 2)),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(
                    'Please fill all the mandatory fields',
                    style: TextStyle(
                        color: Colors.white, fontSize: Sizing().height(6, 3)),
                  ),
                )
              : SizedBox(),
          Tooltip(
            message: 'Close',
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.grey[350],
              child: IconButton(
                  onPressed: () {
                    widget.clearDropdown!();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: Sizing().height(15, 4),
                  )),
            ),
          )
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(
            bottom: Sizing().height(1, 1),
          ),
          padding: EdgeInsets.symmetric(
            vertical: Sizing().height(1, 1),
            horizontal: Sizing.width(2, 3),
          ),
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(2)),
          child: TextButton(
              onPressed: () async {
                List<String> keys = keyStore.keys.toList();
                List<String> values = keyStore.values.toList();
                List<String> keyValues = [];
                bool error = false;

                for (int i = 0; i < keys.length; i++) {
                  if (keys[i].contains('*') && values[i] == '') {
                    error = true;
                  }
                }

                if (error) {
                  setState(() {
                    showValidation = true;
                  });
                } else {
                  CommonUi().showLoadingDialog(context);
                  setState(() {
                    showValidation = false;
                  });

                  for (int i = 0; i < keys.length; i++) {
                    keyValues.add('${keys[i]}|${values[i]}');
                  }

                  File file = File(widget.dirPath);
                  file.writeAsStringSync(keyValues.join(','),
                      mode: FileMode.write);
                  widget.clearDropdown!();

                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Generate report',
                style: TextStyle(
                    fontSize: Sizing().height(8, 3), color: whiteColor),
              )),
        ),
      ],
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SizedBox(
                width: double.maxFinite,
                child: keyWordList.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: keyWordList.length,
                        itemBuilder: (context, index) {
                          return !keyWordList[index]
                                  .toLowerCase()
                                  .contains('result')
                              ? Padding(
                                  padding: EdgeInsets.only(
                                      right: Sizing.width(5, 10),
                                      top: Sizing().height(5, 5)),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              bottom: Sizing().height(3, 2)),
                                          child: Row(
                                            children: [
                                              Text(
                                                keyWordList[index].contains('*')
                                                    ? keyWordList[index]
                                                        .split('*')
                                                        .first
                                                    : keyWordList[index],
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize:
                                                        Sizing().height(10, 3),
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              keyWordList[index].contains('*')
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                          left: Sizing()
                                                              .height(2, 1)),
                                                      child: Icon(
                                                        Icons.info,
                                                        size: Sizing()
                                                            .height(5, 3.5),
                                                        color: Colors.red,
                                                      ),
                                                    )
                                                  : SizedBox()
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            bottom: Sizing().height(5, 5)),
                                        child: !keyWordList[index]
                                                    .toLowerCase()
                                                    .contains('image') &&
                                                !keyWordList[index]
                                                    .contains('result')
                                            ? TextFormField(
                                                initialValue: keyStore[
                                                        keyWordList[index]] ??
                                                    '',
                                                cursorColor: primaryColor,
                                                style: TextStyle(
                                                    fontSize:
                                                        Sizing().height(10, 3)),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide:
                                                        const BorderSide(
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  keyStore[keyWordList[index]] =
                                                      value;
                                                },
                                              )
                                            : Container(
                                                // width: Sizing.width(60, 150),
                                                decoration: BoxDecoration(
                                                    color: whiteColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    border: Border.all(
                                                      color: Colors.black26,
                                                    )),
                                                padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        Sizing().height(2, 2),
                                                    horizontal:
                                                        Sizing.width(2, 2)),
                                                // margin: EdgeInsets.symmetric(
                                                //     vertical: Sizing().height(1, 2),
                                                //     horizontal: Sizing.width(3, 5)),
                                                child: DropdownButton<String>(
                                                  isDense: true,
                                                  isExpanded: true,
                                                  hint: const Text(
                                                    'Select Image',
                                                  ),
                                                  iconSize: Platform.isAndroid
                                                      ? Sizing.getScreenWidth(
                                                                  context) >
                                                              1000
                                                          ? 30
                                                          : Sizing()
                                                              .height(20, 20)
                                                      : 25,
                                                  iconEnabledColor:
                                                      Colors.grey[600],
                                                  underline: const SizedBox(),
                                                  onChanged: (value) {
                                                    keyStore[keyWordList[
                                                        index]] = value!;

                                                    setState(() {
                                                      keyStore[keyWordList[
                                                          index]] = value;
                                                    });
                                                  },
                                                  value: keyStore[keyWordList[
                                                              index]] !=
                                                          ''
                                                      ? keyStore[
                                                          keyWordList[index]]
                                                      : null,
                                                  items: imageNameList
                                                      .map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: imageList[value]
                                                          .toString(),
                                                      child: Text(
                                                        value.toString(),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox();
                        })
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
