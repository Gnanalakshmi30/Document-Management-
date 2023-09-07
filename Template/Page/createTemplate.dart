import 'dart:async';
import 'dart:io';
import 'package:USB_Share/Configuration/Model/reportCategory_model.dart';
import 'package:USB_Share/Configuration/Model/templateStyle_model.dart';
import 'package:USB_Share/Configuration/Service/config_service.dart';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Template/Model/templateAndCategoryMapModel.dart';
import 'package:USB_Share/Template/Service/templateAndCategoryMapService.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/local_server.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:USB_Share/services/file_services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:path/path.dart' as path;

class WindowsEditor extends StatefulWidget {
  final String? templateName;
  final int? projectNo;
  final bool isFormGR;
  final int? categoryId;
  final bool? isEditTemp;
  const WindowsEditor(
      {super.key,
      this.templateName,
      required this.isFormGR,
      this.projectNo,
      this.categoryId,
      this.isEditTemp});

  @override
  State<WindowsEditor> createState() => _WindowsEditorState();
}

class _WindowsEditorState extends State<WindowsEditor> {
  int port = 5321;
  late LocalServer localServer;
  final controller = WebviewController();
  late WebViewController androidController;
  bool _isLoaded = false;
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  final configurationService = ConfigurationService();
  List<ReportCategoryModel> reportCategoryData = [];
  String? selectedCategory;
  final templateAndCategoryMapService = TemplateAndCategoryMapService();
  String text = "";
  List<TemplateStyleModel> tempStyleData = [];
  String dirFolderName = "";

  @override
  void initState() {
    if (Platform.isAndroid) {
      androidController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('https://www.youtube.com/')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadFlutterAsset('assets/editor.html');
    }
    if (Platform.isWindows) {
      initServer();
    } else if (Platform.isAndroid) {
      loadFile();
    }

    if (widget.categoryId != null && widget.categoryId != 0) {
      setState(() {
        selectedCategory = widget.categoryId.toString();
      });
    }

    setState(() {
      dirFolderName = Constants.directoryFolderName;
    });
    getReportCategoryList();
    getTemplateStyleData();

    super.initState();
  }

  getTemplateStyleData() async {
    var res = await configurationService.getTemplateStyleData();
    setState(() {
      tempStyleData = res;
    });
  }

  loadFile() async {
    if (widget.templateName != null &&
        widget.templateName != "" &&
        widget.isFormGR == true) {
      Directory directory = await FileMethods.getSaveDirectory();
      File file = File(
          '${directory.path}$dirFolderName/${widget.projectNo}/GeneratedReport/${widget.templateName}.html');

      String htmlContent = file.readAsStringSync();
      Timer(const Duration(seconds: 5), () async {
        await androidController.runJavaScript('set(`$htmlContent`)');
      });
    }
  }

  getReportCategoryList() async {
    var res = await configurationService.getReportCategory();
    setState(() {
      reportCategoryData = res;
    });
  }

  initServer() {
    localServer = LocalServer(port);
    localServer.start(handleRequest);
    loadHtmlFromAssets();
  }

  handleRequest(HttpRequest request) {
    try {
      if (request.method == 'GET' &&
          request.uri.queryParameters['query'] == "getRawTeXHTML") {
      } else {}
    } catch (e) {
      errorLog.add(ErrorLogModel(
          errorDescription: e.toString(), duration: DateTime.now().toString()));
      errorLogService.saveErrorLog(errorLog);
      print('Exception in handleRequest: $e');
    }
  }

