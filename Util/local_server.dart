import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

/*
 * credit thanks to https://github.com/shah-xad/flutter_tex/blob/master/lib/src/utils/tex_view_server.dart
 */

class LocalServer {
  HttpServer? server;
  final int port;

  LocalServer(this.port);

  ///Closes the server.
  Future<void> close() async {
    if (server != null) {
      await server!.close(force: true);
      server = null;
    }
  }

  ///Starts the server
  Future<void> start(Function(HttpRequest request) request) async {
    if (server != null) {
      throw Exception('Server already started on http://localhost:$port');
    }

    var completer = new Completer();
    runZoned(() {
      HttpServer.bind('localhost', port, shared: true).then((server) {
        this.server = server;

        server.listen((HttpRequest httpRequest) async {
          request(httpRequest);
          List<int> body = [];
          var path = httpRequest.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';

          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            print(e.toString());
            httpRequest.response.close();
            return;
          }

          var contentType = ['text', 'html'];
          if (!httpRequest.requestedUri.path.endsWith('/') &&
              httpRequest.requestedUri.pathSegments.isNotEmpty) {
            var mimeType = lookupMimeType(httpRequest.requestedUri.path,
                headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }

          httpRequest.response.headers.contentType =
              new ContentType(contentType[0], contentType[1], charset: 'utf-8');
          httpRequest.response.add(body);
          httpRequest.response.close();
        });
        completer.complete();
      });
    });
    return completer.future;
  }
}

class WebSocketServer {
  HttpServer? server;
  int? port;

  WebSocketServer({this.port});

  ///Closes the server.
  Future<void> close() async {
    if (server != null) {
      await server!.close(force: true);
      server = null;
    }
  }

  ///Starts the server
  Future<void> start() async {
    if (server != null) {
      throw Exception('Server already started on http://localhost:$port');
    }
    var completer = Completer();
    runZoned(() {
      HttpServer.bind('localhost', port!, shared: true).then(
          (HttpServer server) {
        print('[+]WebSocket listening at -- ws://localhost:$port/');
        this.server = server;
        server.listen((HttpRequest request) {
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            ws.listen(
              (data) {
                print(
                    '\t\t${request.connectionInfo?.remoteAddress} -- ${data.toString()}');
                Timer(const Duration(seconds: 1), () {
                  if (ws.readyState == WebSocket.open) {
                    ws.add("dfdfdfdfdfd");
                  }
                });
              },
              onDone: () => print('[+]Done :)'),
              onError: (err) => print('[!]Error -- ${err.toString()}'),
              cancelOnError: true,
            );
            // request.response.close();
          }, onError: (err) => print('[!]Error -- ${err.toString()}'));
        }, onError: (err) => print('[!]Error -- ${err.toString()}'));
        completer.complete();
      }, onError: (err) => print('[!]Error -- ${err.toString()}'));
    });

    return completer.future;
  }
}
