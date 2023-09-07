import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/components/constants.dart';
import 'package:USB_Share/components/snackbar.dart';
import 'package:USB_Share/methods/methods.dart';
import 'package:USB_Share/models/share_history_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('History'),
        flexibleSpace: Container(
          decoration: appBarGradient,
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              onPressed: () {
                setState(() {
                  clearHistory();
                });
                showSnackBar(context, 'History cleared');
              },
            ),
          ),
        ),
        leading: BackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ),
      body: FutureBuilder(
        future: getHistory(),
        builder: (context, AsyncSnapshot snap) {
          if (snap.connectionState == ConnectionState.done) {
            late List<ShareHistory> data;

            snap.data == null
                ? data = []
                : data = HistoryList.formData(snap.data).historyList;

            return snap.data == null
                ? const Center(
                    child: Text('File sharing history will appear here'),
                  )
                : ListView.separated(
                    separatorBuilder: (context, i) {
                      return const Divider(
                        color: Color.fromARGB(255, 70, 69, 69),
                      );
                    },
                    itemCount: data.length,
                    itemBuilder: (context, item) {
                      return ListTile(
                        leading:
                            getFileIcon(data[item].fileName.split('.').last),
                        onTap: () async {
                          String path =
                              data[item].filePath.replaceAll(r"\", "/");
                          if (Platform.isAndroid || Platform.isIOS) {
                            try {
                              // OpenFile.open(path);
                            } catch (_) {
                              // ignore: use_build_context_synchronously
                              showSnackBar(
                                  context, 'No corresponding app found');
                            }
                          } else {
                            try {
                              launchUrl(
                                Uri.file(
                                  path,
                                  windows: Platform.isWindows,
                                ),
                              );
                            } catch (e) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Unable to open the file')));
                            }
                          }
                        },
                        title: Text(
                          data[item].fileName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(getDateString(data[item].date)),
                      );
                    });
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
