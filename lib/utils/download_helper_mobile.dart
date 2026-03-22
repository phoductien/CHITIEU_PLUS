import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'download_helper.dart';

class MobileDownloadHelper implements DownloadHelper {
  @override
  Future<void> downloadFile(Uint8List bytes, String fileName) async {
    // 1. Ask for All Files Access permission to bypass Scoped Storage
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }

    // 2. Select Directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    // 3. Save File Directly
    final targetPath = p.join(selectedDirectory, fileName);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
  }
}

DownloadHelper getDownloadHelper() => MobileDownloadHelper();
