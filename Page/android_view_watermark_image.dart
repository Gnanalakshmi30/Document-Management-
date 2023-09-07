// ignore_for_file: prefer_const_constructors, prefer_final_fields, unused_import

import 'dart:io';
import 'package:USB_Share/Configuration/Model/saveCreatedDate_model.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:USB_Share/AddImage/Page/watermark_page.dart';
import 'package:USB_Share/Configuration/Model/config_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/Util/styles.dart';

class AndroidViewWaterMark extends StatefulWidget {
  final String? projName;
  final File image;
  final String? folderName;
  final bool? isWithoutSubfolder;
  const AndroidViewWaterMark(
      {super.key,
      this.projName,
      required this.image,
      this.folderName,
      this.isWithoutSubfolder});

  @override
  State<AndroidViewWaterMark> createState() => _AndroidViewWaterMarkState();
}

class _AndroidViewWaterMarkState extends State<AndroidViewWaterMark> {
  ScreenshotController screenshotController = ScreenshotController();
  TextEditingController captionController = TextEditingController();
  Uint8List? screenshotImage;
  File? wImg;
  File? cImg;
  final configurationService = ConfigurationService();
  List<ConfigurationModel> configData = [];

  List<String> _dropdownItems = [
    'Top',
    'Bottom',
  ];
  String? _selectedItem = "Bottom";
  List<String> suggestions = [
    'Top',
    'Right',
    'Left',
    'Bottom-Center',
    'Bottom-Left',
    'Bottom-Right'
  ];
  String? selectedSuggestion;
  String dirFolderName = "";

  getConfigData() async {
    var res = await configurationService.getConfiguration();
    setState(() {
      res.removeAt(0);
      configData = res;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getConfigData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: blackColor,
        appBar: appBar(),
        body: WillPopScope(
          onWillPop: () async => false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                Sizing.spacingHeight,
                _selectedItem == 'Bottom'
                    ? convertScreenToImageBottom()
                    : convertScreenToImageTop(),
                Sizing.getScreenWidth(context) > 1000
                    ? SizedBox()
                    : Sizing.spacingHeight,
                Sizing.getScreenWidth(context) > 1000
                    ? SizedBox()
                    : Sizing.spacingHeight,
                Sizing.getScreenWidth(context) > 1000
                    ? SizedBox()
                    : Sizing.spacingHeight,
                Sizing.spacingHeight,
                captionBox(),
                Sizing.getScreenWidth(context) > 1000
                    ? Sizing.spacingHeight
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: primaryColor,
      automaticallyImplyLeading: true,
      title: Text(_selectedItem ?? '',
          style: TextStyle(
              fontSize: Sizing.getScreenWidth(context) > 1000
                  ? 25
                  : Sizing().height(15, 15))),
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
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.done,
            size: Platform.isAndroid
                ? Sizing.getScreenWidth(context) > 1000
                    ? 40
                    : Sizing().height(20, 20)
                : 30,
          ),
          onPressed: () async {
            try {
              if (captionController.text != "") {
                CommonUi().showLoadingDialog(context);
                final image = await screenshotController.captureFromWidget(
                    _selectedItem == 'Bottom'
                        ? convertScreenToImageBottom()
                        : convertScreenToImageTop());
                setState(() {
                  screenshotImage = image;
                });
                await imgToFile(screenshotImage!);
                await compressFile();
                saveToDirectory();
              } else {
                CherryToast.error(
                        title: Text(
                          "Please enter caption",
                          style: TextStyle(fontSize: Sizing().height(9, 3)),
                        ),
                        autoDismiss: true)
                    .show(context);
              }
            } on Exception catch (e) {
              rethrow;
            }
          },
        ),
        PopupMenuButton<String>(
          iconSize: Platform.isAndroid
              ? Sizing.getScreenWidth(context) > 1000
                  ? 40
                  : Sizing().height(20, 20)
              : 30,
          onSelected: (String result) {
            setState(() {
              _selectedItem = result;
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: _dropdownItems[0],
              child: Text('Top'),
            ),
            PopupMenuItem<String>(
              value: _dropdownItems[1],
              child: Text('Bottom'),
            ),
          ],
        ),
      ],
    );
  }

