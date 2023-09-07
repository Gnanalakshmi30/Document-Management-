// ignore_for_file: unused_import

import 'dart:io';
import 'package:USB_Share/Configuration/Model/saveCreatedDate_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:USB_Share/Project/Model/projectModel.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/styles.dart';
import 'package:image_cropping/image_cropping.dart' as winCropper;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SubFolderPage extends StatefulWidget {
  final String? projName;

  const SubFolderPage({super.key, this.projName});

  @override
  State<SubFolderPage> createState() => _SubFolderPageState();
}

class _SubFolderPageState extends State<SubFolderPage> {
  List<FileSystemEntity> entities = [];
  bool loading = true;
  bool? res;
  bool selectAll = false;
  List<DirectoryInfo> directoryInfo = [];
  List<DirectoryInfo> finalSubFolList = [];
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  Uint8List? windowsImageBytes;
  File? croppedResultImg;
  String dirFolderName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getSubFolders();
  }

  getSubFolders() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory('${directory.path}$dirFolderName/${widget.projName}');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
    try {
      directoryInfo = [];
      entities = dir.listSync();
      List<String?> sessionSubFolders =
          session.newAddedSubFol.map<String?>((e) => e.path).toList();
      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in entities) {
          if (entity is Directory) {
            var path = Platform.isWindows
                ? entity.path.split('\\').last
                : entity.path.split('/').last;
            // check with session list for new added subFol
            if (!sessionSubFolders.contains(path)) {
              final stat = entity.statSync();
              final modifiedDate = stat.modified.toString();
              directoryInfo.add(
                  DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
            }
          } else if (entity is File) {
            var path = Platform.isWindows
                ? entity.path.split('\\').last
                : entity.path.split('/').last;

            if (!sessionSubFolders.contains(path)) {
              final stat = entity.statSync();
              final modifiedDate = stat.modified.toString();
              directoryInfo.add(
                  DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
            }
          }
        }

        directoryInfo.addAll(session.newAddedSubFol);
      }
      //Sort the directory by modified date
      directoryInfo.sort((a, b) {
        var bPath = Platform.isWindows
            ? (b.path ?? "").split('\\').last
            : (b.path ?? "").split('/').last;
        var aPath = Platform.isWindows
            ? (a.path ?? "").split('\\').last
            : (a.path ?? "").split('/').last;

        return aPath.compareTo(bPath);
      });
      //Remove generated report folder and deleted subfolder
      if (directoryInfo.isNotEmpty) {
        directoryInfo.removeWhere((rr) {
          String path = Platform.isWindows
              ? (rr.path ?? "").split('\\').last
              : (rr.path ?? "").split('/').last;
          return path.toLowerCase().trim() == 'generatedreport' ||
              path.toLowerCase().trim().contains('.photoapp') ||
              path.toLowerCase().trim() ==
                  session.deletedSubFolder.toLowerCase().trim();
        });

        if (session.editedSubfolder != "") {
          directoryInfo.removeWhere((elem) =>
              (elem.path ?? "").split('/').last == session.editedSubfolder);
        }
      }

      if (mounted) {
        setState(() {
          finalSubFolList = directoryInfo;
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
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: appBar(),
            body: loading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Center(child: CommonUi().showLoading()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: Sizing.horizontalPadding,
                            child: subFolListView()),
                      ],
                    ),
                  )),
      ),
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        icon: CircleAvatar(
          radius: 13,
          backgroundColor: primaryColor,
          child: Icon(Icons.arrow_back,
              color: Colors.white,
              size: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                  ? 25
                  : Sizing().height(20, 5)),
        ),
        onPressed: () {
          session.newAddedSubFol = [];

          Navigator.of(context)
              .pushReplacementNamed(PageRouter.dashboard, arguments: {
            "index": 0,
            "newProjCreated": false,
          });
          // Navigator.of(context).pushNamed(PageRouter.dashboard, arguments: {
          //   "index": 0,
          //   "newProjCreated": false,
          // });
        },
      ),
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              res = await showDialog(
                  context: context,
                  builder: (context) {
                    return AddSubFolder(
                      projName: widget.projName,
                      isEdit: false,
                      dirFolderName: dirFolderName,
                    );
                  });

              if (res == true) {
                getSubFolders();
              } else {
                res = false;
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizing.width(3, 4),
                vertical: Sizing().height(2, 2),
              ),
              margin: EdgeInsets.symmetric(
                  horizontal: Sizing.width(2, 0),
                  vertical: Sizing().height(5, 2)),
              decoration: BoxDecoration(
                  color: primaryColor, borderRadius: BorderRadius.circular(7)),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: Sizing.width(1, 2)),
                    child: Text(
                      'Add subfolder',
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
                      Icons.create_new_folder,
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
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              galleryPicker();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizing.width(3, 4),
                vertical: Sizing().height(2, 2),
              ),
              margin: EdgeInsets.symmetric(
                  horizontal: Sizing.width(2, 10),
                  vertical: Sizing().height(5, 2)),
              decoration: BoxDecoration(
                  color: primaryColor, borderRadius: BorderRadius.circular(7)),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: Sizing.width(1, 2)),
                    child: Text(
                      'Add gallery image',
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
                      Icons.add_photo_alternate,
                      color: Colors.white,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 25
                          : Sizing().height(20, 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  galleryPicker() async {
    try {
      FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpeg', 'jpg', 'png'],
      );

      if (pickedFile == null) {
        windowsImageBytes = null;
      } else {
        CommonUi().showLoadingDialog(context);
        File file = File(pickedFile.files.single.path!);
        windowsImageBytes = await file.readAsBytes();

        await windowsCropImage(windowsImageBytes!);
        Navigator.pop(context);
        if (croppedResultImg != null) {
          final bytes = await croppedResultImg!.readAsBytes();
          final imgByte = Uint8List.fromList(bytes);

          saveImage(croppedResultImg!.path, imgByte, croppedResultImg!);
        }
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  windowsCropImage(Uint8List windowsImageBytes) async {
    try {
      List<int>? croppedImg = await winCropper.ImageCropping.cropImage(
          visibleOtherAspectRatios: false,
          context: context,
          imageBytes: windowsImageBytes,
          onImageDoneListener: (data) {
            setState(
              () {
                windowsImageBytes = data;
              },
            );
          },
          customAspectRatios: [
            winCropper.CropAspectRatio(
              ratioX: 3,
              ratioY: 2,
            ),
          ],
          squareBorderWidth: 2,
          isConstrain: false,
          squareCircleColor: primaryColor,
          defaultTextColor: Colors.black,
          selectedTextColor: Colors.orange,
          colorForWhiteSpace: Colors.white,
          makeDarkerOutside: true,
          outputImageFormat: winCropper.OutputImageFormat.jpg,
          encodingQuality: 10);

      if (croppedImg != null) {
        Directory dir;
        Directory winDir = await getApplicationDocumentsDirectory();
        dir = Directory('${winDir.path}/$dirFolderName');
        String tempPath = dir.path;
        String dT = DateFormat('yymmddmmss').format(DateTime.now());
        File tempFile = File('$tempPath/pickedImage$dT.jpg');
        await tempFile.writeAsBytes(croppedImg);
        setState(() {
          croppedResultImg = tempFile;
          final size = ImageSizeGetter.getSize(FileInput(croppedResultImg!));
          session.selectedWidth = size.width;
          session.selectedHeight = size.height;
        });
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  saveImage(String imagePath, Uint8List imgByte, File img) async {
    try {
      Navigator.of(context)
          .pushNamed(PageRouter.viewWatermarkImage, arguments: {
        "projName": widget.projName,
        "image": img,
        "isWithoutSubfolder": true,
      });
    } on Exception catch (e) {
      rethrow;
    }
  }

  subFolListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(
              left: Sizing.width(5, 10),
              right: Sizing.width(5, 10),
              top: Sizing().height(5, 10),
              bottom: Sizing().height(5, 5),
            ),
            child: Text('${widget.projName} - Subfolder(s) & File(s)',
                style:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? TextStyle(fontSize: 17, color: primaryColor)
                        : TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor))),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Sizing.width(5, 10),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: Sizing.width(5, 5), vertical: Sizing().height(5, 2)),
          decoration: BoxDecoration(
              color: Color(0xfff6f6f6),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Table(
                columnWidths: {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: subfolderTable(),
              ),
              finalSubFolList.length == 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Sizing().height(5, 5)),
                          child: Text(
                            'No subfolder found',
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
      ],
    );
  }

  subfolderTable() {
    List<TableRow> subFolList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Name",
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
          child: Text("Actions",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ]),
    ];

    if (finalSubFolList.length > 0) {
      for (int i = 0; i < finalSubFolList.length; i++) {
        subFolList.add(TableRow(children: [
          Row(
            children: [
              finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpeg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('png')
                  ? Icon(Icons.image,
                      color: primaryColor,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 25
                          : Sizing().height(20, 4))
                  : Icon(Icons.folder,
                      color: primaryColor,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 25
                          : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Text(finalSubFolList[i].path!.split('\\').last,
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                Constants.modifiedDateFormat.format(
                    DateTime.parse(finalSubFolList[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Row(
            children: [
              finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpeg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('png')
                  ? SizedBox()
                  : IconButton(
                      tooltip: 'Rename folder',
                      onPressed: () async {
                        res = await showDialog(
                            context: context,
                            builder: (context) {
                              return AddSubFolder(
                                projName: widget.projName,
                                subFolName:
                                    finalSubFolList[i].path!.split('\\').last,
                                isEdit: true,
                                dirFolderName: dirFolderName,
                              );
                            });

                        if (res == true) {
                          getSubFolders();
                        } else {
                          res = false;
                        }
                      },
                      icon: Icon(
                        Icons.edit,
                        size: Sizing.getScreenWidth(context) > 1000 &&
                                !Platform.isWindows
                            ? 25
                            : Sizing().height(20, 4),
                      )),
              finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('jpeg') ||
                      finalSubFolList[i]
                          .path!
                          .split('\\')
                          .last
                          .toLowerCase()
                          .contains('png')
                  ? IconButton(
                      tooltip: "View image",
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(PageRouter.photoViewImage, arguments: {
                          "image": File(finalSubFolList[i].path ?? "")
                        });
                      },
                      icon: Icon(
                        Icons.visibility,
                        color: Colors.blue,
                        size: Sizing.getScreenWidth(context) > 1000 &&
                                !Platform.isWindows
                            ? 25
                            : Sizing().height(20, 4),
                      ),
                    )
                  : IconButton(
                      tooltip: "View library",
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(PageRouter.addImagePage, arguments: {
                          "projName": widget.projName,
                          "folderName": Platform.isWindows
                              ? finalSubFolList[i].path!.split('\\').last
                              : finalSubFolList[i].path!.split('/').last,
                        });
                      },
                      icon: Icon(
                        Icons.photo_library,
                        color: Colors.blue,
                        size: Sizing.getScreenWidth(context) > 1000 &&
                                !Platform.isWindows
                            ? 25
                            : Sizing().height(20, 4),
                      ),
                    ),
              IconButton(
                  tooltip: finalSubFolList[i]
                              .path!
                              .split('\\')
                              .last
                              .toLowerCase()
                              .contains('jpg') ||
                          finalSubFolList[i]
                              .path!
                              .split('\\')
                              .last
                              .toLowerCase()
                              .contains('jpeg') ||
                          finalSubFolList[i]
                              .path!
                              .split('\\')
                              .last
                              .toLowerCase()
                              .contains('png')
                      ? 'Delete file'
                      : 'Delete folder',
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
                                              String subFolName =
                                                  Platform.isWindows
                                                      ? finalSubFolList[i]
                                                          .path!
                                                          .split('\\')
                                                          .last
                                                      : finalSubFolList[i]
                                                          .path!
                                                          .split('/')
                                                          .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();

                                              if (finalSubFolList[i]
                                                      .path!
                                                      .split('\\')
                                                      .last
                                                      .toLowerCase()
                                                      .contains('jpg') ||
                                                  finalSubFolList[i]
                                                      .path!
                                                      .split('\\')
                                                      .last
                                                      .toLowerCase()
                                                      .contains('jpeg') ||
                                                  finalSubFolList[i]
                                                      .path!
                                                      .split('\\')
                                                      .last
                                                      .toLowerCase()
                                                      .contains('png')) {
                                                Directory newDirectory = Directory(
                                                    '${directory.path}/$dirFolderName/${widget.projName}/$subFolName');
                                                File imageFile = File(
                                                    '${newDirectory.path}');
                                                if (await imageFile.exists()) {
                                                  await imageFile.delete();
                                                }
                                              } else {
                                                Directory newDirectory = Directory(
                                                    '${directory.path}/$dirFolderName/${widget.projName}/$subFolName');
                                                if (await newDirectory
                                                    .exists()) {
                                                  await newDirectory.delete(
                                                      recursive: true);
                                                }
                                              }

                                              setState(() {
                                                session.deletedSubFolder =
                                                    subFolName;
                                                session.newAddedSubFol
                                                    .removeWhere((element) =>
                                                        element.path ==
                                                        subFolName);

                                                getSubFolders();
                                              });

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
    return subFolList;
  }

  selectAllGuest() {
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              checkColor: Colors.white,
              activeColor: primaryColor,
              value: selectAll,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    selectAll = !selectAll;
                  });
                }
              },
            ),
          ),
          Text(
            "select all",
            textAlign: TextAlign.start,
            style: subtitle1,
          ),
        ],
      ),
    );
  }
}

class AddSubFolder extends StatefulWidget {
  final String? projName;
  final String? subFolName;
  final bool? isEdit;
  final String? dirFolderName;
  const AddSubFolder(
      {super.key,
      this.projName,
      this.subFolName,
      this.isEdit,
      this.dirFolderName});

  @override
  State<AddSubFolder> createState() => _AddSubFolderState();
}

class _AddSubFolderState extends State<AddSubFolder> {
  final TextEditingController _folderName = TextEditingController();
  final TextEditingController _folderCount = TextEditingController();
  bool showErrorMsg = false;
  bool showCountErrorMsg = false;
  bool showZeroErrorMsg = false;
  final configurationService = ConfigurationService();
  bool projExists = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit == true) {
      _folderName.text = widget.subFolName ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: widget.isEdit == true
            ? Text(
                'Rename Subfolder',
                style: TextStyle(
                    fontSize: Sizing().height(2, 3.5),
                    fontWeight: FontWeight.w500),
              )
            : Text(
                'Add Subfolder',
                style: TextStyle(
                    fontSize: Sizing().height(2, 3.5),
                    fontWeight: FontWeight.w500),
              ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            folderField(),
            showErrorMsg
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Subfolder name is required',
                        style: TextStyle(
                            fontSize: Sizing().height(10, 3),
                            color: Colors.red),
                      ),
                    ],
                  )
                : const SizedBox(),
            widget.isEdit == false
                ? SizedBox(height: Sizing().height(10, 5))
                : SizedBox(),
            widget.isEdit == false ? folderCountField() : SizedBox(),
            widget.isEdit == false && showCountErrorMsg
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'No.of subfolder(s) is required',
                        style: TextStyle(
                            fontSize: Sizing().height(10, 3),
                            color: Colors.red),
                      ),
                    ],
                  )
                : const SizedBox(),
            widget.isEdit == false && showZeroErrorMsg
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Subfolder count is invalid',
                        style: TextStyle(
                            fontSize: Sizing().height(10, 3),
                            color: Colors.red),
                      ),
                    ],
                  )
                : const SizedBox(),
            projExists
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Subfolder already exists',
                        style: TextStyle(
                            fontSize: Sizing().height(10, 3),
                            color: Colors.red),
                      ),
                    ],
                  )
                : SizedBox(),
          ],
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
                  await _createsubFolder();
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

  folderField() {
    return TextFormField(
      onFieldSubmitted: (value) async {
        await _createsubFolder();
      },
      controller: _folderName,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(10, 3)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Subfolder Name',
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(10, 3))),
      maxLength: 18,
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
        });
      },
    );
  }

  folderCountField() {
    return TextFormField(
      onFieldSubmitted: (value) async {
        await _createsubFolder();
      },
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 2,
      keyboardType: TextInputType.number,
      controller: _folderCount,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(10, 3)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'No.of Subfolder(s)',
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(10, 3))),
      onChanged: (value) async {
        setState(() {
          showCountErrorMsg = false;
          showZeroErrorMsg = false;
        });
      },
    );
  }

  checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  _createsubFolder() async {
    DateTime now = DateTime.now();
    String currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    try {
      bool folderName = false;
      bool count = false;
      bool zeroCount = false;

      if (_folderName.text == "") {
        folderName = true;
        setState(() {
          showErrorMsg = true;
        });
      }
      if (_folderCount.text == "") {
        count = true;
        setState(() {
          showCountErrorMsg = true;
        });
      }
      if (_folderCount.text != "" && int.parse(_folderCount.text) <= 0) {
        zeroCount = true;
        setState(() {
          showZeroErrorMsg = true;
        });
      }

      if (folderName == false) {
        String subFolderName = "";
        if (widget.isEdit == false) {
          subFolderName = "${widget.projName}_${_folderName.text}";
        } else {
          subFolderName = "${_folderName.text}";
        }
        Directory? newDirectory;
        Directory? oldDirectory;
        Directory directory = await FileMethods.getSaveDirectory();
        newDirectory = Directory('${directory.path}${widget.dirFolderName}');

        if (Platform.isAndroid) {
          newDirectory = Directory(
              '${directory.path}/${widget.dirFolderName}/${widget.projName}');
          await checkExists(newDirectory);
          for (int i = 1; i <= int.parse(_folderCount.text); i++) {
            newDirectory = Directory(
                '${directory.path}/${widget.dirFolderName}/${widget.projName}/${subFolderName}_$i');
            await checkExists(newDirectory);
          }
        } else if (Platform.isWindows) {
          if (widget.isEdit == false && count == false && zeroCount == false) {
            newDirectory = Directory(
                '${directory.path}/${widget.dirFolderName}/${widget.projName}');
            await checkExists(newDirectory);

            newDirectory = Directory(
                '${directory.path}/${widget.dirFolderName}/${widget.projName}/${subFolderName}_1');
            if (!await newDirectory.exists()) {
              for (int i = 1; i <= int.parse(_folderCount.text); i++) {
                newDirectory = Directory(
                    '${directory.path}/${widget.dirFolderName}/${widget.projName}/${subFolderName}_$i');

                await checkExists(newDirectory);

                File cFile = File(
                    '${directory.path}/${widget.dirFolderName}/${widget.projName}/${subFolderName}_$i/.PhotoApp.txt');

                cFile.create();

                final result = await Process.run('attrib', ['+h', cFile.path]);
              }

              if (newDirectory != null) {
                session.newAddedSubFol.add(DirectoryInfo(
                    path: newDirectory.path.split('/').last,
                    modifiedDate: DateTime.now().toString()));
                session.deletedSubFolder = "";
              }

              Navigator.pop(context, true);
            } else {
              setState(() {
                projExists = true;
              });
            }
          } else if (widget.isEdit == true) {
            if (widget.subFolName != subFolderName) {
              oldDirectory = Directory(
                  '${directory.path}/${widget.dirFolderName}/${widget.projName}/${widget.subFolName}');
              newDirectory = Directory(
                  '${directory.path}/${widget.dirFolderName}/${widget.projName}/$subFolderName');

              if (oldDirectory.existsSync()) {
                oldDirectory.renameSync(
                    '${directory.path}/${widget.dirFolderName}/${widget.projName}/$subFolderName');
              }
              if (mounted) {
                setState(() {
                  session.editedSubfolder = '${widget.subFolName}';
                });
              }
            }

            Navigator.of(context).pushNamed(PageRouter.subFolderPage,
                arguments: {
                  "projName": widget.projName
                }).then((value) => setState(() {}));
          }
        }
      }
    } on Exception catch (e) {
      rethrow;
    }
  }
}
