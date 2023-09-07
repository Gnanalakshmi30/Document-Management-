// ignore_for_file: prefer_const_constructors, prefer_final_fields

import 'dart:io';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/Dashboard/Page/dashboard_page.dart';
import 'package:USB_Share/Template/Model/projectAndTemplateMapModel.dart';
import 'package:USB_Share/Template/Service/projectAndTemplateMapService.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:USB_Share/Project/Model/projectModel.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  bool isLoading = false;
  Box box = Hive.box('appData');
  bool loading = true;

  final GlobalKey globalKey = GlobalKey();
  Uint8List? uImg;
  List<String> projList = [];
  bool selectAll = false;
  String dirFolderName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    setState(() {});
    getFiles();
  }

  List<FileSystemEntity> entities = [];

  //get files from internalStorage
  void getFiles() async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/sdcard/Download/$dirFolderName');
    } else if (Platform.isWindows) {
      Directory directory = await getApplicationDocumentsDirectory();
      dir = Directory('${directory.path}/$dirFolderName');
    }

    if (!await dir!.exists()) {
      await dir.create(recursive: true);
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
    try {
      entities = await dir.list().toList();

      var data = entities.reversed.toList();
      if (mounted) {
        setState(() {
          entities = data;
          loading = false;
        });
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: whiteColor,
            appBar: appBar(),
            body: loading
                ? CommonUi().showLoading()
                : SingleChildScrollView(
                    child: Padding(
                        padding: Sizing.horizontalPadding,
                        child: projectListView()),
                  )));
  }

  appBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            session.selectedFolders = [];
            selectAll = false;
          });
        },
      ),
      backgroundColor: primaryColor,
      title: const Text(
        'Photo App',
      ),
      actions: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AddProject();
                  });
            },
          ),
        ),
      ],
    );
  }

  checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

