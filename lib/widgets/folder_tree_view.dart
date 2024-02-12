import 'dart:io';
import 'package:flutter/material.dart';

class FolderTreeView extends StatefulWidget {
  final String folderPath;

  const FolderTreeView({super.key, required this.folderPath});

  @override
  createState() => _FolderTreeViewState();
}

class _FolderTreeViewState extends State<FolderTreeView> {
  late List<FileSystemEntity> items;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    items = Directory(widget.folderPath).listSync(recursive: false);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildTreeItem(items[index]);
      },
    );
  }

  Widget _buildTreeItem(FileSystemEntity entity) {
    if (entity is File) {
      return ListTile(
        title: Text(entity.path),
        leading: Icon(Icons.insert_drive_file),
      );
    } else if (entity is Directory) {
      return ExpansionTile(
        key: PageStorageKey<FileSystemEntity>(entity),
        title: Text(entity.path),
        leading: Icon(Icons.folder),
        children: _buildChildren(entity),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  List<Widget> _buildChildren(Directory parent) {
    List<Widget> children = [];
    parent.listSync(recursive: false).forEach((entity) {
      children.add(_buildTreeItem(entity));
    });
    return children;
  }
}
