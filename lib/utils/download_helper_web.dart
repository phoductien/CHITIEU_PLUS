import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'download_helper.dart';

class WebDownloadHelper implements DownloadHelper {
  @override
  Future<void> downloadFile(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

DownloadHelper getDownloadHelper() => WebDownloadHelper();
