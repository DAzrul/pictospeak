import 'package:flutter/foundation.dart';

void downloadCSV(String csv) {
  if (kIsWeb) {
    // nanti isi web download
    debugPrint("Web CSV download");
  } else {
    // Android/iOS
    debugPrint("Mobile CSV export");
  }
}