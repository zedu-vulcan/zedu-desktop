import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageUsage {
  final int mediaBytes;
  final int attachmentsBytes;

  const StorageUsage({
    required this.mediaBytes,
    required this.attachmentsBytes,
  });

  int get totalBytes => mediaBytes + attachmentsBytes;
}

class StorageService {
  const StorageService();

  Future<StorageUsage> calculateUsage() async {
    int media = 0;
    int attachments = 0;

    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        media += await _calculateDirSize(cacheDir);
      }
    } catch (e) {
      debugPrint('Error getting cache directory size: $e');
    }

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final attachmentsDir = Directory('${appSupportDir.path}/attachments');
      if (await attachmentsDir.exists()) {
        attachments += await _calculateDirSize(attachmentsDir);
      }
    } catch (e) {
      debugPrint('Error getting attachments directory size: $e');
    }

    return StorageUsage(
      mediaBytes: media,
      attachmentsBytes: attachments,
    );
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  Future<void> clearMediaCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing media cache: $e');
    }
  }

  Future<void> clearAttachments() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final attachmentsDir = Directory('${appSupportDir.path}/attachments');
      if (await attachmentsDir.exists()) {
        await for (final entity in attachmentsDir.list(followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error clearing attachments: $e');
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
