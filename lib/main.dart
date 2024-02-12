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

import 'inner_server.dart';
import 'model/vm/global.dart';
import 'widgets/draggable_switch.dart';
import 'widgets/folder_tree_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            children: <Widget>[
              Flexible(
                child: Consumer<GlobalVM>(
                  builder: (context, value, child) {
                    print('value.folderPath ${value.folderPath}');
                    if (value.folderPath.isEmpty) return Text('拖拽');
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      // 检查文件夹是否包含index.html
                      if (!autoPreviewDone && InnerServer.hasIndexHtml(value.folderPath)) {
                        setState(() {
                          autoPreviewDone = true;
                        });
                        Navigator.pushNamed(context, '/detail', arguments: {'folderPath': value.folderPath});
                      } else {}
                    });

                    return FolderTreeView(folderPath: value.folderPath);
                  },
                ),
              ),
              Column(
                children: [
                  ExampleDragTarget(
                    onDragDone: (_) {
                      setState(() {
                        autoPreviewDone = false;
                      });
                    },
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/detail');
                      },
                      child: Text('查看详细信息'),
                    ),
                  )
                ],
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
  const ExampleDragTarget({Key? key, this.onDragDone}) : super(key: key);

  @override
  createState() => _ExampleDragTargetState();
}

class _ExampleDragTargetState extends State<ExampleDragTarget> {
  Future<void> _unzipToTempFolder(String zipFilePath) async {
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
    } catch (e) {
      print('Error extracting Zip file: $e');
    }
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
        height: 200,
        width: 200,
        color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
        child: _list.isEmpty ? const Center(child: Text("Drop here")) : Text(_list.join("\n")),
      ),
    );
  }
}