  loadHtmlFromAssets() async {
    const editor = 'assets/editor.html';

    var url = 'http://localhost:$port/$editor';
    await controller.initialize();
    await controller.setBackgroundColor(Colors.transparent);
    await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await controller.loadUrl(url);

    //editTemplate
    if (widget.templateName != null &&
        widget.templateName != "" &&
        widget.isFormGR == false) {
      Directory directory = await FileMethods.getSaveDirectory();
      File file = File(
          '${directory.path}$dirFolderName/Template/${widget.templateName}.html');

      String htmlContent = file.readAsStringSync();
      Timer(const Duration(seconds: 5), () async {
        if (Platform.isWindows) {
          await controller.executeScript('set(`$htmlContent`)');
        } else if (Platform.isAndroid) {
          await androidController.runJavaScript('set(`$htmlContent`)');
        }
      });
    } else if (widget.templateName != null &&
        widget.templateName != "" &&
        widget.isFormGR == true) {
      Directory directory = await FileMethods.getSaveDirectory();
      File file = File(
          '${directory.path}$dirFolderName/${widget.projectNo}/GeneratedReport/${widget.templateName}.html');

      String htmlContent = file.readAsStringSync();
      Timer(const Duration(seconds: 5), () async {
        await controller.executeScript('set(`$htmlContent`)');
      });
    }
    //editTemplate

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appbar(),
        body: controller != null
            ? WillPopScope(
                onWillPop: () async => false,
                child: Column(
                  children: [
                    Platform.isWindows
                        ? Expanded(
                            child: Webview(
                            controller,
                          ))
                        : Expanded(
                            child: WebViewWidget(controller: androidController),
                          )
                  ],
                ),
              )
            : WillPopScope(
                onWillPop: () async => false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Center(child: CommonUi().showLoading()),
                ),
              ));
  }

  appbar() {
    return AppBar(
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
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
      title: Text(widget.isFormGR ? 'Edit Report' : 'Create Template'),
      actions: [
        widget.isEditTemp == true && Platform.isWindows
            ? IconButton(
                tooltip: "Download template",
                onPressed: () async {
                  try {
                    var htmlData =
                        await controller.executeScript('myeditor.getData()');
                    String txtIsi = htmlData
                        .toString()
                        .replaceAll("'", '\\"')
                        .replaceAll('"', '\\"')
                        .replaceAll("[", "\\[")
                        .replaceAll("]", "\\]")
                        .replaceAll("\n", "")
                        .replaceAll("\n\n", "")
                        .replaceAll("\r", " ")
                        .replaceAll('\r\n', " ");

                    final directory = await getDownloadsDirectory();
                    File htmlFilee =
                        File('${directory!.path}/${widget.templateName}.html');
                    String htmlPathh =
                        '${directory.path}/${widget.templateName}.html';
                    await htmlFilee.writeAsString(htmlData);
                    String docPath = '${directory.path}/${widget.templateName}';
                    String docName = '${widget.templateName}';
                    print(docName);
                    // final file =
                    //     File('C:\\Photo_app\\Documents\\Files\\Polymer.html');
                    // final contents = await file.readAsString();

                    // docPath = docPath.replaceAll('/', '\\');
                    // htmlPathh = htmlPathh.replaceAll('/', '\\');
                    //   createWordDocumentFromHTML(htmlData);

                    // var result = await Process.run(
                    //     'C:\\Users\\New\\Downloads\\ToHtml\\ToHtml\\ToHtml\\bin\\Debug\\net6.0\\ToHtml.exe',
                    //     ["Export", docPath, htmlPathh]);

                    // if (result.stderr.isNotEmpty) {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'An error occurred in Python script: ${result.stderr}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print(
                    //       'An error occurred in Python script: ${result.stderr}');
                    // } else {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'Python script output: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print('Python script output: ${result.stdout}');
                    // }

                    // if (result.stdout.contains('An error occurred:')) {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'An error occurred in the my_function: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print(
                    //       'An error occurred in the my_function: ${result.stdout}');
                    // } else {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'my_function output: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print('my_function output: ${result.stdout}');
                    // }

                    String fSize = '${tempStyleData[0].fontSize}';
                    String fFamily = tempStyleData[0].fontFamily ?? "";

                    // await controller.executeScript(
                    //     'convertHtmlToWord(`$htmlPathh`,`$docName`,`$fSize`,`$fFamily`)');
                    await controller.executeScript(
                        'exportHTML(`$docName`,`$fSize`,`$fFamily`)');

                    //pywin32 download

                    //   //copy and paste python file
                    //   ByteData data =
                    //       await rootBundle.load('assets/exportWord.py');
                    //   File tempPyFile = File('${directory.path}/exportWord.py');

                    //   if (!await tempPyFile.exists()) {
                    //     await tempPyFile.create();
                    //   }
                    //   await tempPyFile.writeAsBytes(data.buffer.asUint8List());
                    //   //copy and paste python file

                    //   String scriptPath = '${directory.path}/exportWord.py';

                    //   var result = await Process.run(
                    //       'python', [scriptPath, htmlPathh, docPath]);
                    // if (result.stderr.isNotEmpty) {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'An error occurred in Python script: ${result.stderr}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print(
                    //       'An error occurred in Python script: ${result.stderr}');
                    // } else {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'Python script output: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print('Python script output: ${result.stdout}');
                    // }

                    // if (result.stdout.contains('An error occurred:')) {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'An error occurred in the my_function: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print(
                    //       'An error occurred in the my_function: ${result.stdout}');
                    // } else {
                    //   errorLog.add(ErrorLogModel(
                    //       errorDescription:
                    //           'my_function output: ${result.stdout}',
                    //       duration: DateTime.now().toString()));
                    //   errorLogService.saveErrorLog(errorLog);
                    //   print('my_function output: ${result.stdout}');
                    // }

                    //   //delete script file
                    //   File scriptFile = File(scriptPath);

                    //   if (scriptFile.existsSync()) {
                    //     scriptFile.deleteSync();
                    //   }

                    //delete html file
                    File downloadHtmlFile =
                        File('${directory.path}/${widget.templateName}.html');

                    if (downloadHtmlFile.existsSync()) {
                      downloadHtmlFile.deleteSync();
                    }
                  } on Exception catch (e) {
                    errorLog.add(ErrorLogModel(
                        errorDescription: e.toString(),
                        duration: DateTime.now().toString()));
                    errorLogService.saveErrorLog(errorLog);
                  }
                },
                icon: Icon(
                  Icons.download,
                  color: whiteColor,
                  size: Sizing().height(20, 6),
                ))
            : SizedBox(),
        widget.isFormGR == false
            ? IconButton(
                tooltip: "Upload word file",
                onPressed: () async {
                  //run python script
                  try {
                    var picked = await FilePicker.platform.pickFiles();
                    if (picked != null) {
                      File file = File(picked.files.single.path!);
                      String filePath = file.path;

                      //get the directory by splitting the file path
                      String directoryPath = path.dirname(filePath);
                      print(directoryPath);
                      //get the directory by splitting the file path

                      String htmlFilePath = filePath.split('.').first;
                      String htmlFileName = "$htmlFilePath.html";
                      print('File path: $filePath');
                      print(picked.files.first.name);

                      print("aaa:: $htmlFileName");

                      // var result = await Process.run(
                      //     'C:\\Users\\New\\Downloads\\ToHtml\\ToHtml\\ToHtml\\bin\\Debug\\net6.0\\ToHtml.exe',
                      //     ["Import", filePath, htmlFileName]);

                      //copy and paste python file
                      ByteData data =
                          await rootBundle.load('assets/importWord.py');
                      File tempPyFile = File('$directoryPath/importWord.py');

                      if (!await tempPyFile.exists()) {
                        await tempPyFile.create();
                      }
                      await tempPyFile.writeAsBytes(data.buffer.asUint8List());
                      //copy and paste python file

                      // String htmlFilePath = filePath.split('.').first;
                      // String htmlFileName = "$htmlFilePath.html";
                      // print('File path: $filePath');
                      // print(picked.files.first.name);
                      // String scriptPath = tempPyFile.path;
                      // print("aaa:: $htmlFileName");

                      var result = await Process.run(
                          'python', ['importWord.py', filePath, htmlFileName]);
                      if (result.stderr.isNotEmpty) {
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
                        print('Python script output: ${result.stdout}');
                      }

                      if (result.stdout.contains('An error occurred:')) {
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
                        print('my_function output: ${result.stdout}');
                      }

                      //extract html content
                      File htmlFile = File(htmlFileName);
                      if (await htmlFile.exists()) {
                        String htmlData = await htmlFile.readAsString();

                        try {
                          // htmlData =
                          //     htmlData.replaceAll(RegExp(r'<img\b[^>]*>'), '');
                          String txtIsi = htmlData
                              .toString()
                              .replaceAll("'", '\\"')
                              .replaceAll('"', '\\"')
                              .replaceAll("[", "\\[")
                              .replaceAll("]", "\\]")
                              .replaceAll("\n", "")
                              .replaceAll("\n\n", "")
                              .replaceAll("\r", " ")
                              .replaceAll('\r\n', " ");

                          await controller.executeScript('set(`$txtIsi`)');

                          //delete importScript file
                          File importScriptFile =
                              File('$directoryPath/importWord.py');

                          if (importScriptFile.existsSync()) {
                            importScriptFile.deleteSync();
                          }

                          //delete html file
                          File htmlFile = File(htmlFileName);

                          if (htmlFile.existsSync()) {
                            htmlFile.deleteSync();
                          }
                        } on Exception catch (e) {
                          errorLog.add(ErrorLogModel(
                              errorDescription: 'Import Word executeScript: $e',
                              duration: DateTime.now().toString()));
                          errorLogService.saveErrorLog(errorLog);
                        }
                      } else {
                        errorLog.add(ErrorLogModel(
                            errorDescription: 'File not found',
                            duration: DateTime.now().toString()));
                        errorLogService.saveErrorLog(errorLog);
                        print('File not found');
                      }

                      // extract html content
                    }
                  } on Exception catch (e) {
                    errorLog.add(ErrorLogModel(
                        errorDescription: 'Import Word: $e',
                        duration: DateTime.now().toString()));
                  }
                },
                icon: Icon(
                  Icons.upload_file,
                  color: whiteColor,
                  size: Sizing().height(20, 6),
                ))
            : SizedBox(),
        widget.isFormGR == false
            ? Container(
                width: Sizing.width(150, 200),
                decoration: BoxDecoration(
                    color: whiteColor, borderRadius: BorderRadius.circular(3)),
                padding: EdgeInsets.only(
                    right: Sizing.width(1, 1),
                    left: Sizing.width(2, 2),
                    top: Sizing().height(1, 1)),
                margin: EdgeInsets.symmetric(
                    vertical: Sizing().height(1, 2),
                    horizontal: Sizing.width(2, 2)),
                child: DropdownButton<String>(
                  hint: const Text(
                    'Select report category',
                  ),
                  isDense: true,
                  isExpanded: true,
                  iconSize: Platform.isAndroid
                      ? Sizing.getScreenWidth(context) > 1000
                          ? 30
                          : Sizing().height(20, 20)
                      : 25,
                  iconEnabledColor: Colors.grey[600],
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  value: selectedCategory,
                  items: reportCategoryData.map((ReportCategoryModel value) {
                    return DropdownMenuItem<String>(
                      value: value.categoryID.toString(),
                      child: Text(
                        value.categoryName.toString(),
                      ),
                    );
                  }).toList(),
                ),
              )
            : const SizedBox(),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
              tooltip: "Save Report",
              onPressed: () async {
                try {
                  if (widget.isFormGR == false) {
                    if (selectedCategory != null && selectedCategory != "") {
                      var htmlData =
                          await controller.executeScript('myeditor.getData()');
                      if (htmlData != null && htmlData != "") {
                        if (widget.templateName != null &&
                            widget.templateName != "" &&
                            widget.isFormGR == false) {
                          CommonUi().showLoading();
                          Directory? newDirectory;
                          Directory directory =
                              await FileMethods.getSaveDirectory();
                          newDirectory =
                              Directory('${directory.path}$dirFolderName');
                          await checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/$dirFolderName/Template');
                          await checkExists(newDirectory);

                          File file = File(
                              '${newDirectory.path}/${widget.templateName}.html');

                          file.writeAsStringSync(htmlData);
                          Navigator.of(context).pushNamed(
                            PageRouter.template,
                          );
                        } else {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return TemplateNameDialog(
                                  controller: controller,
                                  reportCategory:
                                      int.parse(selectedCategory ?? "0"),
                                  dirFolderName: dirFolderName,
                                );
                              });
                        }
                      } else {
                        CherryToast.error(
                                title: Text(
                                  "Template cannot be empty",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      }
                    } else {
                      CherryToast.error(
                              title: Text(
                                "Select report category",
                                style:
                                    TextStyle(fontSize: Sizing().height(5, 3)),
                              ),
                              autoDismiss: true)
                          .show(context);
                    }
                  } else {
                    if (widget.templateName != null &&
                        widget.templateName != "" &&
                        widget.isFormGR == true) {
                      CommonUi().showLoading();
                      Directory? newDirectory;
                      Directory directory =
                          await FileMethods.getSaveDirectory();
                      newDirectory =
                          Directory('${directory.path}$dirFolderName');
                      await checkExists(newDirectory);
                      newDirectory = Directory(
                          '${directory.path}/$dirFolderName/${widget.projectNo}');
                      await checkExists(newDirectory);
                      newDirectory = Directory(
                          '${directory.path}/$dirFolderName/${widget.projectNo}/GeneratedReport');
                      await checkExists(newDirectory);
                      newDirectory = Directory(
                          '${directory.path}/$dirFolderName/${widget.projectNo}/GeneratedReport');
                      await checkExists(newDirectory);

                      File file = File(
                          '${newDirectory.path}/${widget.templateName}.html');
                      if (Platform.isWindows) {
                        var htmlData = await controller
                            .executeScript('myeditor.getData()');
                        file.writeAsStringSync(htmlData);
                      } else if (Platform.isAndroid) {
                        var htmlData = await androidController
                            .runJavaScriptReturningResult('myeditor.getData()');
                        String txtIsi = htmlData
                            .toString()
                            .replaceAll("'", '\\"')
                            .replaceAll('"', '\\"')
                            .replaceAll("[", "\\[")
                            .replaceAll("]", "\\]")
                            .replaceAll("\n", "")
                            .replaceAll("\n\n", "")
                            .replaceAll("\r", " ")
                            .replaceAll('\r\n', " ");

                        file.writeAsStringSync(txtIsi);
                      }

                      Navigator.of(context).pushNamed(
                        PageRouter.generateReport,
                      );
                    }
                  }
                } on Exception catch (e) {
                  errorLog.add(ErrorLogModel(
                      errorDescription: e.toString(),
                      duration: DateTime.now().toString()));
                  errorLogService.saveErrorLog(errorLog);
                }
              },
              icon: Icon(
                Icons.save,
                size: Sizing().height(20, 6),
              )),
        ),
      ],
    );
  }

  checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> createWordDocumentFromHTML(String html) async {
    try {
      final parsedHtml = parse(html);
      final document = parsedHtml.body!.text;

      final directory = await getDownloadsDirectory();
      final path = '${directory!.path}/document.doc';
      final file = File(path);
      await file.writeAsString(document);

      //await OpenFile.open(path);

      // Process.run('explorer.exe', ['/select,', path]);
    } on Exception catch (e) {
      throw e;
    }
  }
}

