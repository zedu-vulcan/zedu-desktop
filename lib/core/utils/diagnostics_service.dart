import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zedu/core/utils/logger.dart';

class DiagnosticsExportResult {
  final bool success;
  final String? filePath;
  final String? message;

  const DiagnosticsExportResult({
    required this.success,
    this.filePath,
    this.message,
  });
}

class DiagnosticsService {
  DiagnosticsService._();

  static const String appVersion = '0.1.0+1';
  static const String appName = 'Zedu Desktop';

  /// Collects OS and application environment details.
  static String getSystemInfoText() {
    final now = DateTime.now().toUtc().toIso8601String();
    return '''Zedu Desktop Diagnostics Information
====================================
Exported At: $now
Application: $appName
App Version: $appVersion
Operating System: ${Platform.operatingSystem}
OS Version: ${Platform.operatingSystemVersion}
Dart SDK Version: ${Platform.version}
Processor Count: ${Platform.numberOfProcessors}
Locale: ${Platform.localeName}
Environment: ${kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release')}
''';
  }

  /// Builds an in-memory Archive containing recent logs and system info.
  static Archive createDiagnosticsArchive() {
    final archive = Archive();

    // 1. Diagnostics information file
    final infoBytes = utf8.encode(getSystemInfoText());
    archive.addFile(
      ArchiveFile('diagnostics_info.txt', infoBytes.length, infoBytes),
    );

    // 2. Recent application logs
    final logsBytes = utf8.encode(AppLogger.recentLogsText);
    archive.addFile(
      ArchiveFile('app_logs.txt', logsBytes.length, logsBytes),
    );

    return archive;
  }

  /// Encodes the diagnostics archive into zip bytes.
  static List<int> createDiagnosticsZipBytes() {
    final archive = createDiagnosticsArchive();
    return ZipEncoder().encode(archive);
  }

  /// Prompts user with save dialog and exports the diagnostics zip file.
  static Future<DiagnosticsExportResult> exportDiagnosticsZip({
    String? overridePath,
  }) async {
    try {
      final zipBytes = createDiagnosticsZipBytes();
      if (overridePath != null) {
        final file = File(overridePath);
        await file.writeAsBytes(zipBytes);
        AppLogger.i('Diagnostics exported to $overridePath', tag: 'Diagnostics');
        return DiagnosticsExportResult(success: true, filePath: overridePath);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'zedu_diagnostics_$timestamp.zip';

      final selectedPath = await FilePicker.saveFile(
        dialogTitle: 'Export Diagnostics',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );

      if (selectedPath == null || selectedPath.isEmpty) {
        AppLogger.i('Diagnostics export cancelled by user', tag: 'Diagnostics');
        return const DiagnosticsExportResult(
          success: false,
          message: 'Export cancelled',
        );
      }

      final file = File(selectedPath);
      await file.writeAsBytes(zipBytes);
      AppLogger.i('Diagnostics exported to $selectedPath', tag: 'Diagnostics');
      return DiagnosticsExportResult(success: true, filePath: selectedPath);
    } catch (e, st) {
      AppLogger.e('Failed to export diagnostics', tag: 'Diagnostics', error: e, stackTrace: st);
      return DiagnosticsExportResult(
        success: false,
        message: 'Failed to export diagnostics: $e',
      );
    }
  }

  /// UI trigger for Export Diagnostics that shows feedback to the user.
  static Future<void> handleExportDiagnostics(BuildContext? context) async {
    final result = await exportDiagnosticsZip();
    if (context != null && context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        if (result.success) {
          final fileName = result.filePath?.split(Platform.pathSeparator).last ?? 'zip';
          messenger.showSnackBar(
            SnackBar(
              content: Text('Diagnostics exported: $fileName'),
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (result.message != null && result.message != 'Export cancelled') {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.message!),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
