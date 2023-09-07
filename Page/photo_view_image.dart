import 'dart:io';
import 'package:USB_Share/Util/sizing.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:USB_Share/Util/palette.dart';

class PhotoViewImage extends StatefulWidget {
  final File image;
  const PhotoViewImage({super.key, required this.image});

  @override
  State<PhotoViewImage> createState() => _PhotoViewImageState();
}

class _PhotoViewImageState extends State<PhotoViewImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: blackColor,
          leading: IconButton(
            tooltip: 'Back',
            icon: CircleAvatar(
              radius: 13,
              backgroundColor: primaryColor,
              child: Icon(Icons.arrow_back,
                  color: Colors.white,
                  size: Sizing.getScreenWidth(context) > 1000 &&
                          !Platform.isWindows
                      ? 25
                      : Sizing().height(20, 5)),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: WillPopScope(
            onWillPop: () async => false,
            child: Platform.isWindows
                ? SingleChildScrollView(
                    child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child:
                            PhotoView(imageProvider: FileImage(widget.image))),
                  )
                : PhotoView(imageProvider: FileImage(widget.image))));
  }
}
