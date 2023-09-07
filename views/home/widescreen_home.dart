import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:USB_Share/methods/handle_share.dart';
import '../../services/photon_sender.dart';
import '../apps_list.dart';

class WidescreenHome extends StatefulWidget {
  const WidescreenHome({Key? key}) : super(key: key);

  @override
  State<WidescreenHome> createState() => _WidescreenHomeState();
}

class _WidescreenHomeState extends State<WidescreenHome> {
  bool isLoading = false;
  Box box = Hive.box('appData');
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isLoading) ...{
            Card(
              color: const Color.fromARGB(255, 241, 241, 241),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: send(context),
            ),
            SizedBox(
              width: size.width / 10,
            ),
            Card(
              color: const Color.fromARGB(255, 241, 241, 241),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: receive(context),
            ),
          } else ...{
            Center(
              child: SizedBox(
                width: size.width / 4,
                height: size.height / 4,
                child: Lottie.asset('assets/lottie/setting_up.json',
                    width: 40, height: 40),
              ),
            ),
            const Center(
              child: Text(
                'Please wait, file(s) are being fetched',
                style: TextStyle(
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            )
          }
        ],
      ),
    );
  }

  receive(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.red,
      child: IconButton(
          onPressed: () {
            if (Platform.isAndroid || Platform.isIOS) {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        MaterialButton(
                          onPressed: () async {
                            HandleShare(context: context).onNormalScanTap();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minWidth: MediaQuery.of(context).size.width / 2,
                          color: Colors.blue,
                          child: const Text(
                            'Normal mode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        MaterialButton(
                          onPressed: () {
                            HandleShare(context: context).onQrScanTap();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minWidth: MediaQuery.of(context).size.width / 2,
                          color: Colors.blue,
                          child: const Text(
                            'QR code mode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    );
                  });
            } else {
              Navigator.of(context).pushNamed('/receivepage');
            }
          },
          icon: const Icon(
            Icons.download_outlined,
            color: Colors.white,
          )),
    );
  }

  send(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.green,
      child: IconButton(
          onPressed: () async {
            if (Platform.isAndroid) {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minWidth: MediaQuery.of(context).size.width / 2,
                            color: Colors.blue,
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                              });

                              await PhotonSender.handleSharing();

                              setState(() {
                                isLoading = false;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Icon(
                                  Icons.file_open,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Files',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(
                          height: 25,
                        ),
                        MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minWidth: MediaQuery.of(context).size.width / 2,
                            color: Colors.blue,
                            onPressed: () async {
                              if (box.get('queryPackages')) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const AppsList()));
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                          'Query installed packages'),
                                      content: const Text(
                                          'To get installed apps, you need to allow photon to query all installed packages. Would you like to continue ?'),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Go back'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            box.put('queryPackages', true);

                                            Navigator.of(context)
                                                .popAndPushNamed('/apps');
                                          },
                                          child: const Text('Continue'),
                                        )
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/android.svg',
                                  color: Colors.white,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  'Apps',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    );
                  });
            } else {
              await PhotonSender.handleSharing();
            }
          },
          icon: const Icon(
            Icons.send,
            color: Colors.white,
          )),
    );
  }
}
