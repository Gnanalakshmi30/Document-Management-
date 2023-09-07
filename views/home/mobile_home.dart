import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:USB_Share/services/photon_sender.dart';
import '../../methods/handle_share.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({Key? key}) : super(key: key);

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  PhotonSender photonSePhotonSender = PhotonSender();
  bool isLoading = false;
  Box box = Hive.box('appData');
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isLoading) ...{
          Card(
            color: const Color.fromARGB(255, 241, 241, 241),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: send(),
          ),
          const SizedBox(
            height: 32,
          ),
          Card(
            color: const Color.fromARGB(255, 241, 241, 241),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: receive(context),
          ),
        } else ...{
          Center(
            child: SizedBox(
              width: size.width / 4,
              height: size.height / 4,
              child: Lottie.asset(
                'assets/lottie/setting_up.json',
                width: 100,
                height: 100,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Please wait, file(s) are being fetched',
              style: TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          )
        },
      ],
    );
  }

  receive(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.red,
      child: IconButton(
        onPressed: () {
          if (Platform.isAndroid || Platform.isIOS) {
            showModalBottomSheet(
                backgroundColor: Colors.white,
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
        ),
      ),
    );
  }

  send() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.green,
      child: IconButton(
        onPressed: () async {
          if (Platform.isAndroid) {
            await PhotonSender.handleSharing();
          } else {
            await PhotonSender.handleSharing();
          }
        },
        icon: const Icon(
          Icons.send,
          color: Colors.white,
        ),
      ),
    );
  }
}