// single or multi select project folders
  // Future<void> copyDirectory(String source, String destination) async {
  //   try {
  //     final sourceDir = Directory(source);
  //     final destinationDir = Directory(destination);
  //     if (!destinationDir.existsSync()) {
  //       destinationDir.createSync(recursive: true);
  //     }
  //     final List<FileSystemEntity> files = sourceDir.listSync(recursive: true);

  //     for (final FileSystemEntity fileOrDir in files) {
  //       final String newPath =
  //           '${destinationDir.path}/${fileOrDir.uri.path.substring(sourceDir.uri.path.length)}';
  //       if (fileOrDir is File) {
  //         fileOrDir.copySync(newPath);
  //       } else if (fileOrDir is Directory) {
  //         Directory(newPath).createSync(recursive: true);
  //       }
  //     }
  //     DateTime syncedTime = DateTime.now();
  //     HiveHelper().saveSyncedTime(syncedTime);
  //     session.isProjSelect = true;
  //     setState(() {
  //       session.selectedFolders = [];
  //       selectAll = false;
  //     });
  //     await PhotonSender.handleSharing();
  //   } on Exception catch (e) {
  //     throw e;
  //   }
  // }

  projectListView() {
    var red = entities.where((c) => !c.path.split('/').last.contains(".zip"));
    if (red.isNotEmpty) {
      entities = red.toList();
    }
    var x = entities.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            primary: false,
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final currentItem = entities[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(PageRouter.subFolderPage, arguments: {
                    "projName": Platform.isWindows
                        ? currentItem.path.split('\\').last
                        : currentItem.path.split('/').last
                  });
                },
                child: Card(
                  color: whiteColor,
                  child: ListTile(
                    leading: Icon(
                      Icons.folder,
                      color: Colors.yellow[600],
                      size: Platform.isAndroid ? Sizing().height(30, 35) : 30,
                    ),
                    title: Text(Platform.isWindows
                        ? currentItem.path.split('\\').last
                        : currentItem.path.split('/').last),
                  ),
                ),
              );
            })
        : Center(
            child: Text(
            'No data',
            style: subtitle1,
          ));
    return x;
  }

  selectAllGuest() {
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              side: BorderSide(color: Colors.grey, width: 2.0),
              checkColor: Colors.white,
              activeColor: primaryColor,
              value: selectAll,
              onChanged: (value) {
                if (mounted) {
                  List<String> tempFolderName = [];
                  setState(() {
                    selectAll = !selectAll;
                    entities.forEach((element) {
                      if (selectAll) {
                        tempFolderName.add(element.path);
                      } else {
                        tempFolderName = [];
                      }
                    });
                    session.selectedFolders = tempFolderName;
                  });
                }
              },
            ),
          ),
          Text(
            "select all",
            textAlign: TextAlign.start,
            style: subtitle1.copyWith(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class AddProject extends StatefulWidget {
  final String? projName;
  final String? projNo;
  final bool? isEdit;
  final String? dirFolderName;
  const AddProject(
      {super.key, this.projName, this.projNo, this.isEdit, this.dirFolderName});

  @override
  State<AddProject> createState() => _AddProjectState();
}

class _AddProjectState extends State<AddProject> {
  final TextEditingController _projName = TextEditingController();

  TextEditingController _jobTitle = TextEditingController();
  bool showErrorMsg = false;
  bool showProjNameErrorMsg = false;

  final configurationService = ConfigurationService();
  bool projExists = false;
  final projTempService = ProjectAndTemplateMapService();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit == true) {
      _jobTitle.text = widget.projNo ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: widget.isEdit == true
            ? Text(
                'Rename Project',
                style: TextStyle(
                    fontSize: Sizing().height(13, 3.5),
                    fontWeight: FontWeight.w500),
              )
            : Text(
                'Add Project',
                style: TextStyle(
                    fontSize: Sizing().height(13, 3.5),
                    fontWeight: FontWeight.w500),
              ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Platform.isAndroid
                  ? Sizing.getScreenWidth(context) > 1000
                      ? SizedBox(height: 15)
                      : Sizing.spacingHeight
                  : const SizedBox(),
              jobtitleField(),
              showErrorMsg
                  ? SizedBox(height: Sizing().height(5, 2))
                  : SizedBox(),
              showErrorMsg
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Project No is required',
                          style: TextStyle(
                              fontSize: Sizing().height(10, 3),
                              color: Colors.red),
                        ),
                      ],
                    )
                  : SizedBox(),
              projExists
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Project folder already exists',
                          style: TextStyle(
                              fontSize: Sizing().height(10, 3),
                              color: Colors.red),
                        ),
                      ],
                    )
                  : SizedBox(),
            ],
          ),
        ),
        actions: [
          Container(
            height: Sizing().height(30, 7),
            margin: EdgeInsets.only(bottom: Sizing().height(10, 3)),
            decoration: BoxDecoration(
                color: greyColor, borderRadius: BorderRadius.circular(5)),
            child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                      fontSize: Sizing().height(10, 3), color: whiteColor),
                )),
          ),
          Container(
            height: Sizing().height(30, 7),
            margin: EdgeInsets.only(bottom: Sizing().height(10, 3)),
            decoration: BoxDecoration(
                color: primaryColor, borderRadius: BorderRadius.circular(5)),
            child: TextButton(
                onPressed: () async {
                  await _createFolder();
                },
                child: Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: Sizing().height(10, 3), color: whiteColor),
                )),
          ),
          SizedBox(
            width: Sizing.width(4, 4),
          )
        ]);
  }

  _createFolder() async {
    DateTime now = DateTime.now();
    String currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    try {
      if (_jobTitle.text == "") {
        setState(() {
          showErrorMsg = true;
        });
      }

      if (showErrorMsg == false) {
        String folderName;

        folderName = _jobTitle.text;

        Directory? newDirectory;
        Directory? oldDirectory;
        Directory directory = await FileMethods.getSaveDirectory();
        newDirectory = Directory('${directory.path}${widget.dirFolderName}');

        if (Platform.isAndroid) {
          if (widget.isEdit == false) {
            newDirectory = Directory(
                '${directory.path}/${widget.dirFolderName}/$folderName');
            await checkExists(newDirectory);

            //create photoSyncFolderDir in PhotoApp
            Directory photoSyncFolderDir = Directory(
                '${directory.path}/${widget.dirFolderName}/PhotoSync');

            if (!await photoSyncFolderDir.exists()) {
              await photoSyncFolderDir.create(recursive: true);
            }
            //create photoSyncFolderDir in PhotoApp

            //create project in photoSyncFolder
            Directory newSyncDirectory =
                Directory('${photoSyncFolderDir.path}/$folderName');
            await checkExists(newSyncDirectory);

            session.newAddedProj.add(DirectoryInfo(
                path: newDirectory.path.split('/').last,
                modifiedDate: DateTime.now().toString()));

            // session.deletedProject = [];
            session.deletedProject.removeWhere((element) =>
                element.toLowerCase() ==
                newDirectory!.path.split('/').last.toLowerCase());

            Navigator.of(context).pushNamed(
              PageRouter.androidDashboardPage,
            );
          } else if (widget.isEdit == true) {
            String pName = widget.projName == "-"
                ? '${widget.projNo}'
                : '${widget.projName}_${widget.projNo}';

            if (pName != folderName) {
              oldDirectory = widget.projName == "-"
                  ? Directory(
                      '${directory.path}/${widget.dirFolderName}/${widget.projNo}')
                  : Directory(
                      '${directory.path}/${widget.dirFolderName}/${widget.projName}_${widget.projNo}');
              newDirectory = Directory(
                  '${directory.path}/${widget.dirFolderName}/$folderName');

              if (oldDirectory.existsSync()) {
                oldDirectory.renameSync(
                    '${directory.path}/${widget.dirFolderName}/$folderName');

                //replace the project name in TemplateAndProjMappingfile
                List<ProjectAndTemplateMapModel> pData =
                    await projTempService.getProjectAndTemplateMapping();
                pData.forEach((f) {
                  if (widget.projName == "-") {
                    if (f.project == '${widget.projNo}') {
                      f.project = (f.project ?? "")
                          .replaceAll('${widget.projNo}', '$folderName');
                    }
                  } else {
                    if (f.project == '${widget.projName}_${widget.projNo}') {
                      f.project = (f.project ?? "").replaceAll(
                          '${widget.projName}_${widget.projNo}', '$folderName');
                    }
                  }
                });

                projTempService.saveProjectAndTemplateMapping(pData);
                //replace the project name in TemplateAndProjMappingfile
              }

              //create photoSyncFolderDir in PhotoApp
              Directory photoSyncFolderDir = Directory(
                  '${directory.path}/${widget.dirFolderName}/PhotoSync');

              if (!await photoSyncFolderDir.exists()) {
                await photoSyncFolderDir.create(recursive: true);
              }
              //create photoSyncFolderDir in PhotoApp

              //Edit / create project in photoSyncFolder
              Directory oldSyncDirectory = widget.projName == "-"
                  ? Directory('${photoSyncFolderDir.path}/${widget.projNo}')
                  : Directory(
                      '${photoSyncFolderDir.path}/${widget.projName}_${widget.projNo}');
              Directory newSyncDirectory =
                  Directory('${photoSyncFolderDir.path}/$folderName');

              if (oldSyncDirectory.existsSync()) {
                oldSyncDirectory.renameSync(newSyncDirectory.path);
              } else {
                //create project in photoSyncFolder
                await checkExists(newSyncDirectory);
              }

              //Edit / create project in photoSyncFolder

              if (!session.editedProjAndroid.contains(widget.projName == "-"
                  ? '${widget.projNo}'
                  : '${widget.projName}_${widget.projNo}')) {
                if (mounted) {
                  setState(() {
                    session.editedProjAndroid.add(widget.projName == "-"
                        ? '${widget.projNo}'
                        : '${widget.projName}_${widget.projNo}');

                    session.deletedProject.removeWhere((element) =>
                        element.toLowerCase() == folderName.toLowerCase());
                    session.isEdit = true;
                  });
                }
              }
              Navigator.of(context)
                  .pushNamed(
                    PageRouter.androidDashboardPage,
                  )
                  .then((value) => setState(() {}));
            } else {
              setState(() {
                session.isEdit = true;
              });
              Navigator.of(context)
                  .pushNamed(
                    PageRouter.androidDashboardPage,
                  )
                  .then((value) => setState(() {}));
            }
          }
        } else if (Platform.isWindows) {
          if (widget.isEdit == false) {
            newDirectory = Directory(
                '${directory.path}/${widget.dirFolderName}/$folderName');
            if (!await newDirectory.exists()) {
              await newDirectory.create(recursive: true);
              File cFile = File(
                  '${directory.path}/${widget.dirFolderName}/$folderName/.PhotoApp.txt');

              cFile.create();
              final result = await Process.run('attrib', ['+h', cFile.path]);

              session.newAddedProj.add(DirectoryInfo(
                  path: newDirectory.path.split('/').last,
                  modifiedDate: DateTime.now().toString()));
              // session.deletedProject =[];
              session.deletedProject.removeWhere((element) =>
                  element.toLowerCase() ==
                  newDirectory!.path.split('/').last.toLowerCase());

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardPage(
                            index: 0,
                            newProjCreated: true,
                          )));
            } else {
              setState(() {
                projExists = true;
              });
            }
          } else if (widget.isEdit == true) {
            String pName = widget.projName == "-"
                ? '${widget.projNo}'
                : '${widget.projName}_${widget.projNo}';
            if (pName != folderName) {
              oldDirectory = widget.projName == "-"
                  ? Directory(
                      '${directory.path}/${widget.dirFolderName}/${widget.projNo}')
                  : Directory(
                      '${directory.path}/${widget.dirFolderName}/${widget.projName}_${widget.projNo}');
              newDirectory = Directory(
                  '${directory.path}/${widget.dirFolderName}/$folderName');

              if (oldDirectory.existsSync()) {
                oldDirectory.renameSync(
                    '${directory.path}/${widget.dirFolderName}/$folderName');

                //replace the project name in TemplateAndProjMappingfile
                List<ProjectAndTemplateMapModel> pData =
                    await projTempService.getProjectAndTemplateMapping();
                pData.forEach((f) {
                  if (widget.projName == "-") {
                    if (f.project == '${widget.projNo}') {
                      f.project = (f.project ?? "")
                          .replaceAll('${widget.projNo}', '$folderName');
                    }
                  } else {
                    if (f.project == '${widget.projName}_${widget.projNo}') {
                      f.project = (f.project ?? "").replaceAll(
                          '${widget.projName}_${widget.projNo}', '$folderName');
                    }
                  }
                });

                projTempService.saveProjectAndTemplateMapping(pData);
                //replace the project name in TemplateAndProjMappingfile
              }

              if (!session.editedProjWindows.contains(widget.projName == "-"
                  ? '${widget.projNo}'
                  : '${widget.projName}_${widget.projNo}')) {
                if (mounted) {
                  setState(() {
                    session.editedProjWindows.add(widget.projName == "-"
                        ? '${widget.projNo}'
                        : '${widget.projName}_${widget.projNo}');

                    session.isEdit = true;
                  });
                }
              }

              session.deletedProject.removeWhere((element) =>
                  element.toLowerCase() == folderName.toLowerCase());

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardPage(
                            index: 0,
                            newProjCreated: true,
                          ))).then((value) => setState(() {}));
            } else {
              setState(() {
                session.isEdit = true;
              });
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardPage(
                            index: 0,
                            newProjCreated: true,
                          ))).then((value) => setState(() {}));
            }
          }
        }
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  projectField() {
    return TextField(
      controller: _projName,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(10, 3)),
      maxLength: 18,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Project Name',
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(10, 3))),
      onChanged: (value) async {
        setState(() {
          showProjNameErrorMsg = false;
        });
      },
    );
  }

  jobtitleField() {
    return TextFormField(
      onFieldSubmitted: (val) async {
        if (val != '') {
          await _createFolder();
        }
      },
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 30,
      keyboardType: TextInputType.number,
      controller: _jobTitle,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(10, 3)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Project No',
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(10, 3))),
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
        });
      },
    );
  }
}
