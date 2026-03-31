import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import '../widgets/premium_toast.dart';

class FileService {
  static Future<void> downloadFile({
    required BuildContext context,
    required String url,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Use flutter_file_downloader to save directly to the system's Downloads folder.
      // This is the most robust way across Android versions and avoids manual path management.
      await FileDownloader.downloadFile(
        url: url,
        name: fileName,
        onProgress: (name, progress) {
          if (onProgress != null) {
            onProgress(progress / 100); // Package provides 0-100, we expect 0-1
          }
        },
        onDownloadCompleted: (path) {
          if (context.mounted) {
            PremiumToast.show(
              context,
              title: "Download Complete",
              message: "$fileName saved to Downloads",
              type: ToastType.success,
            );
          }
        },
        onDownloadError: (error) {
          if (context.mounted) {
            PremiumToast.show(
              context,
              title: "Download Failed",
              message: error.toString(),
              type: ToastType.error,
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        PremiumToast.show(
          context,
          title: "File Error",
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }
}
