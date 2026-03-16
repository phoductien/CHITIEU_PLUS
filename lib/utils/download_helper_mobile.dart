import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'download_helper.dart';

class MobileDownloadHelper implements DownloadHelper {
  @override
  Future<void> downloadFile(Uint8List bytes, String fileName) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    final targetPath = p.join(selectedDirectory, fileName);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
  }
}

DownloadHelper getDownloadHelper() => MobileDownloadHelper();
