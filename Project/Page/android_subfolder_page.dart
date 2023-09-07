// ignore_for_file: prefer_final_fields, unused_import

import 'dart:io';
import 'package:USB_Share/AddImage/Model/addImage_model.dart';
import 'package:USB_Share/AddImage/Service/add_Image_service.dart';
import 'package:USB_Share/Configuration/Model/saveCreatedDate_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
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
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:intl/intl.dart';

class AndroidSubFolderPage extends StatefulWidget {
  final String? projName;

  const AndroidSubFolderPage({super.key, this.projName});

  @override
  State<AndroidSubFolderPage> createState() => _AndroidSubFolderPageState();
}

class _AndroidSubFolderPageState extends State<AndroidSubFolderPage> {
  List<FileSystemEntity> entities = [];
  bool loading = true;
  bool? res;
  bool selectAll = false;
  List<DirectoryInfo> directoryInfo = [];
  List<DirectoryInfo> finalSubFolList = [];
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  File? galleryPicked;
  File? croppedResultImg;
  File? cameraPicked;
  final imageService = ImageService();
  List<ImageLogModel> imglogData = [];
  List<ImageLogModel> finalImageList = [];

  List<String> fileNameLog = [];
  Map<int, String> imgLogData = {};
  var dFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String dirFolderName = "";
  String dirConfigFolderName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
      dirConfigFolderName = Constants.dataFolder;
    });
    getSubFolders();
    getImageLogData();
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
              final modifiedDate = Constants.dFormat.format(stat.modified);
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

  getImageLogData() async {
    String? imgN;
    var res = await imageService.getImageLog();
    setState(() {
      imglogData = res;
    });
    int count = 0;
    for (var element in res) {
      if ((element.imageName ?? "").contains(widget.projName ?? '')) {
        if (element.imageName != null && element.imageName != '') {
          if (element.imageName!.contains('WaterMark')) {
            finalImageList.add(ImageLogModel(
                imageName: element.imageName!.split('WaterMark/').last,
                syncedDate: element.syncedDate));
          } else if (element.imageName!.contains('Compressed')) {
            finalImageList.add(ImageLogModel(
                imageName: element.imageName!.split('Compressed/').last,
                syncedDate: element.syncedDate));
          } else if (element.imageName!.contains('Original')) {
            finalImageList.add(ImageLogModel(
                imageName: element.imageName!.split('Original/').last,
                syncedDate: element.syncedDate));
          } else {
            finalImageList.add(ImageLogModel(
                imageName: element.imageName, syncedDate: element.syncedDate));
          }
        }
        fileNameLog.add(imgN ?? "");
        imgLogData[count] = element.syncedDate ?? '';
      }
    }
    count++;
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
                    child: Padding(
                        padding: Sizing.horizontalPadding,
                        child: subFolListView()),
                  )),
      ),
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: primaryColor,
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
          session.newAddedSubFol = [];
          // Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(
            PageRouter.androidDashboardPage,
          );
        },
      ),
      title: Text(widget.projName ?? '',
          style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
              ? const TextStyle(fontSize: 25)
              : const TextStyle()),
      actions: [
        Padding(
          padding: Sizing.horizontalPadding,
          child: IconButton(
            tooltip: "Add subfolder",
            icon: Icon(
              Icons.create_new_folder,
              size: Platform.isAndroid
                  ? Sizing.getScreenWidth(context) > 1000
                      ? 40
                      : Sizing().height(20, 20)
                  : 30,
            ),
            onPressed: () async {
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
          ),
        ),
        Padding(
          padding: Sizing.horizontalPadding,
          child: IconButton(
            tooltip: "Add camera image",
            icon: Icon(
              Icons.add_a_photo,
              size: Platform.isAndroid
                  ? Sizing.getScreenWidth(context) > 1000
                      ? 40
                      : Sizing().height(20, 20)
                  : 30,
            ),
            onPressed: () async {
              cameraPicker();
            },
          ),
        ),
        Padding(
          padding: Sizing.horizontalPadding,
          child: IconButton(
            tooltip: "Add gallery image",
            icon: Icon(
              Icons.add_photo_alternate,
              size: Platform.isAndroid
                  ? Sizing.getScreenWidth(context) > 1000
                      ? 40
                      : Sizing().height(20, 20)
                  : 30,
            ),
            onPressed: () async {
              galleryPicker();
            },
          ),
        ),
      ],
    );
  }

  galleryPicker() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final galleryImg = File(image.path);
      setState(() {
        galleryPicked = galleryImg;
      });

      await cropImage(galleryImg);
      if (croppedResultImg != null) {
        final bytes = await croppedResultImg!.readAsBytes();
        final imgByte = Uint8List.fromList(bytes);

        saveImage(croppedResultImg!.path, imgByte, croppedResultImg!);
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  cameraPicker() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;
      final cameraImg = File(image.path);
      setState(() {
        cameraPicked = cameraImg;
      });

      await cropImage(cameraImg);
      final bytes = await croppedResultImg!.readAsBytes();
      final imgByte = Uint8List.fromList(bytes);
      saveImage(croppedResultImg!.path, imgByte, croppedResultImg!);
    } on Exception catch (e) {
      rethrow;
    }
  }

  cropImage(File img) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: img.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.ratio4x3,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        croppedResultImg = File(croppedFile.path);
        final size = ImageSizeGetter.getSize(FileInput(croppedResultImg!));
        session.selectedWidth = size.width;
        session.selectedHeight = size.height;
      });
    }
  }

  saveImage(String imagePath, Uint8List imgByte, File img) async {
    try {
      Navigator.of(context)
          .pushNamed(PageRouter.androidViewWaterMark, arguments: {
        "projName": widget.projName,
        "image": img,
        "isWithoutSubfolder": true,
      });
    } on Exception catch (e) {
      rethrow;
    }
  }

  subFolListView() {
    late String syncD;
    var x = finalSubFolList.isNotEmpty
        ? Column(
            children: [
              ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  primary: false,
                  itemCount: finalSubFolList.length,
                  itemBuilder: (context, index) {
                    final currentItem = finalSubFolList[index];
                    syncD = "";

                    var fileName = Platform.isWindows
                        ? currentItem.path!.split('\\').last
                        : currentItem.path!.split('/').last;
                    var data = finalImageList.where((j) =>
                        j.imageName!.split('\\').last.trim() == fileName);
                    List<ImageLogModel> filteredImageList = [];
                    bool iconCheck = false;

                    if (data.isNotEmpty) {
                      filteredImageList = data.toList();
                    }
                    if (filteredImageList.isNotEmpty) {
                      iconCheck = true;
                    }
                    if (iconCheck) {
                      for (var k in data) {
                        if (k.imageName!.split('\\').last.trim() == fileName) {
                          syncD = k.syncedDate ?? "";
                        }
                      }
                    }

                    return InkWell(
                      onTap: () {
                        currentItem.path!
                                    .split('/')
                                    .last
                                    .toLowerCase()
                                    .contains('png') ||
                                currentItem.path!
                                    .split('/')
                                    .last
                                    .toLowerCase()
                                    .contains('jpg') ||
                                currentItem.path!
                                    .split('/')
                                    .last
                                    .toLowerCase()
                                    .contains('jpeg')
                            ? Navigator.of(context).pushNamed(
                                PageRouter.photoViewImage,
                                arguments: {
                                    "image": File(currentItem.path ?? "")
                                  })
                            : Navigator.of(context).pushNamed(
                                PageRouter.androidaddImagePage,
                                arguments: {
                                    "projName": widget.projName,
                                    "folderName": Platform.isWindows
                                        ? currentItem.path!.split('\\').last
                                        : currentItem.path!.split('/').last,
                                  });
                      },
                      child: Card(
                        color: whiteColor,
                        child: Column(
                          children: [
                            (Platform.isAndroid &&
                                        iconCheck &&
                                        currentItem.path!
                                            .split('/')
                                            .last
                                            .toLowerCase()
                                            .contains('png')) ||
                                    (Platform.isAndroid &&
                                        iconCheck &&
                                        currentItem.path!
                                            .split('/')
                                            .last
                                            .toLowerCase()
                                            .contains('jpg')) ||
                                    (Platform.isAndroid &&
                                        iconCheck &&
                                        currentItem.path!
                                            .split('/')
                                            .last
                                            .toLowerCase()
                                            .contains('jpeg'))
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        syncD != ""
                                            ? dFormat
                                                .format(DateTime.parse(syncD))
                                            : "",
                                        style:
                                            body3.copyWith(color: Colors.grey),
                                      ),
                                      Sizing.spacingWidth,
                                      Padding(
                                        padding: EdgeInsets.only(
                                            right: Sizing.width(4, 5),
                                            top: Sizing().height(1, 1)),
                                        child: Align(
                                            alignment: Alignment.centerRight,
                                            child: CircleAvatar(
                                                radius: Sizing.getScreenWidth(
                                                                context) >
                                                            1000 &&
                                                        !Platform.isWindows
                                                    ? 15
                                                    : 10,
                                                backgroundColor: Colors.green,
                                                child: Icon(
                                                  Icons.sync,
                                                  color: whiteColor,
                                                  size: Sizing.getScreenWidth(
                                                                  context) >
                                                              1000 &&
                                                          !Platform.isWindows
                                                      ? 20
                                                      : Sizing().height(10, 5),
                                                ))),
                                      )
                                    ],
                                  )
                                : SizedBox(),
                            ListTile(
                              leading: currentItem.path!
                                          .split('/')
                                          .last
                                          .toLowerCase()
                                          .contains('png') ||
                                      currentItem.path!
                                          .split('/')
                                          .last
                                          .toLowerCase()
                                          .contains('jpg') ||
                                      currentItem.path!
                                          .split('/')
                                          .last
                                          .toLowerCase()
                                          .contains('jpeg')
                                  ? Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: Sizing.width(5, 7),
                                          vertical: Sizing().height(5, 1)),
                                      child: Image.file(
                                        File(currentItem.path!),
                                        height: Sizing().height(50, 15),
                                      ),
                                    )
                                  : Icon(
                                      Icons.business_center,
                                      color: Colors.yellow[600],
                                      size: Platform.isAndroid
                                          ? Sizing.getScreenWidth(context) >
                                                  1000
                                              ? 40
                                              : Sizing().height(30, 35)
                                          : 30,
                                    ),
                              title: Text(
                                Platform.isWindows
                                    ? currentItem.path!.split('\\').last
                                    : currentItem.path!.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(fontSize: 20)
                                    : const TextStyle(),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  currentItem.path!
                                              .split('/')
                                              .last
                                              .toLowerCase()
                                              .contains('png') ||
                                          currentItem.path!
                                              .split('/')
                                              .last
                                              .toLowerCase()
                                              .contains('jpg') ||
                                          currentItem.path!
                                              .split('/')
                                              .last
                                              .toLowerCase()
                                              .contains('jpeg')
                                      ? SizedBox()
                                      : IconButton(
                                          tooltip: 'Rename folder',
                                          onPressed: () async {
                                            res = await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AddSubFolder(
                                                    projName: widget.projName,
                                                    subFolName: currentItem
                                                        .path!
                                                        .split('/')
                                                        .last,
                                                    isEdit: true,
                                                    dirFolderName:
                                                        dirFolderName,
                                                  );
                                                });

                                            if (res == true) {
                                              getSubFolders();
                                              setState(() {});
                                            } else {
                                              res = false;
                                            }
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            size:
                                                Sizing.getScreenWidth(context) >
                                                            1000 &&
                                                        !Platform.isWindows
                                                    ? 25
                                                    : Sizing().height(20, 4),
                                          )),
                                  IconButton(
                                    tooltip: "Delete Folder",
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
                                                    style: Platform.isWindows
                                                        ? body3
                                                        : subtitle1,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        Sizing().height(8, 6),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          vertical: Sizing()
                                                              .height(1, 1),
                                                          horizontal:
                                                              Sizing.width(
                                                                  2, 3),
                                                        ),
                                                        decoration: BoxDecoration(
                                                            color: greyColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        2)),
                                                        child: TextButton(
                                                            onPressed:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              'No',
                                                              style: TextStyle(
                                                                  fontSize: Platform
                                                                          .isWindows
                                                                      ? Sizing()
                                                                          .height(
                                                                              2,
                                                                              3)
                                                                      : 12,
                                                                  color:
                                                                      whiteColor),
                                                            )),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            left: Sizing.width(
                                                                2, 2)),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          vertical: Sizing()
                                                              .height(1, 1),
                                                          horizontal:
                                                              Sizing.width(
                                                                  2, 3),
                                                        ),
                                                        decoration: BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        2)),
                                                        child: TextButton(
                                                            onPressed:
                                                                () async {
                                                              try {
                                                                String subFolName = Platform
                                                                        .isWindows
                                                                    ? currentItem
                                                                        .path!
                                                                        .split(
                                                                            '\\')
                                                                        .last
                                                                    : currentItem
                                                                        .path!
                                                                        .split(
                                                                            '/')
                                                                        .last;
                                                                Directory
                                                                    directory =
                                                                    await FileMethods
                                                                        .getSaveDirectory();

                                                                if (currentItem.path!.split('/').last.toLowerCase().contains('png') ||
                                                                    currentItem
                                                                        .path!
                                                                        .split(
                                                                            '/')
                                                                        .last
                                                                        .toLowerCase()
                                                                        .contains(
                                                                            'jpg') ||
                                                                    currentItem
                                                                        .path!
                                                                        .split(
                                                                            '/')
                                                                        .last
                                                                        .toLowerCase()
                                                                        .contains(
                                                                            'jpeg')) {
                                                                  Directory
                                                                      newDirectory =
                                                                      Directory(
                                                                          '${directory.path}/$dirFolderName/${widget.projName}/$subFolName');
                                                                  File
                                                                      imageFile =
                                                                      File(
                                                                          '${newDirectory.path}');
                                                                  if (await imageFile
                                                                      .exists()) {
                                                                    await imageFile
                                                                        .delete();
                                                                  }

                                                                  //Delete the photoSyncImageFile in photoSyncFolderDir
                                                                  Directory
                                                                      photoSyncFolderDir =
                                                                      Directory(
                                                                          '${directory.path}/$dirFolderName/PhotoSync/${widget.projName}/$subFolName');
                                                                  File
                                                                      photoSyncImageFile =
                                                                      File(
                                                                          '${photoSyncFolderDir.path}');
                                                                  if (await photoSyncImageFile
                                                                      .exists()) {
                                                                    await photoSyncImageFile.delete(
                                                                        recursive:
                                                                            true);
                                                                  }
                                                                  //Delete the photoSyncImageFile in photoSyncFolderDir
                                                                } else {
                                                                  Directory
                                                                      newDirectory =
                                                                      Directory(
                                                                          '${directory.path}/$dirFolderName/${widget.projName}/$subFolName');
                                                                  if (await newDirectory
                                                                      .exists()) {
                                                                    await newDirectory.delete(
                                                                        recursive:
                                                                            true);
                                                                  }

                                                                  //Delete the subFolder in photoSyncFolderDir
                                                                  Directory
                                                                      photoSyncFolderDir =
                                                                      Directory(
                                                                          '${directory.path}/$dirFolderName/PhotoSync/${widget.projName}/$subFolName');
                                                                  if (await photoSyncFolderDir
                                                                      .exists()) {
                                                                    await photoSyncFolderDir.delete(
                                                                        recursive:
                                                                            true);
                                                                  }
                                                                  //Delete the subFolder in photoSyncFolderDir
                                                                }

                                                                setState(() {
                                                                  session.deletedSubFolder =
                                                                      subFolName;
                                                                  session
                                                                      .newAddedSubFol
                                                                      .removeWhere((element) =>
                                                                          element
                                                                              .path ==
                                                                          subFolName);
                                                                  getSubFolders();
                                                                });

                                                                Navigator.pop(
                                                                    context);
                                                                CherryToast.success(
                                                                        title: Text(
                                                                          "Deleted successfully",
                                                                          style:
                                                                              TextStyle(fontSize: Sizing().height(9, 3)),
                                                                        ),
                                                                        autoDismiss: false)
                                                                    .show(context);
                                                              } on Exception catch (e) {
                                                                errorLog.add(ErrorLogModel(
                                                                    errorDescription: e
                                                                        .toString(),
                                                                    duration: DateTime
                                                                            .now()
                                                                        .toString()));
                                                                errorLogService
                                                                    .saveErrorLog(
                                                                        errorLog);
                                                              }
                                                            },
                                                            child: Text(
                                                              'Yes',
                                                              style: TextStyle(
                                                                  fontSize: Platform
                                                                          .isWindows
                                                                      ? Sizing()
                                                                          .height(
                                                                              2,
                                                                              3)
                                                                      : 12,
                                                                  color:
                                                                      whiteColor),
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
                                      size: Platform.isAndroid
                                          ? Sizing.getScreenWidth(context) >
                                                  1000
                                              ? 35
                                              : Sizing().height(18, 20)
                                          : 25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
            ],
          )
        : SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: Text(
              'No data',
              style: subtitle3,
              textAlign: TextAlign.center,
            )),
          );
    return x;
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
        title: Text(
          'Add Subfolder',
          style: Platform.isWindows
              ? body2
              : Sizing.getScreenWidth(context) > 1000
                  ? subtitle3
                  : subtitle1,
        ),
        content: SingleChildScrollView(
          child: Column(
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
                          'No.of subfolder is required',
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
      maxLength: 18,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Subfolder Name',
          labelStyle:
              TextStyle(color: Colors.grey, fontSize: Sizing().height(10, 3))),
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
          labelText: 'No.of Subfolder',
          labelStyle:
              TextStyle(color: Colors.grey, fontSize: Sizing().height(10, 3))),
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
        Directory? newSubDirectory;
        Directory directory = await FileMethods.getSaveDirectory();
        newDirectory = Directory('${directory.path}${widget.dirFolderName}');

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
            }
            //create photoSyncFolderDir in PhotoApp
            Directory photoSyncFolderDir = Directory(
                '${directory.path}/${widget.dirFolderName}/PhotoSync');

            if (!await photoSyncFolderDir.exists()) {
              await photoSyncFolderDir.create(recursive: true);
            }
            //create photoSyncFolderDir in PhotoApp

            //create project in photoSyncFolder
            Directory newSyncDirectory =
                Directory('${photoSyncFolderDir.path}/${widget.projName}');
            await checkExists(newSyncDirectory);
            for (int i = 1; i <= int.parse(_folderCount.text); i++) {
              newSubDirectory =
                  Directory('${newSyncDirectory.path}/${subFolderName}_$i');
              await checkExists(newSubDirectory);
            }
            //create project in photoSyncFolder
          } else {
            setState(() {
              projExists = true;
            });
          }
          if (newDirectory != null) {
            session.newAddedSubFol.add(DirectoryInfo(
                path: newDirectory.path.split('/').last,
                modifiedDate: DateTime.now().toString()));
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

            //create photoSyncFolderDir in PhotoApp
            Directory photoSyncFolderDir = Directory(
                '${directory.path}/${widget.dirFolderName}/PhotoSync');

            if (!await photoSyncFolderDir.exists()) {
              await photoSyncFolderDir.create(recursive: true);
            }
            //create photoSyncFolderDir in PhotoApp

            //Edit / create subfolder in photoSyncFolder
            Directory oldSyncDirectory = Directory(
                '${photoSyncFolderDir.path}/${widget.projName}/${widget.subFolName}');
            newSubDirectory = Directory(
                '${photoSyncFolderDir.path}/${widget.projName}/$subFolderName');

            if (oldSyncDirectory.existsSync()) {
              oldSyncDirectory.renameSync(newSubDirectory.path);
            } else {
              //create subfolder in photoSyncFolder
              await checkExists(newSubDirectory);
            }

            //Edit / create subfolder in photoSyncFolder
          }
        }

        Navigator.of(context).pushNamed(PageRouter.androidSubFolderPage,
            arguments: {
              "projName": widget.projName
            }).then((value) => setState(() {}));
      }
    } on Exception catch (e) {
      rethrow;
    }
  }
}
