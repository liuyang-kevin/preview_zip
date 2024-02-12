import 'package:flutter/material.dart';
import 'package:preview_zip_website/inner_server.dart';
import 'package:webview_all/webview_all.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String folderPath = args != null ? args['folderPath'] ?? "" : "";
    return Scaffold(
      body: FutureBuilder(
          future: InnerServer.startServer(folderPath, 8080),
          builder: (context, snap) {
            return const Center(child: Webview(url: "http://127.0.0.1:8080"));
          }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
