import 'dart:io';

import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as convertor;

class AndroidTableView extends StatefulWidget {
  final String htmlString;
  final List<String>? keywordList;
  final File tableContentFilePath;
  final File keyContentPath;
  // final String dirPath;
  const AndroidTableView({
    super.key,
    required this.htmlString,
    required this.keywordList,
    required this.tableContentFilePath,
    required this.keyContentPath,
    // required this.dirPath,
  });

  @override
  State<AndroidTableView> createState() => _AndroidTableViewState();
}

class _AndroidTableViewState extends State<AndroidTableView> {
  List<List<List<String>>> tableList = [];
  Map<String, String> keyStore = {};

  List<String> keyWordList = [];

  @override
  initState() {
    super.initState();

    if (widget.keywordList != null && widget.keywordList!.isNotEmpty) {
      File keyfile = File(widget.keyContentPath.path);
      List<String> values = [];
      String content = keyfile.readAsStringSync();
      if (content != '') {
        values = content.split(',');
      }

      if (values.isNotEmpty && values.length == widget.keywordList!.length) {
        for (String i in values) {
          var keyVal = i.split('|');
          keyStore[keyVal[0]] = keyVal[1];
          keyWordList.add(keyVal[0]);
        }
      } else {
        for (String i in widget.keywordList!) {
          if (content != '') {}
          keyStore[i] = '';
          keyWordList.add(i);
        }
      }
    }
    listFromHtml(removeJunk());
  }

  removeJunk() {
    var temp = widget.htmlString;
    if (widget.htmlString.startsWith('b')) {
      temp = temp.substring(2);
      return temp;
    }
    return temp;
  }

  listFromHtml(String html) {
    List<List<List<String>>> tables = [];

    var doc = convertor.parse(html);
    var tbl = doc.querySelectorAll('table');
    if (tbl.isNotEmpty) {
      tbl.forEach((e) {
        List<List<String>> dataLst = [];
        List<String> data = [];

        var tr = e.querySelectorAll('tr');

        if (tr.isNotEmpty) {
          for (var i in tr) {
            //Check if tr has th (Header)
            var th = i.querySelectorAll('th');
            if (th.isNotEmpty) {
              data = [];
              for (var h in th) {
                data.add(h.text);
              }
              dataLst.add(data);
            }

            //Check if tr has td (body)
            var td = i.querySelectorAll('td');
            if (td.isNotEmpty) {
              data = [];
              for (var d in td) {
                data.add(d.text);
              }
              dataLst.add(data);
            }
          }
        }
        //remove unwanted table list
        dataLst.removeWhere((e) => e.length == 1);
        tables.add(dataLst);
      });
    }

    setState(() {
      tableList = tables;
    });
  }

