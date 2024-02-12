import 'package:flutter/widgets.dart';

class GlobalVM with ChangeNotifier {
  String _folderPath = "";

  String get folderPath => _folderPath;

  void updateUnzipFloder(String path) {
    _folderPath = path;
    notifyListeners();
  }
}