  captionBox() {
    captionController.selection =
        TextSelection.collapsed(offset: captionController.text.length);
    return Container(
      padding: EdgeInsets.only(left: Sizing().height(3, 3)),
      decoration: BoxDecoration(
          color: Colors.grey[800], borderRadius: BorderRadius.circular(20)),
      child: TextFormField(
        style: subtitle2.copyWith(color: whiteColor),
        cursorColor: whiteColor,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.only(top: 18),
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                  bottom: Sizing.getScreenWidth(context) > 1000
                      ? 0
                      : Sizing().height(5, 5)),
              child: Icon(
                Icons.add_photo_alternate,
                color: whiteColor,
                size: Platform.isAndroid
                    ? Sizing.getScreenWidth(context) > 1000
                        ? 30
                        : Sizing().height(20, 20)
                    : 30,
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: Sizing.width(5, 5)),
              child: DropdownButton<String>(
                iconSize: Platform.isAndroid
                    ? Sizing.getScreenWidth(context) > 1000
                        ? 30
                        : Sizing().height(20, 20)
                    : 30,
                iconEnabledColor: whiteColor,
                underline: SizedBox(),
                onChanged: (value) {
                  captionController.text = value ?? '';
                },
                value: selectedSuggestion,
                items: configData.map((ConfigurationModel value) {
                  return DropdownMenuItem<String>(
                    value: value.captionName.toString(),
                    child: Text(value.captionName.toString()),
                  );
                }).toList(),
              ),
            ),
            hintText: 'Add a caption...',
            hintStyle: Sizing.getScreenWidth(context) > 1000
                ? subtitle3.copyWith(color: greyColor)
                : subtitle1.copyWith(color: greyColor)),
        onChanged: (val) {},
        controller: captionController,
      ),
    );
  }

  convertScreenToImageBottom() {
    int count = 8;
    if ((widget.projName ?? "").length < 10) {
      count = 8;
    } else if ((widget.projName ?? "").length == 10) {
      count = 5;
    } else if ((widget.projName ?? "").length > 10) {
      count = 3;
    }

    return SizedBox(
      // height: Sizing.getScreenWidth(context) > 1000
      //     ? Sizing().height(500, 500)
      //     : Sizing().height(300, 400),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              widget.image,
              width: double.infinity,
              fit: session.selectedWidth < 3000 ? BoxFit.fill : BoxFit.contain,
            ),
            Sizing.spacingHeight,
            SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Positioned(
                      child: WaterMark(
                          columnCount: 4,
                          rowCount: count,
                          text: "${widget.projName}"),
                    ),
                    Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "${widget.projName}",
                            style: title1,
                          ),
                        ))
                  ],
                )),
            Sizing.spacingHeight,
          ],
        ),
      ),
    );
  }

  convertScreenToImageTop() {
    int count = 8;
    if ((widget.projName ?? "").length < 10) {
      count = 8;
    } else if ((widget.projName ?? "").length == 10) {
      count = 5;
    } else if ((widget.projName ?? "").length > 10) {
      count = 3;
    }

    return SizedBox(
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Sizing.spacingHeight,
              SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Positioned(
                      child: WaterMark(
                          columnCount: 4,
                          rowCount: count,
                          text: "${widget.projName}"),
                    ),
                    Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "${widget.projName}",
                            style: title1,
                          ),
                        ))
                  ],
                ),
              ),
              Sizing.spacingHeight,
              Image.file(
                widget.image,
                width: double.infinity,
                fit:
                    session.selectedWidth < 3000 ? BoxFit.fill : BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  imgToFile(List<int> img) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    Directory directory = Directory('$tempPath/tempfile');
    await directory.create(recursive: true);
    File file = File('$tempPath/tempfile/tempfile.png');
    Uint8List bytesData = Uint8List.fromList(img);
    await file.writeAsBytes(bytesData);
    wImg = file;
    return file;
  }

  Future<File?> compressFile() async {
    final result = await FlutterImageCompress.compressWithFile(
      wImg!.path,
      quality: 50,
    );
    final compressedFile = await wImg!.writeAsBytes(result!);
    cImg = compressedFile;
    return compressedFile;
  }

  saveToDirectory() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      DateTime now = DateTime.now();
      String currentDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      Directory? newDirectory;
      Directory directory = await FileMethods.getSaveDirectory();

      //create photoSyncFolderDir in PhotoApp
      Directory photoSyncFolderDir =
          Directory('${directory.path}/$dirFolderName/PhotoSync');

      if (!await photoSyncFolderDir.exists()) {
        await photoSyncFolderDir.create(recursive: true);
      }
      //create photoSyncFolderDir in PhotoApp

      if (widget.isWithoutSubfolder == false) {
        //save original image
        newDirectory = Directory(
            '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/Original');
        await newDirectory.create(recursive: true);

        File file = File(
            '${newDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_orginal_$timestamp.jpg');
        widget.image.copySync(file.path);

        //save watermark image
        newDirectory = Directory(
            '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/WaterMark');

        await newDirectory.create(recursive: true);

        File file1 = File(
            '${newDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_watermark_$timestamp.jpg');
        wImg!.copySync(file1.path);

        //save compressedWatermark image
        newDirectory = Directory(
            '${directory.path}$dirFolderName/${widget.projName}/${widget.folderName}/Compressed');

        await newDirectory.create(recursive: true);
        File cFile = File(
            '${newDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_compressed_$timestamp.jpg');
        cImg!.copySync(cFile.path);

        //save original image to photosync folder
        Directory newSyncDirectory = Directory(
            '${photoSyncFolderDir.path}/${widget.projName}/${widget.folderName}/Original');
        await newSyncDirectory.create(recursive: true);

        File filee = File(
            '${newSyncDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_orginal_$timestamp.jpg');
        widget.image.copySync(filee.path);

        //save watermark image to photosync folder
        Directory newWatermarkSyncDirectory = Directory(
            '${photoSyncFolderDir.path}/${widget.projName}/${widget.folderName}/WaterMark');

        await newWatermarkSyncDirectory.create(recursive: true);

        File filee1 = File(
            '${newWatermarkSyncDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_watermark_$timestamp.jpg');
        wImg!.copySync(filee1.path);

        //save compressedWatermark image to photosync folder
        Directory newCompressSyncDirectory = Directory(
            '${photoSyncFolderDir.path}/${widget.projName}/${widget.folderName}/Compressed');

        await newCompressSyncDirectory.create(recursive: true);
        File filee3 = File(
            '${newCompressSyncDirectory.path}/${widget.projName}_${widget.folderName}_${captionController.text}_compressed_$timestamp.jpg');
        cImg!.copySync(filee3.path);

        Navigator.pop(context);
        Navigator.of(context).pushNamedAndRemoveUntil(
            PageRouter.androidaddImagePage, (Route<dynamic> route) => false,
            arguments: {
              "projName": widget.projName,
              "folderName": widget.folderName,
              "isNewImageAdded": true,
            });
      } else if (widget.isWithoutSubfolder == true) {
        newDirectory =
            Directory('${directory.path}$dirFolderName/${widget.projName}');
        await newDirectory.create(recursive: true);

        Directory newSyncDirectory =
            Directory('${photoSyncFolderDir.path}/${widget.projName}');
        await newSyncDirectory.create(recursive: true);

        //save original image

        File file = File(
            '${newDirectory.path}/${widget.projName}_${captionController.text}_orginal_$timestamp.jpg');
        widget.image.copySync(file.path);

        //save watermark image

        File file1 = File(
            '${newDirectory.path}/${widget.projName}_${captionController.text}_watermark_$timestamp.jpg');
        wImg!.copySync(file1.path);

        //save compressedWatermark image

        File cFile = File(
            '${newDirectory.path}/${widget.projName}_${captionController.text}_compressed_$timestamp.jpg');
        cImg!.copySync(cFile.path);

        //save original image to photosync folder

        File filee = File(
            '${newSyncDirectory.path}/${widget.projName}_${captionController.text}_orginal_$timestamp.jpg');
        widget.image.copySync(filee.path);

        //save watermark image to photosync folder

        File filee1 = File(
            '${newSyncDirectory.path}/${widget.projName}_${captionController.text}_watermark_$timestamp.jpg');
        wImg!.copySync(filee1.path);

        //save compressedWatermark image to photosync folder

        File filee3 = File(
            '${newSyncDirectory.path}/${widget.projName}_${captionController.text}_compressed_$timestamp.jpg');
        cImg!.copySync(filee3.path);

        Navigator.pop(context);

        Navigator.of(context).pushReplacementNamed(
            PageRouter.androidSubFolderPage,
            arguments: {"projName": widget.projName});
      }
    } on Exception catch (e) {
      rethrow;
    }
  }
}
