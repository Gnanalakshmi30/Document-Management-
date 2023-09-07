// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:USB_Share/AddImage/Model/addImage_model.dart';
import 'package:USB_Share/AddImage/Page/watermark_page.dart';
import 'package:USB_Share/AddImage/Service/add_Image_service.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';
import 'package:intl/intl.dart';

class AndroidaddImagePage extends StatefulWidget {
  final String? projName;
  final String? folderName;
  final bool? isNewImageAdded;
  const AndroidaddImagePage(
      {super.key, this.folderName, this.projName, this.isNewImageAdded});

  @override
  State<AndroidaddImagePage> createState() => _AndroidaddImagePageState();
}

class _AndroidaddImagePageState extends State<AndroidaddImagePage> {
  File? galleryPicked;
  File? cameraPicked;
  List<FileSystemEntity> entities = [];
  List<FileSystemEntity> waterMarkEntities = [];
  List<FileSystemEntity> compressedEntities = [];
  String? gImg;
  bool loading = true;
  WidgetsToImageController controller = WidgetsToImageController();
  Uint8List? bytes;
  File? croppedResultImg;
  int? tabIndex;
  final imageService = ImageService();
  List<ImageLogModel> imglogData = [];
  List<ImageLogModel> finalImageList = [];
  List<String> fileNameLog = [];
  Map<int, String> imgLogData = {};
  var dFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String dirFolderName = "";

  getImageLogData() async {
    String? imgN;
    var res = await imageService.getImageLog();
    setState(() {
      imglogData = res;
    });
    int count = 0;
    for (var element in res) {
      if ((element.imageName ?? "").contains(widget.folderName ?? '')) {
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

  getSubFoldersImgList() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory(
        '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/Original');

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

  getSubFoldersWaterMarkImgList() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory(
        '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/WaterMark');

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
      waterMarkEntities = await dir.list().toList();
      var data = waterMarkEntities.reversed.toList();
      if (mounted) {
        setState(() {
          waterMarkEntities = data;
          loading = false;
        });
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  getSubFoldersCompressedImgList() async {
    Directory directory = await FileMethods.getSaveDirectory();
    final dir = Directory(
        '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/Compressed');

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
      compressedEntities = await dir.list().toList();
      var data = compressedEntities.reversed.toList();
      if (mounted) {
        setState(() {
          compressedEntities = data;
          loading = false;
        });
      }
    } on Exception catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getSubFoldersImgList();
    getSubFoldersWaterMarkImgList();
    getSubFoldersCompressedImgList();
    getImageLogData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: SafeArea(
          child: Scaffold(
        appBar: appBar(),
        body: WillPopScope(
          onWillPop: () async => false,
          child: TabBarView(
            children: [
              loading
                  ? CommonUi().showLoading()
                  : Padding(
                      padding: Sizing.horizontalPadding, child: imgListView()),
              loading
                  ? CommonUi().showLoading()
                  : Padding(
                      padding: Sizing.horizontalPadding,
                      child: waterMarkImgListView()),
              loading
                  ? CommonUi().showLoading()
                  : Padding(
                      padding: Sizing.horizontalPadding,
                      child: compressedImgListView()),
            ],
          ),
        ),
      )),
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: primaryColor,
      title: Text(
        widget.folderName ?? '',
        style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
            ? const TextStyle(fontSize: 25)
            : const TextStyle(),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: whiteColor,
          size: Platform.isAndroid
              ? Sizing.getScreenWidth(context) > 1000
                  ? 30
                  : Sizing().height(20, 20)
              : 30,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(PageRouter.androidSubFolderPage,
              arguments: {"projName": widget.projName});
        },
      ),
      bottom: TabBar(
        onTap: (value) {
          tabIndex = value;
        },
        indicatorColor: primaryColor,
        tabs: const [
          Tab(
            text: "Original",
          ),
          Tab(
            text: "Watermark",
          ),
          Tab(
            text: "Compressed",
          ),
        ],
        labelColor: primaryColor,
        unselectedLabelColor: whiteColor,
        labelStyle: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
            ? const TextStyle(fontSize: 25)
            : const TextStyle(),

        // add it here
        indicator: RectangularIndicator(
          verticalPadding: 3,
          horizontalPadding: 3,
          color: whiteColor,
          paintingStyle: PaintingStyle.fill,
        ),
      ),
      actions: [
        Platform.isWindows
            ? const SizedBox()
            : Padding(
                padding: Sizing.horizontalPadding,
                child: IconButton(
                  icon: Icon(
                    Icons.add_a_photo,
                    size: Platform.isAndroid
                        ? Sizing.getScreenWidth(context) > 1000
                            ? 40
                            : Sizing().height(20, 20)
                        : 30,
                  ),
                  onPressed: () {
                    cameraPicker();
                  },
                ),
              ),
        Platform.isWindows
            ? const SizedBox()
            : Padding(
                padding: Sizing.horizontalPadding,
                child: IconButton(
                  icon: Icon(
                    Icons.add_photo_alternate,
                    size: Platform.isAndroid
                        ? Sizing.getScreenWidth(context) > 1000
                            ? 40
                            : Sizing().height(20, 20)
                        : 30,
                  ),
                  onPressed: () {
                    galleryPicker();
                  },
                ),
              ),
      ],
    );
  }

  galleryPicker() async {
    try {
      if (Platform.isAndroid) {
        final image =
            await ImagePicker().pickImage(source: ImageSource.gallery);
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
      } else if (Platform.isWindows) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png'],
        );
        final bytes = result!.files.first.bytes;
        final fileName = result.files.first.name;
        final xfile = await XFile.fromData(bytes!, name: fileName);
        if (xfile == null) return;
        final galleryImg = File(xfile.path);
        setState(() {
          galleryPicked = galleryImg;
        });

        await cropImage(galleryImg);
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

  pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['jpg', 'png', 'gif'],
    );
    if (result != null) {
      File file = File((result.files.single.path) ?? '');
      await cropImage(file);
      final bytes = await croppedResultImg!.readAsBytes();
      final imgByte = Uint8List.fromList(bytes);
      saveImage(croppedResultImg!.path, imgByte, croppedResultImg!);
    } else {
      // User canceled the picker
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
      // getSubFoldersImgList();

      Navigator.of(context)
          .pushNamed(PageRouter.androidViewWaterMark, arguments: {
        "projName": widget.projName,
        "image": img,
        "folderName": widget.folderName,
        "isWithoutSubfolder": false,
      });
    } on Exception catch (e) {
      rethrow;
    }
  }

