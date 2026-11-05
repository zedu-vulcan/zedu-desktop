import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('LoginAuditEntryModel.fromJson', () {
    test('reads the backend login activity keys', () {
      final entry = LoginAuditEntryModel.fromJson(const {
        'id': 'audit-1',
        'user_id': 'user-1',
        'access_token_id': 'token-1',
        'device': 'Chrome on macOS',
        'location': 'Lagos, NG',
        'ip_address': '102.89.0.1',
        'login_at': '2026-05-08T13:07:00Z',
        'created_at': '2026-05-08T13:07:05Z',
        'is_live': true,
      });

      expect(entry.id, 'audit-1');
      expect(entry.device, 'Chrome on macOS');
      expect(entry.location, 'Lagos, NG');
      expect(entry.ipAddress, '102.89.0.1');
      expect(entry.loginAt, DateTime.utc(2026, 5, 8, 13, 7));
      expect(entry.createdAt, DateTime.utc(2026, 5, 8, 13, 7, 5));
      expect(entry.isLive, isTrue);
    });

    test('tolerates missing and null values', () {
      final entry = LoginAuditEntryModel.fromJson(const {
        'id': null,
        'device': null,
        'login_at': null,
        'is_live': null,
      });

      expect(entry.id, isEmpty);
      expect(entry.device, isEmpty);
      expect(entry.location, isEmpty);
      expect(entry.ipAddress, isEmpty);
      expect(entry.loginAt, isNull);
      expect(entry.createdAt, isNull);
      expect(entry.isLive, isFalse);
    });

    test('tolerates numbers and strings in place of the expected types', () {
      final entry = LoginAuditEntryModel.fromJson(const {
        'id': 42,
        'device': 7,
        'ip_address': 10,
        'login_at': 1778245620000,
        'created_at': 'not a date',
        'is_live': 'true',
      });

      expect(entry.id, '42');
      expect(entry.device, '7');
      expect(entry.ipAddress, '10');
      expect(
        entry.loginAt,
        DateTime.fromMillisecondsSinceEpoch(1778245620000, isUtc: true),
      );
      expect(entry.createdAt, isNull);
      expect(entry.isLive, isTrue);

      expect(
        LoginAuditEntryModel.fromJson(const {'is_live': 1}).isLive,
        isTrue,
      );
      expect(
        LoginAuditEntryModel.fromJson(const {'is_live': 'false'}).isLive,
        isFalse,
      );
      expect(
        LoginAuditEntryModel.fromJson(const {'is_live': 0}).isLive,
        isFalse,
      );
    });
  });

  group('LoginAuditPage', () {
    test('has more pages while the current page is before the last', () {
      const page = LoginAuditPage(entries: [], currentPage: 1, totalPages: 3);
      const last = LoginAuditPage(entries: [], currentPage: 3, totalPages: 3);

      expect(page.hasMore, isTrue);
      expect(last.hasMore, isFalse);
      expect(const LoginAuditPage.empty().hasMore, isFalse);
    });
  });
}
