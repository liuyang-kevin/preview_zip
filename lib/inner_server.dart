import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

class InnerServer {
  static HttpServer? _server;
  static String _directoryPath = '';
  static shelf.Handler? _handler;

  static Future<void> startServer(String directoryPath, int port) async {
    if (_server != null) {
      print('Server is already running on port $port, close it');
      await _server!.close(force: true);
    }

    _directoryPath = directoryPath;
    _handler = _createHandler(_directoryPath);

    // 启动新的服务器
    _server = await io.serve(_handler!, InternetAddress.anyIPv4, port);

    print('Server running on port ${_server!.port}');
  }

  static shelf.Handler _createHandler(String directoryPath) {
    return const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(createStaticHandler(directoryPath, defaultDocument: 'index.html'));
  }

  static bool hasIndexHtml(String directoryPath) {
    var directory = Directory(directoryPath);
    var files = directory.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('index.html')) {
        return true;
      }
    }
    return false;
  }
}