  Widget addWaterMarkDesign(File img) {
    return SizedBox(
      height: Sizing().height(300, 400),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.file(
              img,
              height: Sizing().height(200, 250),
              fit: BoxFit.fill,
            ),
            Sizing.spacingHeight,
            Flexible(
              child: Stack(
                children: [
                  Positioned(
                    child: WaterMark(
                        columnCount: 5,
                        rowCount: 8,
                        text: "${widget.projName}"),
                  ),
                  Positioned(
                      left: 140,
                      top: 15,
                      child: Text(
                        "${widget.projName}",
                        style: title1,
                      ))
                ],
              ),
            ),
            Sizing.spacingHeight,
          ],
        ),
      ),
    );
  }

  imgListView() {
    bool iconCheck = false;
    late String syncD;
    var x = entities.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: entities.length,
            itemBuilder: (context, index) {
              syncD = "";
              final currentItem = entities[index];
              var fileName = Platform.isWindows
                  ? currentItem.path.split('\\').last
                  : currentItem.path.split('/').last;
              var data = finalImageList.where(
                  (j) => j.imageName!.split('\\').last.trim() == fileName);

              if (data.isNotEmpty) {
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
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path)});
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.width(0, 10),
                      vertical: Sizing().height(2, 2)),
                  child: Card(
                    color: whiteColor,
                    child: Column(
                      children: [
                        Platform.isAndroid && iconCheck
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    syncD != ""
                                        ? dFormat.format(DateTime.parse(syncD))
                                        : "",
                                    style: body3.copyWith(color: Colors.grey),
                                  ),
                                  Sizing.spacingWidth,
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: Sizing.width(4, 5),
                                        top: Sizing().height(1, 1)),
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: CircleAvatar(
                                            radius:
                                                Sizing.getScreenWidth(context) >
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
                        Row(
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: Sizing.width(5, 7),
                                    vertical: Sizing().height(5, 1)),
                                child: Image.file(
                                  File(currentItem.path),
                                  height: Sizing().height(50, 15),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                Platform.isWindows
                                    ? currentItem.path.split('\\').last
                                    : currentItem.path.split('/').last,
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(fontSize: 20)
                                    : const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
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

  waterMarkImgListView() {
    late String syncD;
    bool iconCheck = false;
    var x = waterMarkEntities.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: waterMarkEntities.length,
            itemBuilder: (context, index) {
              syncD = "";
              final currentItem = waterMarkEntities[index];
              String fileName = Platform.isWindows
                  ? currentItem.path.split('\\').last
                  : currentItem.path.split('/').last;
              var data = finalImageList.where(
                  (j) => j.imageName!.split('\\').last.trim() == fileName);

              if (data.isNotEmpty) {
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
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path)});
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.width(0, 10),
                      vertical: Sizing().height(2, 2)),
                  child: Card(
                    color: whiteColor,
                    child: Column(
                      children: [
                        Platform.isAndroid && iconCheck
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    syncD != ""
                                        ? dFormat.format(DateTime.parse(syncD))
                                        : "",
                                    style: body3.copyWith(color: Colors.grey),
                                  ),
                                  Sizing.spacingWidth,
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: Sizing.width(4, 5),
                                        top: Sizing().height(1, 1)),
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: CircleAvatar(
                                            radius:
                                                Sizing.getScreenWidth(context) >
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
                        Row(
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: Sizing.width(5, 7),
                                    vertical: Sizing().height(5, 1)),
                                child: Image.file(
                                  File(currentItem.path),
                                  height: Sizing().height(50, 15),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                Platform.isWindows
                                    ? currentItem.path.split('\\').last
                                    : currentItem.path.split('/').last,
                                style: Sizing.getScreenWidth(context) > 1000 &&
                                        !Platform.isWindows
                                    ? const TextStyle(fontSize: 20)
                                    : const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
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

  compressedImgListView() {
    late String syncD;
    bool iconCheck = false;
    var x = compressedEntities.isNotEmpty
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: compressedEntities.length,
            itemBuilder: (context, index) {
              syncD = "";
              final currentItem = compressedEntities[index];
              String fileName = Platform.isWindows
                  ? currentItem.path.split('\\').last
                  : currentItem.path.split('/').last;

              var data = finalImageList.where(
                  (j) => j.imageName!.split('\\').last.trim() == fileName);

              if (data.isNotEmpty) {
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
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path)});
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Sizing.width(0, 10),
                      vertical: Sizing().height(2, 2)),
                  child: Card(
                    color: whiteColor,
                    child: Column(
                      children: [
                        Platform.isAndroid && iconCheck
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    syncD != ""
                                        ? dFormat.format(DateTime.parse(syncD))
                                        : "",
                                    style: body3.copyWith(color: Colors.grey),
                                  ),
                                  Sizing.spacingWidth,
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: Sizing.width(4, 5),
                                        top: Sizing().height(1, 1)),
                                    child: Align(
                                        alignment: Alignment.centerRight,
                                        child: CircleAvatar(
                                            radius:
                                                Sizing.getScreenWidth(context) >
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
                        Row(
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: Sizing.width(5, 7),
                                    vertical: Sizing().height(5, 1)),
                                child: Image.file(
                                  File(currentItem.path),
                                  height: Sizing().height(50, 15),
                                ),
                              ),
                            ),
                            Expanded(
                                child: Text(
                              Platform.isWindows
                                  ? currentItem.path.split('\\').last
                                  : currentItem.path.split('/').last,
                              style: Sizing.getScreenWidth(context) > 1000 &&
                                      !Platform.isWindows
                                  ? const TextStyle(fontSize: 20)
                                  : const TextStyle(),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
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
}
