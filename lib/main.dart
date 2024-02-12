import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:preview_zip_website/pages/webview_page.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'inner_server.dart';
import 'key.dart';
import 'model/vm/global.dart';
import 'widgets/draggable_switch.dart';
import 'widgets/folder_tree_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/detail': (context) => const DetailPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool autoPreviewDone = false;
  bool isOpenInDetailPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拖拽并显示Zip文件路径'),
      ),
      body: ChangeNotifierProvider(
        create: (context) => GlobalVM(),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExampleDragTarget(
                      onDragDone: (_) {
                        setState(() {
                          autoPreviewDone = false;
                        });
                      },
                      onClickZipFileBtn: (folderPath) {
                        if (isOpenInDetailPage) {
                          Navigator.pushNamed(context, '/detail', arguments: {'folderPath': folderPath});
                        } else {
                          Provider.of<GlobalVM>(context, listen: false).updateUnzipFloder(folderPath);
                        }
                      },
                    ),
                    Flexible(
                      flex: 1,
                      child: Consumer<GlobalVM>(
                        builder: (context, value, child) {
                          print('value.folderPath ${value.folderPath}');
                          if (value.folderPath.isEmpty) return Text('拖拽');
                          if (isOpenInDetailPage) {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              // 检查文件夹是否包含index.html
                              if (!autoPreviewDone && InnerServer.hasIndexHtml(value.folderPath)) {
                                setState(() {
                                  autoPreviewDone = true;
                                });
                                Navigator.pushNamed(context, '/detail', arguments: {'folderPath': value.folderPath});
                              } else {}
                            });
                          }

                          return FolderTreeView(folderPath: value.folderPath);
                        },
                      ),
                    )
                  ],
                ),
              ),
              Flexible(
                flex: 5,
                child: Consumer<GlobalVM>(
                  builder: (context, value, child) {
                    Widget webviewWithServer = const Text("未实现");
                    if (value.folderPath.isEmpty) {
                      return const Text("拖拽zip预览");
                    }
                    if (Platform.isWindows) {
                      print('asdfasdfasdfasdf, ${value.folderPath}');
                      webviewWithServer = FutureBuilder(
                          future: InnerServer.startServer(value.folderPath, 8080),
                          builder: (context, snap) {
                            return const Center(child: WinBrowser());
                          });
                    }
                    return webviewWithServer;
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ExampleDragTarget extends StatefulWidget {
  final void Function(DropDoneDetails)? onDragDone;
  final void Function(String)? onClickZipFileBtn;
  const ExampleDragTarget({Key? key, this.onDragDone, this.onClickZipFileBtn}) : super(key: key);

  @override
  createState() => _ExampleDragTargetState();
}

class _ExampleDragTargetState extends State<ExampleDragTarget> {
  Future<String> _unzipToTempFolder(String zipFilePath) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      // Read the Zip file
      List<int> bytes = File(zipFilePath).readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(bytes);
      String unZipFloderPath = "";
      if (archive.isNotEmpty && !archive.first.isFile) {
        unZipFloderPath = path.join(tempPath, archive.first.name);
      }
      // Extract the contents to the temporary folder
      for (ArchiveFile file in archive) {
        String filePath = path.join(tempPath, file.name);
        // Ensure filePath is a directory before creating the file
        if (file.isFile) {
          // Create the parent directory if it doesn't exist
          Directory(path.dirname(filePath)).createSync(recursive: true);
          // Create and write the file
          File(filePath)
            ..createSync()
            ..writeAsBytesSync(file.content);
        } else {
          // print(filePath);
        }
      }

      print('Zip file extracted to: $tempPath');
      // Show a SnackBar message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('$unZipFloderPath'),
          // duration: Duration(days: 365),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dissmiss',
            textColor: Colors.yellow,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      Provider.of<GlobalVM>(context, listen: false).updateUnzipFloder(unZipFloderPath);
      return unZipFloderPath;
    } catch (e) {
      print('Error extracting Zip file: $e');
    }
    return '';
  }

  final List<XFile> _list = [];

  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        setState(() {
          _list.addAll(detail.files);
        });
        if (detail.files.isNotEmpty) {
          var file = detail.files.first;
          _unzipToTempFolder(file.path);
        }
        widget.onDragDone?.call(detail);
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 350),
        color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
        child: _list.isEmpty
            ? const Center(child: Text("Drop here"))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ..._list.map((e) => TextButton(
                        onPressed: () {
                          _unzipToTempFolder(e.path).then((path) => widget.onClickZipFileBtn?.call(path));
                        },
                        child: Text(e.name)))
                  ],
                ),
              ),
      ),
    );
  }
}
