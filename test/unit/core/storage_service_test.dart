import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('StorageService', () {
    const service = StorageService();

    test('formatBytes formats bytes into human-readable strings', () {
      expect(StorageService.formatBytes(0), '0 B');
      expect(StorageService.formatBytes(-50), '0 B');
      expect(StorageService.formatBytes(512), '512.0 B');
      expect(StorageService.formatBytes(1024), '1.0 KB');
      expect(StorageService.formatBytes(1024 * 1024 * 5), '5.0 MB');
      expect(StorageService.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('StorageUsage calculates totalBytes', () {
      const usage = StorageUsage(mediaBytes: 1000, attachmentsBytes: 2500);
      expect(usage.totalBytes, 3500);
    });

    test('calculateUsage returns a valid StorageUsage object without throwing', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final usage = await service.calculateUsage();
      expect(usage.mediaBytes, greaterThanOrEqualTo(0));
      expect(usage.attachmentsBytes, greaterThanOrEqualTo(0));
      expect(usage.totalBytes, greaterThanOrEqualTo(0));
    });
  });
}
