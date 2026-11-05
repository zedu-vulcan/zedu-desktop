import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('DiagnosticsService & AppLogger', () {
    setUp(() {
      AppLogger.clearRecentLogs();
    });

    test('AppLogger captures recent logs into memory buffer', () {
      AppLogger.i('Test info log 1', tag: 'TestTag');
      AppLogger.d('Test debug log 2', tag: 'DebugTag');
      AppLogger.w('Test warning log 3');
      AppLogger.e('Test error log 4', error: 'SampleError');

      final logs = AppLogger.recentLogs;
      expect(logs.length, equals(4));
      expect(logs[0], contains('[INFO]'));
      expect(logs[0], contains('[TestTag]'));
      expect(logs[0], contains('Test info log 1'));

      expect(logs[3], contains('[ERROR]'));
      expect(logs[3], contains('SampleError'));

      expect(AppLogger.recentLogsText, contains('Test info log 1'));
      expect(AppLogger.recentLogsText, contains('Test error log 4'));
    });

    test('getSystemInfoText returns expected app and OS version details', () {
      final info = DiagnosticsService.getSystemInfoText();
      expect(info, contains('Zedu Desktop'));
      expect(info, contains('0.1.0+1'));
      expect(info, contains('Operating System: ${Platform.operatingSystem}'));
      expect(info, contains('OS Version: ${Platform.operatingSystemVersion}'));
      expect(info, contains('Dart SDK Version:'));
    });

    test('createDiagnosticsArchive produces valid archive with logs and info', () {
      AppLogger.i('Log for archive verification');

      final archive = DiagnosticsService.createDiagnosticsArchive();
      expect(archive.length, equals(2));

      final fileNames = archive.map((f) => f.name).toList();
      expect(fileNames, contains('diagnostics_info.txt'));
      expect(fileNames, contains('app_logs.txt'));

      final infoFile = archive.firstWhere((f) => f.name == 'diagnostics_info.txt');
      final infoContent = utf8.decode(infoFile.content as List<int>);
      expect(infoContent, contains('Zedu Desktop Diagnostics Information'));

      final logsFile = archive.firstWhere((f) => f.name == 'app_logs.txt');
      final logsContent = utf8.decode(logsFile.content as List<int>);
      expect(logsContent, contains('Log for archive verification'));
    });

    test('createDiagnosticsZipBytes produces valid decompressed zip data', () {
      AppLogger.i('Zip verification log');

      final zipBytes = DiagnosticsService.createDiagnosticsZipBytes();
      expect(zipBytes, isNotEmpty);

      // Verify that ZipDecoder can read the generated zip archive
      final decodedArchive = ZipDecoder().decodeBytes(zipBytes);
      expect(decodedArchive.length, equals(2));

      final names = decodedArchive.map((f) => f.name).toList();
      expect(names, contains('diagnostics_info.txt'));
      expect(names, contains('app_logs.txt'));
    });

    test('exportDiagnosticsZip writes zip to specified overridePath', () async {
      final tempDir = await Directory.systemTemp.createTemp('zedu_diag_test');
      final targetPath = '${tempDir.path}${Platform.pathSeparator}diagnostics_test.zip';

      try {
        AppLogger.i('Export file test log');
        final result = await DiagnosticsService.exportDiagnosticsZip(
          overridePath: targetPath,
        );

        expect(result.success, isTrue);
        expect(result.filePath, equals(targetPath));

        final targetFile = File(targetPath);
        expect(await targetFile.exists(), isTrue);

        final bytes = await targetFile.readAsBytes();
        final decoded = ZipDecoder().decodeBytes(bytes);
        expect(decoded.length, equals(2));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
