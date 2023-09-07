import 'dart:io';

import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as convertor;

import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';

class TableView extends StatefulWidget {
  final String htmlString;
  final File tableContentFilePath;
  final String? templateFilePath;
  final String? actualtemplatePath;
  final List<String>? keywordList;
  final File keyContentPath;

  const TableView(
      {super.key,
      required this.htmlString,
      required this.tableContentFilePath,
      required this.templateFilePath,
      required this.actualtemplatePath,
      required this.keywordList,
      required this.keyContentPath});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  List<List<List<String>>> tableList = [];
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  late String htmlStringContent;

  Map<String, String> keyStore = {};

  List<String> keyWordList = [];
  @override
  void initState() {
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
    File tableContentFile = File(widget.tableContentFilePath.path);
    setState(() {
      htmlStringContent = tableContentFile.readAsStringSync();
    });
    listFromHtml(removeJunk());
  }

  Future<void> _refreshPage() async {
    final refreshedContent = await _loadHtmlContent();
    listFromHtml(removeJunkA(refreshedContent));
    // await _loadTableData();
  }

  Future<String> _loadHtmlContent() async {
    File tableContentFile = File(widget.tableContentFilePath.path);
    return await tableContentFile.readAsString();
  }

  removeJunk() {
    var temp = htmlStringContent;
    if (htmlStringContent.startsWith('b')) {
      temp = temp.substring(2);
      return temp;
    }
    return temp;
  }

