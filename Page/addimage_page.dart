// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:USB_Share/Project/Model/projectModel.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_cropping/image_cropping.dart' as winCropper;
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';

class AddImagePage extends StatefulWidget {
  final String? projName;
  final String? folderName;
  final bool? isNewImageAdded;
  const AddImagePage(
      {super.key, this.folderName, this.projName, this.isNewImageAdded});

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
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
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  List<DirectoryInfo> originalDirectoryInfo = [];
  List<DirectoryInfo> waterMarkDirectoryInfo = [];
  List<DirectoryInfo> compressedDirectoryInfo = [];
  Uint8List? windowsImageBytes;
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
      originalDirectoryInfo = [];

      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in entities) {
          if (entity is File) {
            final stat = entity.statSync();
            final modifiedDate = stat.modified.toString();
            originalDirectoryInfo.add(
                DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
          }
        }
      }
      //Sort the directory by modified date
      originalDirectoryInfo.sort((a, b) {
        var bPath = Platform.isWindows
            ? (b.path ?? "").split('\\').last
            : (b.path ?? "").split('/').last;
        var aPath = Platform.isWindows
            ? (a.path ?? "").split('\\').last
            : (a.path ?? "").split('/').last;

        return aPath.compareTo(bPath);
      });
      if (mounted) {
        setState(() {
          originalDirectoryInfo = originalDirectoryInfo;
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

      waterMarkDirectoryInfo = [];

      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in waterMarkEntities) {
          if (entity is File) {
            final stat = entity.statSync();
            final modifiedDate = stat.modified.toString();
            waterMarkDirectoryInfo.add(
                DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
          }
        }
      }
      //Sort the directory by modified date
      waterMarkDirectoryInfo.sort((a, b) {
        var bPath = Platform.isWindows
            ? (b.path ?? "").split('\\').last
            : (b.path ?? "").split('/').last;
        var aPath = Platform.isWindows
            ? (a.path ?? "").split('\\').last
            : (a.path ?? "").split('/').last;

        return aPath.compareTo(bPath);
      });
      if (mounted) {
        setState(() {
          waterMarkDirectoryInfo = waterMarkDirectoryInfo;
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

      compressedDirectoryInfo = [];

      //create model with modified date
      if (dir.existsSync()) {
        for (final entity in compressedEntities) {
          if (entity is File) {
            final stat = entity.statSync();
            final modifiedDate = stat.modified.toString();
            compressedDirectoryInfo.add(
                DirectoryInfo(modifiedDate: modifiedDate, path: entity.path));
          }
        }
      }
      //Sort the directory by modified date
      compressedDirectoryInfo.sort((a, b) {
        var bPath = Platform.isWindows
            ? (b.path ?? "").split('\\').last
            : (b.path ?? "").split('/').last;
        var aPath = Platform.isWindows
            ? (a.path ?? "").split('\\').last
            : (a.path ?? "").split('/').last;

        return aPath.compareTo(bPath);
      });
      if (mounted) {
        setState(() {
          compressedDirectoryInfo = compressedDirectoryInfo;
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
                      padding: Sizing.horizontalPadding,
                      child: originalImageListView()),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(widget.folderName ?? '',
          style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
              ? TextStyle(fontSize: 17, color: primaryColor)
              : TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor)),
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
          Navigator.of(context).pushNamed(PageRouter.subFolderPage,
              arguments: {"projName": widget.projName});
        },
      ),
      bottom: TabBar(
        dividerColor: Colors.amber,
        padding: EdgeInsets.symmetric(
          horizontal: Sizing.width(100, 100),
        ),
        onTap: (value) {
          tabIndex = value;
        },
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
        labelColor: Colors.white,
        unselectedLabelColor: primaryColor,
        labelStyle: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
            ? TextStyle(fontSize: 12, color: Colors.white)
            : TextStyle(fontSize: 12, color: Colors.white),

        // add it here
        indicator: RectangularIndicator(
          verticalPadding: 3,
          horizontalPadding: 3,
          color: primaryColor,
          paintingStyle: PaintingStyle.fill,
        ),
      ),
      actions: [
        Platform.isWindows
            ? const SizedBox()
            : Tooltip(
                message: 'Capture image',
                child: InkWell(
                  onTap: () {
                    cameraPicker();
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: Sizing.width(3, 3),
                      vertical: Sizing().height(2, 3),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizing.width(3, 4),
                      vertical: Sizing().height(2, 1),
                    ),
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 107, 114, 169),
                        borderRadius: BorderRadius.circular(7)),
                    child: Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: Sizing.getScreenWidth(context) > 1000 &&
                              !Platform.isWindows
                          ? 25
                          : Sizing().height(20, 4),
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
          .pushNamed(PageRouter.viewWatermarkImage, arguments: {
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

  originalImageListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(
              // horizontal: Sizing.width(100, 90),
              vertical: Sizing().height(10, 10)),
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
                  3: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: originalImageTableView(),
              ),
              originalDirectoryInfo.length == 0
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
      ],
    );
  }

  originalImageTableView() {
    bool iconCheck = false;
    late String syncD;

    List<TableRow> originalImageList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Image name",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Last modified",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Platform.isAndroid
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Last synced",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              )
            : SizedBox(),
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

    if (originalDirectoryInfo.length > 0) {
      for (int i = 0; i < originalDirectoryInfo.length; i++) {
        syncD = "";
        final currentItem = originalDirectoryInfo[i];
        var fileName = Platform.isWindows
            ? currentItem.path!.split('\\').last
            : currentItem.path!.split('/').last;
        var data = finalImageList
            .where((j) => j.imageName!.split('\\').last.trim() == fileName);

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
        originalImageList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.image,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Text(
                    originalDirectoryInfo[i]
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
                Constants.modifiedDateFormat.format(DateTime.parse(
                    originalDirectoryInfo[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Platform.isAndroid
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                      syncD != "" ? dFormat.format(DateTime.parse(syncD)) : "",
                      style: TextStyle(fontSize: 12, color: Colors.black)),
                )
              : SizedBox(),
          Row(
            children: [
              IconButton(
                tooltip: "View image",
                onPressed: () {
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path ?? "")});
                },
                icon: Icon(
                  Icons.visibility,
                  color: Colors.blue,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              ),
              IconButton(
                  tooltip: 'Delete image',
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
                                              String imageName =
                                                  Platform.isWindows
                                                      ? originalDirectoryInfo[i]
                                                          .path!
                                                          .split('\\')
                                                          .last
                                                      : originalDirectoryInfo[i]
                                                          .path!
                                                          .split('/')
                                                          .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();
                                              Directory newDirectory = Directory(
                                                  '${directory.path}/$dirFolderName/${widget.projName}/${widget.folderName}/Original');
                                              File imageFile = File(
                                                  '${newDirectory.path}/$imageName');
                                              if (await imageFile.exists()) {
                                                await imageFile.delete();
                                              }

                                              setState(() {
                                                getSubFoldersImgList();
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
    return originalImageList;
  }

  waterMarkImgListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(
              // horizontal: Sizing.width(100, 90),
              vertical: Sizing().height(10, 10)),
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
                  3: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: waterMarkImageTableView(),
              ),
              waterMarkDirectoryInfo.length == 0
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
      ],
    );
  }

  waterMarkImageTableView() {
    bool iconCheck = false;
    late String syncD;

    List<TableRow> waterMarkImageList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Image name",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Last modified",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Platform.isAndroid
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Last synced",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              )
            : SizedBox(),
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

    if (waterMarkDirectoryInfo.length > 0) {
      for (int i = 0; i < waterMarkDirectoryInfo.length; i++) {
        syncD = "";
        final currentItem = waterMarkDirectoryInfo[i];
        var fileName = Platform.isWindows
            ? currentItem.path!.split('\\').last
            : currentItem.path!.split('/').last;
        var data = finalImageList
            .where((j) => j.imageName!.split('\\').last.trim() == fileName);

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
        waterMarkImageList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.image,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Text(
                    waterMarkDirectoryInfo[i]
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
                Constants.modifiedDateFormat.format(DateTime.parse(
                    waterMarkDirectoryInfo[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Platform.isAndroid
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                      syncD != "" ? dFormat.format(DateTime.parse(syncD)) : "",
                      style: TextStyle(fontSize: 12, color: Colors.black)),
                )
              : SizedBox(),
          Row(
            children: [
              IconButton(
                tooltip: "View image",
                onPressed: () {
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path ?? "")});
                },
                icon: Icon(
                  Icons.visibility,
                  color: Colors.blue,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              ),
              IconButton(
                  tooltip: 'Delete image',
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
                                              String imageName = Platform
                                                      .isWindows
                                                  ? waterMarkDirectoryInfo[i]
                                                      .path!
                                                      .split('\\')
                                                      .last
                                                  : waterMarkDirectoryInfo[i]
                                                      .path!
                                                      .split('/')
                                                      .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();
                                              Directory newDirectory = Directory(
                                                  '${directory.path}/$dirFolderName/${widget.projName}/${widget.folderName}/WaterMark');
                                              File imageFile = File(
                                                  '${newDirectory.path}/$imageName');
                                              if (await imageFile.exists()) {
                                                await imageFile.delete();
                                              }

                                              setState(() {
                                                getSubFoldersWaterMarkImgList();
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
    return waterMarkImageList;
  }

  compressedImgListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(
              // horizontal: Sizing.width(100, 90),
              vertical: Sizing().height(10, 10)),
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
                  3: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: compressedImageTableView(),
              ),
              compressedDirectoryInfo.length == 0
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
      ],
    );
  }

  compressedImageTableView() {
    bool iconCheck = false;
    late String syncD;

    List<TableRow> compressedImageList = [
      TableRow(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Image name",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Last modified",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        Platform.isAndroid
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Last synced",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              )
            : SizedBox(),
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

    if (compressedDirectoryInfo.length > 0) {
      for (int i = 0; i < compressedDirectoryInfo.length; i++) {
        syncD = "";
        final currentItem = compressedDirectoryInfo[i];
        var fileName = Platform.isWindows
            ? currentItem.path!.split('\\').last
            : currentItem.path!.split('/').last;
        var data = finalImageList
            .where((j) => j.imageName!.split('\\').last.trim() == fileName);

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
        compressedImageList.add(TableRow(children: [
          Row(
            children: [
              Icon(Icons.image,
                  color: primaryColor,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4)),
              Padding(
                padding: EdgeInsets.only(left: Sizing.width(2, 2)),
                child: Text(
                    compressedDirectoryInfo[i]
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
                Constants.modifiedDateFormat.format(DateTime.parse(
                    compressedDirectoryInfo[i].modifiedDate ?? "")),
                style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
          Platform.isAndroid
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                      syncD != "" ? dFormat.format(DateTime.parse(syncD)) : "",
                      style: TextStyle(fontSize: 12, color: Colors.black)),
                )
              : SizedBox(),
          Row(
            children: [
              IconButton(
                tooltip: "View image",
                onPressed: () {
                  Navigator.of(context).pushNamed(PageRouter.photoViewImage,
                      arguments: {"image": File(currentItem.path ?? "")});
                },
                icon: Icon(
                  Icons.visibility,
                  color: Colors.blue,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 4),
                ),
              ),
              IconButton(
                  tooltip: 'Delete image',
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
                                              String imageName = Platform
                                                      .isWindows
                                                  ? compressedDirectoryInfo[i]
                                                      .path!
                                                      .split('\\')
                                                      .last
                                                  : compressedDirectoryInfo[i]
                                                      .path!
                                                      .split('/')
                                                      .last;
                                              Directory directory =
                                                  await FileMethods
                                                      .getSaveDirectory();
                                              Directory newDirectory = Directory(
                                                  '${directory.path}/$dirFolderName/${widget.projName}/${widget.folderName}/Compressed');
                                              File imageFile = File(
                                                  '${newDirectory.path}/$imageName');
                                              if (await imageFile.exists()) {
                                                await imageFile.delete();
                                              }

                                              setState(() {
                                                getSubFoldersCompressedImgList();
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
    return compressedImageList;
  }
}