  htmlFromString() {
    CommonUi().showLoadingDialog(context);
    String html = '';
    if (tableList.isNotEmpty) {
      //loop firsrt element for table header
      bool isHeader = true;
      for (int k = 0; k < tableList.length; k++) {
        html += '<table>';
        List<List<String>> tableVal = tableList[k];
        for (int i = 0; i < tableVal.length; i++) {
          if (tableVal[i].isNotEmpty) {
            html += '<tr>';
            for (int j = 0; j < tableVal[i].length; j++) {
              if (isHeader) {
                html += '<th>${tableVal[i][j]}</th>';
                isHeader = false;
              } else {
                html += '<td>${tableVal[i][j]}</td>';
              }
            }
            html += '</tr>';
          }
        }
        html += '</table>';
      }
    }

    widget.tableContentFilePath.writeAsStringSync(html, mode: FileMode.write);

    Navigator.pop(context);
    CherryToast.success(
            title: Text(
              "Table updated successfully",
              style: TextStyle(fontSize: Sizing().height(9, 3)),
            ),
            autoDismiss: true)
        .show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
              Navigator.of(context).pop();
            },
          ),
          // actions: [
          //   GestureDetector(
          //     onTap: () async {
          //       List<String> keys = keyStore.keys.toList();
          //       List<String> values = keyStore.values.toList();
          //       List<String> keyValues = [];
          //       bool error = false;

          //       CommonUi().showLoadingDialog(context);

          //       for (int i = 0; i < keys.length; i++) {
          //         keyValues.add('${keys[i]}|${values[i]}');
          //       }

          //       File file = File(widget.keyContentPath.path);
          //       file.writeAsStringSync(keyValues.join(','),
          //           mode: FileMode.write);

          //       Navigator.pop(context);
          //       Navigator.pop(context);

          //       htmlFromString();
          //     },
          //     child: Container(
          //       padding: EdgeInsets.symmetric(
          //         horizontal: Sizing.width(3, 4),
          //         vertical: Sizing().height(2, 2),
          //       ),
          //       margin: EdgeInsets.symmetric(
          //           horizontal: Sizing.width(2, 10),
          //           vertical: Sizing().height(5, 2)),
          //       decoration: BoxDecoration(
          //           color: primaryColor,
          //           borderRadius: BorderRadius.circular(7)),
          //       child: Row(
          //         children: [
          //           Padding(
          //             padding: EdgeInsets.only(right: Sizing.width(1, 2)),
          //             child: Text(
          //               'Save table value',
          //               style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: Sizing().height(10, 3)),
          //             ),
          //           ),
          //           Container(
          //             padding: EdgeInsets.symmetric(
          //               horizontal: Sizing.width(3, 3),
          //               vertical: Sizing().height(2, 1),
          //             ),
          //             decoration: BoxDecoration(
          //                 color: Color.fromARGB(255, 107, 114, 169),
          //                 borderRadius: BorderRadius.circular(7)),
          //             child: Icon(
          //               Icons.check_circle,
          //               color: Colors.white,
          //               size: Sizing.getScreenWidth(context) > 1000 &&
          //                       !Platform.isWindows
          //                   ? 25
          //                   : Sizing().height(20, 4),
          //             ),
          //           )
          //         ],
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: buildTable(),
                ),
              ),
            ),
          ),
        ));
  }

  List<Widget> buildTable() {
    if (tableList.isEmpty) {
      List<Widget> wgt = [];
      wgt.add(const Center(child: Text('No data')));
      return wgt;
    } else {
      List<Widget> tableWidget = [];
      List<Widget> widgets = [];
      List<Widget> rows = [];

      bool isHeader = true;
      bool isFirstRow = true;

      // loop through tableVal
      for (int k = 0; k < tableList.length; k++) {
        widgets = [];
        List<List<String>> tableVal = tableList[k];
        for (int i = 0; i < tableVal.length; i++) {
          if (tableVal[i].isNotEmpty) {
            // check table has multi-row headers
            if (!isFirstRow && tableVal[0].contains(tableVal[i][0]) ||
                tableVal[0].contains(tableVal[i][1])) {
              isHeader = true;
            }
            //by default first element or 0th index is the header list
            if (isHeader) {
              rows = [];
              for (int j = 0; j < tableVal[i].length; j++) {
                rows.add(header(tableVal[i][j]));
              }
              widgets.add(Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rows,
              ));
              //make isheader after adding first element
              isHeader = false;
              isFirstRow = false;
            } else {
              //create table body
              rows = [];
              for (int j = 0; j < tableVal[i].length; j++) {
                if (!tableVal[i][j].toLowerCase().contains('result')) {
                  rows.add(body(tableVal[i][j], i, j, k, ''));
                } else {
                  var key = '';
                  if (tableVal[i][j].contains('#{') ||
                      tableVal[i][j].contains('}#')) {
                    key = tableVal[i][j].replaceAll('#{', '');
                    key = key.replaceAll('}#', '');
                  }
                  rows.add(body(tableVal[i][j], i, j, k, key));
                }
              }
              widgets.add(Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rows,
              ));
            }
          }
        }
        tableWidget.add(Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ));
      }
      return tableWidget;
    }
  }

  header(String val) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          color: Colors.blue[100]),
      child: Text(
        val,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[900],
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  body(String val, int i, int j, int k, String key) {
    return Container(
        height: 100,
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: key.toLowerCase().contains('result')
            ? TextFormField(
                initialValue: keyStore[key] != null && keyStore[key] != ""
                    ? keyStore[key]
                    : "",
                onChanged: (value) {
                  keyStore[key] = value;
                  tableList[k][i][j] = value;
                  List<String> keys = keyStore.keys.toList();
                  List<String> values = keyStore.values.toList();
                  List<String> keyValues = [];
                  bool error = false;
                  for (int i = 0; i < keys.length; i++) {
                    keyValues.add('${keys[i]}|${values[i]}');
                  }

                  File file = File(widget.keyContentPath.path);
                  file.writeAsStringSync(keyValues.join(','),
                      mode: FileMode.write);
                },
                decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none),
              )
            : TextFormField(
                initialValue: val,
                onChanged: (value) {
                  // tableList[k][i][j] = value;
                },
                decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none),
              ));
  }
}