  removeJunkA(String content) {
    var temp = content;
    if (content.startsWith('b')) {
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
                if (!tableVal[i][j].toLowerCase().contains('result') &&
                    !tableVal[i][j].toLowerCase().contains('#{') &&
                    !tableVal[i][j].toLowerCase().contains('}#')) {
                  rows.add(body(tableVal[i][j], i, j, k, ''));
                } else {
                  var key = '';
                  if (tableVal[i][j].contains('#{') ||
                      tableVal[i][j].contains('}#')) {
                    key = tableVal[i][j].replaceAll('#{', '');
                    key = key.replaceAll('}#', '');
                  }
                  rows.add(body('', i, j, k, key));
                }
              }
              rows.add(deleterow(i, k));
              if (i == tableVal.length - 1) {
                rows.add(addrow(k));
              }

              widgets.add(Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rows,
              ));
            }
          }
        }
        if (widgets.length > 0) {
          // tableWidget.add();
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
      width: 230,
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
        // height: 80,
        width: 230,
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
                onChanged: (value) async {
                  tableList[k][i][j] = value;
                  await modifyTablerow(k, i, j, value);
                },
                decoration: const InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none),
              ));
  }

  deleterow(int i, int k) {
    return IconButton(
        tooltip: 'Delete row',
        icon: CircleAvatar(
          radius: 13,
          backgroundColor: primaryColor,
          child: Icon(Icons.delete,
              color: Colors.white,
              size: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                  ? 25
                  : Sizing().height(20, 5)),
        ),
        onPressed: () async {
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
                                borderRadius: BorderRadius.circular(2)),
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
                            margin: EdgeInsets.only(left: Sizing.width(2, 2)),
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2)),
                            child: TextButton(
                                onPressed: () async {
                                  try {
                                    Directory pythonFileDir =
                                        await Constants.getDataDirectory();
                                    String pythonFilePath = pythonFileDir.path;
                                    var result = await Process.run('python', [
                                      '$pythonFilePath/addrowtotable.py',
                                      widget.templateFilePath.toString(),
                                      k.toString(),
                                      i.toString()
                                    ]);
                                    if (result.stderr != null ||
                                        result.stderr != '') {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription:
                                              'An error occurred in Python script: ${result.stderr}',
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                      print(
                                          'An error occurred in Python script: ${result.stderr}');
                                    } else {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription:
                                              'Python script output: ${result.stdout}',
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                      print(
                                          'Python script output: ${result.stdout}');
                                    }

                                    if (result.stdout
                                        .contains('An error occurred:')) {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription:
                                              'An error occurred in the my_function: ${result.stdout}',
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                      print(
                                          'An error occurred in the my_function: ${result.stdout}');
                                    } else {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription:
                                              'my_function output: ${result.stdout}',
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                      print(
                                          'my_function output: ${result.stdout}');
                                    }

                                    //extract table content from word file
                                    String filePath =
                                        widget.templateFilePath.toString();
                                    var resulttable = await Process.run(
                                        'python', [
                                      '$pythonFilePath/extractTableData.py',
                                      filePath.toString()
                                    ]);
                                    if (resulttable.stderr.isNotEmpty) {
                                      errorLog.add(ErrorLogModel(
                                          errorDescription:
                                              'An error occurred in Python script: ${result.stderr}',
                                          duration: DateTime.now().toString()));
                                      errorLogService.saveErrorLog(errorLog);
                                      print(
                                          'An error occurred in Python script: ${result.stderr}');
                                    }
                                    String tableContent = resulttable.stdout;
                                    //extract table content from word file

                                    //create table content text File
                                    // final File tableContentFile = File(filePath);
                                    await widget.tableContentFilePath
                                        .writeAsString(tableContent,
                                            mode: FileMode.write);

                                    await _refreshPage();

                                    Navigator.pop(context);
                                    CherryToast.success(
                                            title: Text(
                                              "Row deleted successfully",
                                              style: TextStyle(
                                                  fontSize:
                                                      Sizing().height(5, 3)),
                                            ),
                                            autoDismiss: true)
                                        .show(context);
                                  } on Exception catch (e) {
                                    errorLog.add(ErrorLogModel(
                                        errorDescription: e.toString(),
                                        duration: DateTime.now().toString()));
                                    errorLogService.saveErrorLog(errorLog);
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
        });
  }

  addrow(int k) {
    return IconButton(
        tooltip: 'Add row',
        icon: CircleAvatar(
          radius: 13,
          backgroundColor: primaryColor,
          child: Icon(Icons.add,
              color: Colors.white,
              size: Sizing.getScreenWidth(context) > 1000 && !Platform.isWindows
                  ? 25
                  : Sizing().height(20, 5)),
        ),
        onPressed: () async {
          Directory pythonFileDir = await Constants.getDataDirectory();
          String pythonFilePath = pythonFileDir.path;
          var result = await Process.run('python', [
            '$pythonFilePath/addrowtotable.py',
            widget.templateFilePath.toString(),
            k.toString(),
            "0"
          ]);
          if (result.stderr != null || result.stderr != '') {
            errorLog.add(ErrorLogModel(
                errorDescription:
                    'An error occurred in Python script: ${result.stderr}',
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            print('An error occurred in Python script: ${result.stderr}');
          } else {
            errorLog.add(ErrorLogModel(
                errorDescription: 'Python script output: ${result.stdout}',
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            print('Python script output: ${result.stdout}');
          }

          if (result.stdout.contains('An error occurred:')) {
            errorLog.add(ErrorLogModel(
                errorDescription:
                    'An error occurred in the my_function: ${result.stdout}',
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            print('An error occurred in the my_function: ${result.stdout}');
          } else {
            errorLog.add(ErrorLogModel(
                errorDescription: 'my_function output: ${result.stdout}',
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            print('my_function output: ${result.stdout}');
          }

          //extract table content from word file
          String filePath = widget.templateFilePath.toString();
          var resulttable = await Process.run('python',
              ['$pythonFilePath/extractTableData.py', filePath.toString()]);
          if (resulttable.stderr.isNotEmpty) {
            errorLog.add(ErrorLogModel(
                errorDescription:
                    'An error occurred in Python script: ${result.stderr}',
                duration: DateTime.now().toString()));
            errorLogService.saveErrorLog(errorLog);
            print('An error occurred in Python script: ${result.stderr}');
          }
          String tableContent = resulttable.stdout;
          //extract table content from word file

          //create table content text File
          // final File tableContentFile = File(filePath);
          await widget.tableContentFilePath
              .writeAsString(tableContent, mode: FileMode.write);

          await _refreshPage();
        });
  }

  Future<void> modifyTablerow(tableNo, row, col, value) async {
    Directory pythonFileDir = await Constants.getDataDirectory();
    String pythonFilePath = pythonFileDir.path;
    var result = await Process.run('python', [
      '$pythonFilePath/modify_table_row.py',
      widget.templateFilePath.toString(),
      widget.actualtemplatePath.toString(),
      tableNo.toString(),
      row.toString(),
      col.toString(),
      value
    ]);
    if (result.stderr != null || result.stderr != '') {
      errorLog.add(ErrorLogModel(
          errorDescription:
              'An error occurred in Python script: ${result.stderr}',
          duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      print('An error occurred in Python script: ${result.stderr}');
    } else {
      errorLog.add(ErrorLogModel(
          errorDescription: 'Python script output: ${result.stdout}',
          duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      print('Python script output: ${result.stdout}');
    }

    if (result.stdout.contains('An error occurred:')) {
      errorLog.add(ErrorLogModel(
          errorDescription:
              'An error occurred in the my_function: ${result.stdout}',
          duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      print('An error occurred in the my_function: ${result.stdout}');
    } else {
      errorLog.add(ErrorLogModel(
          errorDescription: 'my_function output: ${result.stdout}',
          duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      print('my_function output: ${result.stdout}');
    }
  }
}
