import 'dart:io';
import 'package:USB_Share/AddImage/Model/addImage_model.dart';
import 'package:USB_Share/AddImage/Service/add_Image_service.dart';
import 'package:USB_Share/Dashboard/Model/SyncHistoryModel.dart';
import 'package:USB_Share/Dashboard/Service/dashboard_service.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/components/dialogs.dart';
import 'package:USB_Share/controllers/controllers.dart';
import 'package:USB_Share/models/sender_model.dart';
import 'package:USB_Share/services/photon_sender.dart';

import '../../components/components.dart';

class SharePage extends StatefulWidget {
  const SharePage({Key? key}) : super(key: key);

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  SenderModel senderModel = PhotonSender.getServerInfo();
  PhotonSender photonSender = PhotonSender();
  late double width;
  late double height;
  bool willPop = false;
  var receiverDataInst = GetIt.I.get<ReceiverDataController>();
  List<String> imgName = [];
  List<ImageLogModel> imageLog = [];
  final imageService = ImageService();
  final syncService = DashboardService();

  deleteZipFolderMobile() async {
    try {
      String dirFolderName = Constants.directoryFolderName;
      //delete zip file after shared
      Directory savedDir = await FileMethods.getSaveDirectory();
      File zipFile = File('${savedDir.path}photo_app.zip');
      if (await zipFile.exists()) {
        await zipFile.delete(recursive: true);
      } else {}

      //delete trashzip file
      Directory trashDirectory = Directory('${savedDir.path}$dirFolderName');

      if (await trashDirectory.exists()) {
        List<FileSystemEntity> files = trashDirectory.listSync();
        for (FileSystemEntity file in files) {
          if (file is File &&
              file.path.endsWith('.zip') &&
              file.path.contains('trash')) {
            file.deleteSync();
          }
        }
      } else {}
      //delete trashzip file

      if (session.isWifi) {
        //post recent shared imagelog
        List<ImageLogModel> res = await imageService.getImageLog();
        List<String> imgLogName =
            res.map<String>((e) => e.imageName ?? "").toList();
        setState(() {
          imgName = imgLogName;
        });

        Directory dir = Directory('${savedDir.path}$dirFolderName');
        listFiles(dir);
        imageService.saveImagLog(imageLog);
        session.isWifi = false;
        if (Platform.isWindows) {
          List<SyncHistoryModel> syncHistory = [
            SyncHistoryModel(
                deviceId: '',
                syncedTime: DateTime.now().toLocal().toString(),
                syncMode: 'Wifi',
                noOfFiles: imageLog.length,
                imageFiles: 0)
          ];
          syncService.saveSyncHistory(syncHistory);
        }
        //
      }
    } on Exception catch (e) {
      throw e;
    }
  }

  listFiles(Directory dir) {
    List<FileSystemEntity> contents = dir.listSync();
    for (FileSystemEntity content in contents) {
      if (content is File) {
        if (!imgName.contains(content.path.split('/').last)) {
          imageLog.add(ImageLogModel(
              imageName: content.path.split('/').last,
              syncedDate: DateTime.now().toString()));
        }
      } else if (content is Directory) {
        listFiles(Directory(content.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return WillPopScope(
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: const Text(
              'Share',
              style: TextStyle(color: Colors.white),
            ),
            leading: BackButton(
                color: Colors.white,
                onPressed: () {
                  receiverDataInst.reactive;
                  if (Platform.isWindows) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/dashboard', (Route<dynamic> route) => false,
                        arguments: {
                          'index': 0,
                          'newProjCreated': false,
                        });
                  } else if (Platform.isAndroid) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/AndroidDashboardPage',
                        (Route<dynamic> route) => false);
                  }
                }),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (width > 720) ...{
                    const SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: width > 720 ? 200 : 100,
                          height: width > 720 ? 200 : 100,
                          child: QrImage(
                            size: 180,
                            foregroundColor: Colors.black,
                            data: PhotonSender.getPhotonLink,
                            backgroundColor: Colors.white,
                          ),
                        )
                      ],
                    )
                  } else ...{
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: QrImage(
                        // size: 180,
                        foregroundColor: Colors.black,
                        data: PhotonSender.getPhotonLink,
                        backgroundColor: Colors.white,
                      ),
                    )
                  },

                  const SizedBox(
                    height: 20,
                  ),

                  //receiver data
                  Obx((() => GetIt.I
                          .get<ReceiverDataController>()
                          .receiverMap
                          .isEmpty
                      ? Card(
                          color: Colors.white,
                          clipBehavior: Clip.antiAlias,
                          elevation: 0,
                          // color: Platform.isWindows ? Colors.grey.shade300 : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          child: SizedBox(
                            height: width > 720 ? 200 : 128,
                            width: width > 720 ? width / 2 : width / 1.25,
                            child: Center(
                              child: Wrap(
                                direction: Axis.vertical,
                                children: infoList(
                                    senderModel, width, height, true, "bright"),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: width / 1.2,
                          child: Card(
                            color: const Color.fromARGB(255, 241, 241, 241),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: receiverDataInst.receiverMap.length,
                              itemBuilder: (context, item) {
                                var keys =
                                    receiverDataInst.receiverMap.keys.toList();

                                var data = receiverDataInst.receiverMap;

                                //delete zip file in mobile
                                if (data[keys[item]]['isCompleted'] == 'true') {
                                  // deleteZipFolderMobile();
                                }

                                return ListTile(
                                  title: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (item == 0) ...{
                                          const Center(
                                            child: Text("Sharing status"),
                                          ),
                                        },
                                        const Divider(
                                          thickness: 2.4,
                                          indent: 20,
                                          endIndent: 20,
                                          color: Color.fromARGB(
                                              255, 109, 228, 113),
                                        ),
                                        Center(
                                          child: Text(
                                            "Receiver name : ${data[keys[item]]['hostName']}",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        data[keys[item]]['isCompleted'] ==
                                                'true'
                                            ? const Center(
                                                child: Text(
                                                  "All files sent",
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                    "Sending '${data[keys[item]]['currentFileName']}' (${data[keys[item]]['currentFileNumber']} out of ${data[keys[item]]['filesCount']} files)"),
                                              )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ))),
                ],
              ),
            ),
          )),
      onWillPop: () async {
        willPop = await sharePageWillPopDialog(context);
        GetIt.I.get<ReceiverDataController>().receiverMap.clear();
        return willPop;
      },
    );
  }
}
