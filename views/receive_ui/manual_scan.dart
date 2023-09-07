import 'dart:io';
import 'package:USB_Share/Util/sizing.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/models/sender_model.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:USB_Share/views/receive_ui/progress_page.dart';
import '../../controllers/intents.dart';
import '../../services/photon_receiver.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({Key? key}) : super(key: key);

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  late Directory dir;

  Future<List<SenderModel>> _scan() async {
    dir = await FileMethods.getSaveDirectory();
    try {
      List<SenderModel> resp = await PhotonReceiver.scan();
      return resp;
    } catch (_) {}
    return [];
  }

  GetIt getIt = GetIt.instance;

  //to keep copy of stateful builder context
  //otherwise it will throw error
  late StateSetter sts;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isRequestSent = false;

    return Shortcuts(
      shortcuts: {LogicalKeySet(LogicalKeyboardKey.backspace): GoBackIntent()},
      child: Actions(
        actions: {
          GoBackIntent: CallbackAction<GoBackIntent>(onInvoke: (intent) {
            Navigator.of(context).pop();
            return null;
          })
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: const Text(
              'Scan',
              style: TextStyle(color: Colors.white),
            ),
            leading: BackButton(
                color: Colors.white,
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ),

          body: FutureBuilder(
            future: _scan(),
            builder: (context, AsyncSnapshot snap) {
              if (snap.connectionState == ConnectionState.done) {
                List<SenderModel> senderModels = snap.data as List<SenderModel>;
                return StatefulBuilder(builder: (context, StateSetter c) {
                  sts = c;
                  return Center(
                    child: Column(
                      mainAxisAlignment: snap.data.length == 0
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (snap.data.length == 0) ...{
                          Center(
                            child: Focus(
                              child: Text(
                                'No device found\nMake sure sender & receiver are connected through mobile hotspot\nOR\nSender and Receivers are connected to same wifi\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 720
                                          ? 20
                                          : 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        } else if (isRequestSent) ...{
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 2 - 80,
                          ),
                          Center(
                            child: Focus(
                              child: Text(
                                'Waiting for sender to approve,ask sender to approve !',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 720
                                          ? 18
                                          : 16,
                                ),
                              ),
                            ),
                          ),
                          Card(
                            child: SizedBox(
                                child: Text(
                              '(Files will be saved at $dir)',
                              textAlign: TextAlign.center,
                            )),
                          )
                        } else ...{
                          const SizedBox(
                            height: 28,
                          ),
                          const Center(
                            child: Focus(
                              child: Text(
                                  "Please select the 'sender' from the list"),
                            ),
                          ),
                          ListView.builder(
                            padding: width > 720
                                ? const EdgeInsets.only(left: 120, right: 120)
                                : const EdgeInsets.all(0),
                            shrinkWrap: true,
                            itemCount: snap.data.length,
                            itemBuilder: (c, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  clipBehavior: Clip.antiAlias,
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 5,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        //only rebuild the column
                                        sts(() {
                                          isRequestSent = true;
                                        });

                                        var resp = await PhotonReceiver
                                            .isRequestAccepted(
                                          snap.data[index] as SenderModel,
                                        );

                                        if (resp['accepted']) {
                                          // ignore: use_build_context_synchronously
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return ProgressPage(
                                                  senderModel: snap.data[index]
                                                      as SenderModel,
                                                  secretCode: resp['code'],
                                                );
                                              },
                                            ),
                                          );
                                        } else {
                                          sts(() {
                                            isRequestSent = false;
                                          });
                                          // ignore: use_build_context_synchronously
                                          CherryToast.info(
                                                  title: Text(
                                                    "Access denied by the sender",
                                                    style: TextStyle(
                                                        fontSize: Sizing()
                                                            .height(9, 3)),
                                                  ),
                                                  autoDismiss: true)
                                              .show(context);
                                        }
                                      },
                                      child: Center(
                                        child: SizedBox(
                                          height: width > 720 ? 200 : 128,
                                          width: width > 720
                                              ? width / 2
                                              : width / 1.25,
                                          child: Center(
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    flex: width > 720 ? 1 : 2,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: RichText(
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  '${senderModels[index].host}\n',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                                text:
                                                                    '${senderModels[index].ip} ◉\n',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                            TextSpan(
                                                                text:
                                                                    '${senderModels[index].os}\n',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                            TextSpan(
                                                                text:
                                                                    '${senderModels[index].filesCount} file(s)',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        }
                      ],
                    ),
                  );
                });
              } else {
                return Center(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Lottie.asset(
                              'assets/lottie/searching.json',
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () async {
          //     setState(() {});
          //   },
          //   child: const Text('Retry'),
          // ),
        ),
      ),
    );
  }
}
