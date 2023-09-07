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
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:image_size_getter/image_size_getter.dart';
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

class ViewWaterMark extends StatefulWidget {
  final String? projName;
  final File image;
  final String? folderName;
  final bool? isWithoutSubfolder;
  const ViewWaterMark(
      {super.key,
      this.projName,
      required this.image,
      this.folderName,
      this.isWithoutSubfolder});

  @override
  State<ViewWaterMark> createState() => _ViewWaterMarkState();
}

class _ViewWaterMarkState extends State<ViewWaterMark> {
  ScreenshotController screenshotController = ScreenshotController();
  TextEditingController captionController = TextEditingController();
  Uint8List? screenshotImage;
  File? wImg;
  File? cImg;
  final configurationService = ConfigurationService();
  List<ConfigurationModel> configData = [];
  int imgWidth = 0;
  String dirFolderName = "";

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
    getImgSize();
  }

  getImgSize() async {
    File image = widget.image;
    var decodedImage = await decodeImageFromList(image.readAsBytesSync());
    setState(() {
      imgWidth = decodedImage.width;
    });
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
                SizedBox(
                  height: Sizing().height(10, 10),
                ),
                _selectedItem == 'Bottom'
                    ? convertScreenToImageBottom()
                    : convertScreenToImageTop(),
                SizedBox(
                  height: Sizing().height(10, 10),
                ),
                captionBox(),
                SizedBox(
                  height: Sizing().height(10, 10),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: true,
      title: Text(_selectedItem ?? '',
          style: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
              ? TextStyle(fontSize: 17, color: whiteColor)
              : TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: whiteColor)),
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
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Save',
          icon: CircleAvatar(
            radius: 13,
            backgroundColor: primaryColor,
            child: Icon(Icons.done,
                color: Colors.white,
                size:
                    Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                        ? 25
                        : Sizing().height(20, 5)),
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

                await windowsImageCompress(screenshotImage!);
                saveToDirectory();
              } else {
                CherryToast.error(
                        title: Text(
                          "Please enter caption",
                          style: TextStyle(fontSize: Sizing().height(5, 3)),
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
          tooltip: 'Watermark position',
          iconSize: 20,
          onSelected: (String result) {
            setState(() {
              _selectedItem = result;
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: _dropdownItems[0],
              child: Text('Top',
                  style: TextStyle(fontSize: 13, color: blackColor)),
            ),
            PopupMenuItem<String>(
              value: _dropdownItems[1],
              child: Text('Bottom',
                  style: TextStyle(fontSize: 13, color: blackColor)),
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
      width: Sizing.width(300, 300),
      decoration: BoxDecoration(
          color: Colors.grey[800], borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(top: 3),
        child: TextFormField(
          style: TextStyle(fontSize: 13, color: whiteColor),
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
                  size: 20,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: Sizing.width(5, 5)),
                child: DropdownButton<String>(
                  iconSize: 20,
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
              hintStyle: TextStyle(fontSize: 13, color: greyColor)),
          onChanged: (val) {
            val = val;
          },
          controller: captionController,
        ),
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
      child: Card(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                widget.image,
              ),
              Container(
                  color: whiteColor,
                  height: 100,
                  width: double.parse(imgWidth.toString()),
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
            ],
          ),
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
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: whiteColor,
                height: 100,
                width: double.parse(session.selectedWidth.toString()),
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
              Image.file(
                widget.image,
                fit: BoxFit.contain,
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

  windowsImageCompress(Uint8List img) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      Directory directory = Directory('$tempPath/tempfile');
      await directory.create(recursive: true);
      File file = File('$tempPath/tempfile/tempfile.png');
      Uint8List bytesData = Uint8List.fromList(img);
      await file.writeAsBytes(bytesData);
      wImg = file;
      final input = ImageFile(
        rawBytes: file.readAsBytesSync(),
        filePath: file.path,
      );
      Configuration config = Configuration(
        outputType: ImageOutputType.webpThenJpg,
        // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
        useJpgPngNativeCompressor: false,
        // set quality between 0-100
        quality: 40,
      );

      final param = ImageFileConfiguration(input: input, config: config);
      ImageFile output = await compressor.compress(param);

      //convert ImageFile to File
      String tempImagPath = Directory.systemTemp.path;
      String tempImgFilePath = '$tempImagPath/compressedTemp_image.jpg';
      await File(tempImgFilePath).writeAsBytes(output.rawBytes);
      File comImgfile = File(tempImgFilePath);
      cImg = comImgfile;
    } on Exception catch (e) {
      rethrow;
    }
  }

  saveToDirectory() async {
    Directory dir = await FileMethods.getSaveDirectory();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      DateTime now = DateTime.now();
      String currentDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      Directory? newDirectory;
      Directory directory = await FileMethods.getSaveDirectory();

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

        String imgFileName = widget.image.path.split('$dirFolderName').last;

        File imageFile = File('${directory.path}$dirFolderName$imgFileName');
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        Navigator.pop(context);
        Navigator.of(context).pushNamedAndRemoveUntil(
            PageRouter.addImagePage, (Route<dynamic> route) => false,
            arguments: {
              "projName": widget.projName,
              "folderName": widget.folderName,
              "isNewImageAdded": true,
            });
      } else if (widget.isWithoutSubfolder == true) {
        //save original image
        newDirectory =
            Directory('${directory.path}$dirFolderName/${widget.projName}');
        await newDirectory.create(recursive: true);

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
        String imgFileName = widget.image.path.split('$dirFolderName').last;

        File imageFile = File('${directory.path}$dirFolderName$imgFileName');
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        Navigator.pop(context);

        Navigator.of(context).pushReplacementNamed(PageRouter.subFolderPage,
            arguments: {"projName": widget.projName});
      }
    } on Exception catch (e) {
      rethrow;
    }
  }
}
