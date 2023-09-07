// ignore_for_file: unused_import

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

class AndroidGenerateReport extends StatefulWidget {
  const AndroidGenerateReport({super.key});

  @override
  State<AndroidGenerateReport> createState() => _AndroidGenerateReportState();
}

class _AndroidGenerateReportState extends State<AndroidGenerateReport> {
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
        var path = Platform.isWindows
            ? element.path.split('\\').last
            : element.path.split('/').last;
        if (!path.toLowerCase().contains('template') &&
            !path.toLowerCase().contains('projectfolderbackup')) {
          tempProjList.add(path);
        }
      });
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
  }

  getSaveDir() async {
    Directory directory = await FileMethods.getSaveDirectory();
    setState(() {
      saveDirectory = directory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: appbar(),
            body: WillPopScope(
              onWillPop: () async => false,
              child: saveDirectory == null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Center(child: CommonUi().showLoading()),
                    )
                  : ListView(
                      children: [
                        Sizing.spacingHeight,
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Sizing().height(4, 5),
                              horizontal: Sizing.width(7, 5)),
                          child: Text(
                            'Template Mapping',
                            style: Platform.isWindows ? body2 : subtitle1,
                          ),
                        ),
                        Sizing.spacingHeight,
                        mappedListCardView(),
                      ],
                    ),
            )));
  }

  appbar() {
    return AppBar(
      backgroundColor: primaryColor,
      title: const Text(
        'Prepare Report',
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          size: Platform.isAndroid
              ? Sizing.getScreenWidth(context) > 1000
                  ? 30
                  : Sizing().height(20, 20)
              : 30,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(
            PageRouter.androidDashboardPage,
          );
        },
      ),
      actions: [],
    );
  }

  dropDownAndButton() {
    bool isExist = false;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: Sizing.width(60, 150),
              decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.black26,
                  )),
              padding: EdgeInsets.symmetric(
                  vertical: Sizing().height(2, 2),
                  horizontal: Sizing.width(2, 2)),
              margin: EdgeInsets.symmetric(
                  vertical: Sizing().height(1, 2),
                  horizontal: Platform.isWindows
                      ? Sizing.width(3, 5)
                      : Sizing.width(7, 8)),
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                hint: const Text(
                  'Select project',
                ),
                iconSize: Platform.isAndroid
                    ? Sizing.getScreenWidth(context) > 1000
                        ? 30
                        : Sizing().height(20, 20)
                    : 25,
                iconEnabledColor: Colors.grey[600],
                underline: const SizedBox(),
                onChanged: (value) {
                  setState(() {
                    selectedProject = value;
                  });
                },
                value: selectedProject,
                items: projectList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value.toString(),
                    child: Text(
                      value.toString(),
                    ),
                  );
                }).toList(),
              ),
            ),
            Container(
              width: Sizing.width(60, 150),
              decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.black26,
                  )),
              padding: EdgeInsets.symmetric(
                  vertical: Sizing().height(2, 2),
                  horizontal: Sizing.width(2, 2)),
              margin: EdgeInsets.symmetric(
                  vertical: Sizing().height(1, 2),
                  horizontal: Sizing.width(3, 5)),
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                hint: const Text(
                  'Select template',
                ),
                iconSize: Platform.isAndroid
                    ? Sizing.getScreenWidth(context) > 1000
                        ? 30
                        : Sizing().height(20, 20)
                    : 25,
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
                    child: Text(
                      value.toString(),
                    ),
                  );
                }).toList(),
              ),
            ),
            Platform.isWindows
                ? InkWell(
                    onTap: () async {
                      try {
                        if (selectedProject != null &&
                            selectedProject != "" &&
                            selectedTemplate != null &&
                            selectedTemplate != "") {
                          List<ProjectAndTemplateMapModel> mappedTemplateList =
                              [];
                          int id;

                          var res = await projectAndTemplateMapService
                              .getProjectAndTemplateMapping();
                          mappedTemplateList = res;
                          mappedTemplateList
                              .sort((a, b) => b.id!.compareTo(a.id!));

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
                            //Copy template
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
                            tableContentFile
                                .copySync(pasteTableContentFile.path);
                            //copy and save  tableContent file

                            String selectedTemplateKeyword =
                                await selectedKeywordFile.readAsString();
                            List<String> keywordList =
                                selectedTemplateKeyword.split(',');

                            if (mappedTemplateList.isNotEmpty) {
                              id = mappedTemplateList.last.id ?? 0;
                            } else {
                              id = 0;
                            }

                            //save project and template mapped file

                            if (selectedIndex == -1) {
                              mappedTemplateList.add(ProjectAndTemplateMapModel(
                                  id: id + 1,
                                  project: selectedProject ?? "",
                                  templateName: selectedTemplate));
                            } else {
                              mappedTemplateList[selectedIndex].project =
                                  selectedProject ?? "";

                              mappedTemplateList[selectedIndex].templateName =
                                  selectedTemplate ?? "";
                            }

                            projectAndTemplateMapService
                                .saveProjectAndTemplateMapping(
                                    mappedTemplateList);

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
                          } else {
                            CherryToast.warning(
                                    title: Text(
                                      "Project already exists",
                                      style: TextStyle(
                                          fontSize: Sizing().height(9, 3)),
                                    ),
                                    autoDismiss: true)
                                .show(context);
                          }
                        } else {
                          CherryToast.error(
                                  title: Text(
                                    "Please select the options",
                                    style: TextStyle(
                                        fontSize: Sizing().height(9, 3)),
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
                      margin: EdgeInsets.only(left: Platform.isWindows ? 2 : 0),
                      padding: EdgeInsets.symmetric(
                          horizontal: Sizing.width(5, 8),
                          vertical: Sizing().height(8, 2)),
                      decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: Platform.isWindows
                              ? BorderRadius.circular(2)
                              : BorderRadius.circular(3)),
                      child: Text(
                        'Prepare report',
                        style: TextStyle(
                            fontSize:
                                Platform.isWindows ? Sizing().height(2, 3) : 12,
                            color: whiteColor),
                      ),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
        Platform.isAndroid
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () async {
                      try {
                        if (selectedProject != null &&
                            selectedProject != "" &&
                            selectedTemplate != null &&
                            selectedTemplate != "") {
                          List<ProjectAndTemplateMapModel> mappedTemplateList =
                              [];
                          int id;

                          var res = await projectAndTemplateMapService
                              .getProjectAndTemplateMapping();
                          mappedTemplateList = res;
                          mappedTemplateList
                              .sort((a, b) => b.id!.compareTo(a.id!));

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
                            Directory? mainfolderDirectory;
                            Directory directory2 =
                                await FileMethods.getSaveDirectory();
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

                            newDirectory2 = Directory(
                                '${directory2.path}/$dirFolderName/$selectedProject/GeneratedReport');
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

                            //Copy template
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

                            File paseteKeywordFile = File(
                                '${newDirectory2.path}/$selectedTemplate keyword.txt');
                            paseteKeywordFile.createSync();
                            File pasteTableContentFile = File(
                                '${newDirectory2.path}/$selectedTemplate tableContent.txt');
                            //copy and save  keyword file

                            //copy and save  tableContent file
                            tableContentFile
                                .copySync(pasteTableContentFile.path);
                            //copy and save  tableContent file

                            String selectedTemplateKeyword =
                                await selectedKeywordFile.readAsString();
                            List<String> keywordList =
                                selectedTemplateKeyword.split(',');

                            if (mappedTemplateList.isNotEmpty) {
                              id = mappedTemplateList.last.id ?? 0;
                            } else {
                              id = 0;
                            }

                            //save project and template mapped file

                            if (selectedIndex == -1) {
                              mappedTemplateList.add(ProjectAndTemplateMapModel(
                                  id: id + 1,
                                  project: selectedProject ?? "",
                                  templateName: selectedTemplate));
                            } else {
                              mappedTemplateList[selectedIndex].project =
                                  selectedProject ?? "";

                              mappedTemplateList[selectedIndex].templateName =
                                  selectedTemplate ?? "";
                            }

                            projectAndTemplateMapService
                                .saveProjectAndTemplateMapping(
                                    mappedTemplateList);

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
                          } else {
                            CherryToast.error(
                                    title: Text(
                                      "Project already exists",
                                      style: TextStyle(
                                          fontSize: Sizing().height(9, 3)),
                                    ),
                                    autoDismiss: true)
                                .show(context);
                          }
                        } else {
                          CherryToast.error(
                                  title: Text(
                                    "Please select the options",
                                    style: TextStyle(
                                        fontSize: Sizing().height(9, 3)),
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
                      margin: EdgeInsets.only(
                          top: Sizing().height(5, 5),
                          right: Sizing.width(7, 10)),
                      padding: EdgeInsets.symmetric(
                          horizontal: Sizing.width(8, 9),
                          vertical: Sizing().height(8, 2)),
                      decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(3)),
                      child: const Text(
                        'Prepare report',
                        style: TextStyle(fontSize: 12, color: whiteColor),
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox(),
        SizedBox(
          height: Sizing().height(3, 5),
        ),
        const Divider()
      ],
    );
  }

  mappedListCardView() {
    Widget? w;
    Directory? downloadDir;
    if (mappedProjectTempData.isNotEmpty) {
      mappedProjectTempData.removeWhere((re) {
        return session.deletedProject.contains(re.project.toString());
      });
      mappedProjectTempData.sort((a, b) => b.id!.compareTo(a.id!));

      w = ListView.builder(
          shrinkWrap: true,
          itemCount: mappedProjectTempData.length,
          itemBuilder: (context, index) {
            String projectNo;
            if (mappedProjectTempData[index].project.toString().contains('_')) {
              projectNo =
                  mappedProjectTempData[index].project.toString().split('_')[1];
            } else {
              projectNo = mappedProjectTempData[index].project.toString();
            }
            return Card(
                child: ListTile(
              leading: Icon(
                Icons.article,
                color: Colors.yellow[600],
                size: Sizing().height(30, 7),
              ),
              onTap: Platform.isWindows
                  ? () async {
                      CommonUi().showLoadingDialog(context);
                      String pName =
                          mappedProjectTempData[index].project.toString();
                      String tempName =
                          mappedProjectTempData[index].templateName.toString();

                      //copy and save template file
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
                      String projTempFile =
                          '${newDirectory.path}/$tempName.docx';

                      if (await File(projTempFile).exists()) {
                        await File(projTempFile).delete();
                      }
                      newDirectory =
                          Directory('${directory.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory);

                      newDirectory = Directory(
                          '${directory.path}/$dirFolderName/Template');
                      await Constants.checkExists(newDirectory);
                      File templateFile =
                          File('${newDirectory.path}/$tempName.docx');

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
                    }
                  : () {},
              title: Text(mappedProjectTempData[index].project ?? ""),
              subtitle: Text(mappedProjectTempData[index].templateName ?? ""),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Edit",
                    onPressed: () async {
                      CommonUi().showLoadingDialog(context);
                      Directory? newDirectory2;
                      Directory? mainfolderDirectory;
                      Directory directory2 =
                          await FileMethods.getSaveDirectory();
                      newDirectory2 =
                          Directory('${directory2.path}/$dirFolderName');
                      await Constants.checkExists(newDirectory2);
                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/Template');
                      await Constants.checkExists(newDirectory2);
                      File templateFolderKeywordFile = File(
                          '${newDirectory2.path}/${mappedProjectTempData[index].templateName} keyword.txt');

                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[index].project}');
                      await Constants.checkExists(newDirectory2);

                      newDirectory2 = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[index].project}/GeneratedReport');
                      await Constants.checkExists(newDirectory2);

                      mainfolderDirectory = Directory(
                          '${directory2.path}/$dirFolderName/${mappedProjectTempData[index].project}');

                      Map<String, String> imageFiles =
                          await projectAndTemplateMapService
                              .getImageFiles(mainfolderDirectory);

                      List<String> imageNameList = [];
                      imageFiles.forEach((key, value) {
                        // print('File Name: $key');
                        // print('File Path: $value');
                        imageNameList.add(key);
                      });

                      File paseteKeywordFile = File(
                          '${newDirectory2.path}/${mappedProjectTempData[index].templateName} keyword.txt');
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
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: Sizing().height(18, 5),
                    ),
                  ),
                  Platform.isAndroid
                      ? IconButton(
                          tooltip: "Update table values",
                          onPressed: () async {
                            try {
                              // Directory pythonFileDir =
                              //     await Constants.getDataDirectory();
                              // String pythonFilePath = pythonFileDir.path;
                              CommonUi().showLoadingDialog(context);
                              String pName = mappedProjectTempData[index]
                                  .project
                                  .toString();
                              String tempName = mappedProjectTempData[index]
                                  .templateName
                                  .toString();
                              //select tableContentFile
                              Directory? newDirectory;
                              Directory? newDirectory2;
                              Directory directory =
                                  await FileMethods.getSaveDirectory();
                              Directory directory2 =
                                  await FileMethods.getSaveDirectory();
                              newDirectory2 = Directory(
                                  '${directory2.path}/$dirFolderName');
                              await Constants.checkExists(newDirectory2);
                              newDirectory2 = Directory(
                                  '${directory2.path}/$dirFolderName/Template');
                              await Constants.checkExists(newDirectory2);
                              newDirectory =
                                  Directory('${directory.path}/$dirFolderName');
                              await Constants.checkExists(newDirectory);

                              File templateFolderKeywordFile = File(
                                  '${newDirectory2.path}/${mappedProjectTempData[index].templateName} keyword.txt');

                              newDirectory = Directory(
                                  '${directory.path}/$dirFolderName/$pName');
                              await Constants.checkExists(newDirectory);
                              newDirectory = Directory(
                                  '${directory.path}/$dirFolderName/$pName/GeneratedReport');
                              await Constants.checkExists(newDirectory);

                              File tableContentFile = File(
                                  '${newDirectory.path}/$tempName tableContent.txt');

                              File keyContentPath = File(
                                  '${newDirectory.path}/$tempName keyword.txt');
                              String tableTempFile =
                                  '${newDirectory.path}/$tempName temp.docx';

                              // var result = await Process.run('python', [
                              //   '$pythonFilePath/extractTableData.py',
                              //   tableTempFile
                              // ]);
                              // if (result.stderr.isNotEmpty) {
                              //   errorLog.add(ErrorLogModel(
                              //       errorDescription:
                              //           'An error occurred in Python script: ${result.stderr}',
                              //       duration: DateTime.now().toString()));
                              //   errorLogService.saveErrorLog(errorLog);
                              //   print(
                              //       'An error occurred in Python script: ${result.stderr}');
                              // }
                              // String tableContent = result.stdout;
                              //extract table content from word file

                              //create table content text File
                              // await tableContentFile.writeAsString(tableContent,
                              //     mode: FileMode.write);
                              //select tableContentFile
                              String templateFilePath =
                                  '${newDirectory.path}/$tempName temp.docx';

                              templateFilePath =
                                  templateFilePath.replaceAll('\\', '/');
                              templateFilePath =
                                  templateFilePath.replaceAll('//', '/');

                              // String actualtemplatePath =
                              //     '${newDirectory.path}/$tempName.docx';
                              // actualtemplatePath =
                              //     actualtemplatePath.replaceAll('\\', '/');
                              // actualtemplatePath =
                              //     actualtemplatePath.replaceAll('//', '/');
                              //select tableContentFile

                              //extract the htmlcontent from the file
                              String tableHtmlContent =
                                  await tableContentFile.readAsString();

                              String templateFolderKeyword =
                                  await templateFolderKeywordFile
                                      .readAsString();
                              List<String> keywordList =
                                  templateFolderKeyword.split(',');
                              //extract the htmlcontent from the file
                              Navigator.pop(context);

                              Navigator.of(context).pushNamed(
                                  PageRouter.androidTableView,
                                  arguments: {
                                    "htmlString": tableHtmlContent,
                                    "keywordList": keywordList,
                                    "tableContentFilePath": tableContentFile,
                                    "keyContentPath": keyContentPath,
                                    // "dirPath": dir
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
                            color: Colors.grey,
                            size: Sizing().height(18, 5),
                          ),
                        )
                      : SizedBox()
                ],
              ),
            ));
          });
    } else {
      w = Center(
          child: Text(
        'No data',
        style: subtitle3,
        textAlign: TextAlign.center,
      ));
    }
    return w;
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
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Template Data",
                style: TextStyle(
                    fontSize: Sizing().height(10, 3.5),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: Sizing.width(10, 20),
              ),
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
          showValidation
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: Sizing.width(2, 5),
                          vertical: Sizing().height(4, 2)),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        'Please fill all the mandatory fields',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Sizing().height(6, 3)),
                      ),
                    ),
                  ],
                )
              : SizedBox(),
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
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: EdgeInsets.only(
                right: Sizing.width(5, 10), top: Sizing().height(5, 5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.maxFinite,
                  child: keyWordList.isNotEmpty
                      ? ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: keyWordList.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        bottom: Sizing().height(3, 2)),
                                    child: Row(
                                      children: [
                                        !keyWordList[index]
                                                    .toLowerCase()
                                                    .contains('image') &&
                                                !keyWordList[index]
                                                    .toLowerCase()
                                                    .contains('result')
                                            ? Text(
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
                                              )
                                            : SizedBox(),
                                        keyWordList[index].contains('*') &&
                                                !keyWordList[index]
                                                    .toLowerCase()
                                                    .contains('image') &&
                                                !keyWordList[index]
                                                    .toLowerCase()
                                                    .contains('result')
                                            ? Padding(
                                                padding: EdgeInsets.only(
                                                    left:
                                                        Sizing().height(2, 1)),
                                                child: Icon(
                                                  Icons.info,
                                                  size: Sizing().height(5, 3.5),
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
                                                .toLowerCase()
                                                .contains('result')
                                        ? TextFormField(
                                            initialValue:
                                                keyStore[keyWordList[index]] ??
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
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              keyStore[keyWordList[index]] =
                                                  value;
                                            },
                                          )
                                        : SizedBox()
                                    //       Container(
                                    //           // width: Sizing.width(60, 150),
                                    //           decoration: BoxDecoration(
                                    //               color: whiteColor,
                                    //               borderRadius:
                                    //                   BorderRadius.circular(3),
                                    //               border: Border.all(
                                    //                 color: Colors.black26,
                                    //               )),
                                    //           padding: EdgeInsets.symmetric(
                                    //               vertical: Sizing().height(2, 2),
                                    //               horizontal: Sizing.width(2, 2)),
                                    //           // margin: EdgeInsets.symmetric(
                                    //           //     vertical: Sizing().height(1, 2),
                                    //           //     horizontal: Sizing.width(3, 5)),
                                    //           child: DropdownButton<String>(
                                    //             isDense: true,
                                    //             isExpanded: true,
                                    //             hint: const Text(
                                    //               'Select Image',
                                    //             ),
                                    //             iconSize: Platform.isAndroid
                                    //                 ? Sizing.getScreenWidth(
                                    //                             context) >
                                    //                         1000
                                    //                     ? 30
                                    //                     : Sizing().height(20, 20)
                                    //                 : 25,
                                    //             iconEnabledColor: Colors.grey[600],
                                    //             underline: const SizedBox(),
                                    //             onChanged: (value) {
                                    //               keyStore[keyWordList[index]] =
                                    //                   value!;

                                    //               setState(() {
                                    //                 keyStore[keyWordList[index]] =
                                    //                     value;
                                    //               });
                                    //             },
                                    //             value: keyStore[
                                    //                         keyWordList[index]] !=
                                    //                     ''
                                    //                 ? keyStore[keyWordList[index]]
                                    //                 : null,
                                    //             items: imageNameList
                                    //                 .map((String value) {
                                    //               return DropdownMenuItem<String>(
                                    //                 value:
                                    //                     imageList[value].toString(),
                                    //                 child: Text(
                                    //                   value.toString(),
                                    //                 ),
                                    //               );
                                    //             }).toList(),
                                    //           ),
                                    //         ),

                                    )
                              ],
                            );
                          })
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
