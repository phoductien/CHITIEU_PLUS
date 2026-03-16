import 'dart:typed_data';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

abstract class DownloadHelper {
  Future<void> downloadFile(Uint8List bytes, String fileName);
  
  static DownloadHelper get instance => getDownloadHelper();
}