class TemplateNameDialog extends StatefulWidget {
  final WebviewController controller;
  final int? reportCategory;
  final String? dirFolderName;
  const TemplateNameDialog(
      {super.key,
      required this.controller,
      this.reportCategory,
      this.dirFolderName});

  @override
  State<TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<TemplateNameDialog> {
  final TextEditingController _templateName = TextEditingController();
  List<TemplateAndCategoryMapModel> reportAndTemplateMapList = [];
  final templateAndCategoryMapService = TemplateAndCategoryMapService();
  bool showErrorMsg = false;
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();

  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              "Save As",
              style: TextStyle(
                  fontSize: Sizing().height(4, 5), fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: Sizing().height(5, 6),
          ),
          templateName(),
          showErrorMsg
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Template Name is required',
                      style: TextStyle(
                          fontSize: Sizing().height(2, 3), color: Colors.red),
                    ),
                  ],
                )
              : const SizedBox(),
          SizedBox(
            height: Sizing().height(5, 6),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: Sizing().height(1, 1),
                  horizontal: Sizing.width(2, 3),
                ),
                decoration: BoxDecoration(
                    color: greyColor, borderRadius: BorderRadius.circular(2)),
                child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(
                          fontSize: Sizing().height(2, 3), color: whiteColor),
                    )),
              ),
              Container(
                margin: EdgeInsets.only(left: Sizing.width(2, 2)),
                padding: EdgeInsets.symmetric(
                  vertical: Sizing().height(1, 1),
                  horizontal: Sizing.width(2, 3),
                ),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2)),
                child: TextButton(
                    onPressed: () async {
                      try {
                        if (_templateName.text != "") {
                          CommonUi().showLoading();

                          try {
                            //get template and report category file for templateID
                            List<TemplateAndCategoryMapModel> mappedList = [];
                            int templateId;
                            var res = await templateAndCategoryMapService
                                .getTemplateCategoryMapping();
                            setState(() {
                              mappedList = res;
                            });
                            if (mappedList.isNotEmpty) {
                              templateId = mappedList.last.templateID ?? 0;
                            } else {
                              templateId = 0;
                            }

                            //save template and report category in file
                            reportAndTemplateMapList
                                .add(TemplateAndCategoryMapModel(
                              templateID: templateId + 1,
                              templateName: _templateName.text,
                              reportCategory: widget.reportCategory,
                            ));
                            templateAndCategoryMapService
                                .saveTemplateCategoryMapping(
                                    reportAndTemplateMapList);
                          } on Exception catch (e) {
                            errorLog.add(ErrorLogModel(
                                errorDescription: e.toString(),
                                duration: DateTime.now().toString()));
                            errorLogService.saveErrorLog(errorLog);
                          }

                          var htmlData = await widget.controller
                              .executeScript('myeditor.getData()');

                          Directory? newDirectory;
                          Directory directory =
                              await FileMethods.getSaveDirectory();
                          newDirectory = Directory(
                              '${directory.path}${widget.dirFolderName}');
                          await checkExists(newDirectory);
                          newDirectory = Directory(
                              '${directory.path}/${widget.dirFolderName}/Template');
                          await checkExists(newDirectory);

                          File file = File(
                              '${newDirectory.path}/${_templateName.text}.html');

                          file.writeAsStringSync(htmlData);
                          Navigator.of(context).pushNamed(
                            PageRouter.template,
                          );
                        } else {
                          setState(() {
                            showErrorMsg = true;
                          });
                        }
                      } on Exception catch (e) {
                        errorLog.add(ErrorLogModel(
                            errorDescription: e.toString(),
                            duration: DateTime.now().toString()));
                        errorLogService.saveErrorLog(errorLog);
                      }
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(
                          fontSize: Sizing().height(2, 3), color: whiteColor),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  checkExists(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  templateName() {
    _templateName.selection =
        TextSelection.collapsed(offset: _templateName.text.length);
    return TextFormField(
      controller: _templateName,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(2, 3)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: primaryColor,
            ),
          ),
          labelText: 'Template Name',
          labelStyle:
              TextStyle(color: Colors.grey, fontSize: Sizing().height(2, 3))),
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
        });
      },
    );
  }
}
