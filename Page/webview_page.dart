import 'dart:convert';
import 'dart:io';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/local_server.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class WebViewPage extends StatefulWidget {
  final String byteData;
  const WebViewPage({super.key, required this.byteData});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  int port = 5321;
  late LocalServer localServer;
  late WebviewController controller;

  @override
  void initState() {
    initServer();
    super.initState();
    loadHtmlFromAssets();
  }

  initServer() {
    localServer = LocalServer(port);
    localServer.start(handleRequest);
  }

  handleRequest(HttpRequest request) {
    try {
      if (request.method == 'GET' &&
          request.uri.queryParameters['query'] == "getRawTeXHTML") {
      } else {}
    } catch (e) {}
  }

  // loadHtmlFromAssets() async {
  //   const editor = 'assets/data/sample.html';
  //   var url = 'http://localhost:$port/$editor';
  //   controller = WebviewController();
  //   await controller.initialize();
  //   await controller.setBackgroundColor(Colors.transparent);
  //   await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
  //   print('Loading URL: $url');
  //   await controller.loadUrl(url);
  //   setState(() {});
  // }

  Future<void> loadHtmlFromAssets() async {
    final htmlContent = ''' <!DOCTYPE html>
<html>
<head>
<title>Page Title</title>
</head>
<body>

<h1>This is a Heading</h1>
<p>This is a paragraph.</p>
<img src="data:image/png;base64,${widget.byteData}" alt="Avatar" />

</body>
</html> ''';
    controller = WebviewController();
    await controller.initialize();
    await controller.loadUrl(Uri.dataFromString(
      htmlContent,
      mimeType: 'text/html',
    ).toString());
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
      body: WillPopScope(
        onWillPop: () async => false,
        child: Column(
          children: [
            Expanded(
              child: Webview(
                controller,
              ),
            ),
          ],
        ),
      ),
    );
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
      title: Text('Release and Review'),
    );
  }
}
