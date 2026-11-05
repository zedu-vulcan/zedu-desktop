import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.getAccount', () {
    test(
      'loads saved account fields from the current profile endpoint',
      () async {
        final mockApi = MockApiBaseService();
        final datasource = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(apiBaseUrl: '', usesMockData: false),
          apiBaseService: mockApi,
        );

        when(
          () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
        ).thenAnswer(
          (_) async => const ApiResponseModel<Map<String, dynamic>>(
            statusCode: 200,
            data: {
              'data': {
                'full_name': 'Test Learner',
                'email': 'learner@example.com',
                'timezone': 'Africa/Lagos',
                'display_name': 'Learner',
                'username': 'test-learner',
                'phone': '+2348000000000',
                'title': 'Student',
                'name_pronounciation': 'lear-ner',
              },
            },
          ),
        );

        final account = await datasource.getAccount();

        verify(
          () => mockApi.get<Map<String, dynamic>>(path: '/profile'),
        ).called(1);

        expect(account.name, 'Test Learner');
        expect(account.displayName, 'Learner');
        expect(account.username, 'test-learner');
        expect(account.phoneNumber, '+2348000000000');
        expect(account.title, 'Student');
        expect(account.namePronunciation, 'lear-ner');
      },
    );
  });

  group('UserProfileRemoteDataSourceImpl.updateAccount', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {'status': 'success'},
          statusCode: 200,
        ),
      );
    });

    test('sends the phone number to PATCH /profile as form data', () async {
      const account = ProfileAccount(
        name: 'Odofin Moronke',
        email: '',
        timezone: '',
        phoneNumber: '+2348012345678',
      );

      final saved = await datasource.updateAccount(account);

      final data =
          verify(
                () => mockApi.patch<Map<String, dynamic>>(
                  path: '/profile',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(Map.fromEntries(data.fields), {
        'full_name': 'Odofin Moronke',
        'phone': '+2348012345678',
      });
      expect(saved.phoneNumber, '+2348012345678');
    });
  });

  group('UserProfileRemoteDataSourceImpl notification preferences', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    const path = '/organisations/org-1/notification-preference';
    const desktop = {
      'notify_about': 'mentions',
      'send_mail': true,
      'time_range': '7:00 AM - 9:59 PM',
    };

    ApiResponseModel<Map<String, dynamic>> ok(Object data) =>
        ApiResponseModel(data: {'data': data}, statusCode: 200);

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'http://test/',
          usesMockData: false,
        ),
        apiBaseService: api,
      );
      when(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => ok(desktop));
      when(
        () => api.get<Map<String, dynamic>>(path: '/profile'),
      ).thenAnswer((_) async => ok({'timezone': 'Africa/Lagos'}));
      when(
        () => api.post<Map<String, dynamic>>(
          path: path,
          queryParameters: any(named: 'queryParameters'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok(desktop));
    });

    test('loads the desktop preferences with the profile timezone', () async {
      final preferences = await datasource.getNotificationPreferences(
        orgId: 'org-1',
      );

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.quietHoursEnabled, isTrue);
      expect(preferences.differentMobileSettings, isFalse);
      expect(preferences.timezone, 'Africa/Lagos');
      verify(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'desktop'},
        ),
      ).called(1);
    });

    test('still loads when the mobile and profile requests fail', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'mobile'},
        ),
      ).thenThrow(const ApiFailure(message: 'boom'));
      when(
        () => api.get<Map<String, dynamic>>(path: '/profile'),
      ).thenThrow(const ApiFailure(message: 'boom'));

      final preferences = await datasource.getNotificationPreferences(
        orgId: 'org-1',
      );

      expect(preferences.mode, NotificationMode.mentionsOnly);
      expect(preferences.timezone, isNull);
    });

    test('copies the settings to mobile when mobile shares them', () async {
      final saved = await datasource.updateNotificationPreferences(
        orgId: 'org-1',
        preferences: NotificationPreferences.empty(),
      );

      for (final deviceType in ['desktop', 'mobile']) {
        verify(
          () => api.post<Map<String, dynamic>>(
            path: path,
            queryParameters: {'device_type': deviceType},
            data: any(named: 'data'),
          ),
        ).called(1);
      }
      expect(saved.mode, NotificationMode.mentionsOnly);
    });

    test('leaves mobile alone when it has its own settings', () async {
      final saved = await datasource.updateNotificationPreferences(
        orgId: 'org-1',
        preferences: NotificationPreferences.empty().copyWith(
          differentMobileSettings: true,
        ),
      );

      verifyNever(
        () => api.post<Map<String, dynamic>>(
          path: path,
          queryParameters: {'device_type': 'mobile'},
          data: any(named: 'data'),
        ),
      );
      expect(saved.differentMobileSettings, isTrue);
    });

    test('fails without a selected workspace', () async {
      await expectLater(
        datasource.getNotificationPreferences(orgId: null),
        throwsA(isA<ApiFailure>()),
      );
      verifyNever(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });
  });

  group('UserProfileRemoteDataSourceImpl.getLoginAudit', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    const path = '/users/user-1/login-audit';

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: api,
      );
    });

    void stub(Map<String, dynamic> body) {
      when(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => ApiResponseModel(data: body, statusCode: 200));
    }

    test('requests the user login audit with page and limit', () async {
      stub(const {
        'data': <Map<String, dynamic>>[],
        'pagination': {
          'current_page': 2,
          'page_count': 0,
          'total_pages_count': 2,
          'total_items': 10,
        },
      });

      await datasource.getLoginAudit(userId: 'user-1', page: 2, limit: 5);

      verify(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'page': 2, 'limit': 5},
        ),
      ).called(1);
    });

    test('defaults to the first page of ten entries', () async {
      stub(const {
        'data': <Map<String, dynamic>>[],
        'pagination': <String, dynamic>{},
      });

      await datasource.getLoginAudit(userId: 'user-1');

      verify(
        () => api.get<Map<String, dynamic>>(
          path: path,
          queryParameters: {'page': 1, 'limit': 10},
        ),
      ).called(1);
    });

    test('parses the entries and the pagination envelope', () async {
      stub(const {
        'data': [
          {
            'id': 'audit-1',
            'device': 'Chrome',
            'location': 'Lagos',
            'ip_address': '102.89.0.1',
            'login_at': '2026-05-08T13:07:00Z',
            'created_at': '2026-05-08T13:07:05Z',
            'is_live': true,
          },
          {
            'id': 'audit-2',
            'device': 'Safari',
            'location': 'Abuja',
            'ip_address': '102.89.0.2',
            'login_at': null,
            'created_at': null,
            'is_live': false,
          },
        ],
        'pagination': {
          'current_page': 1,
          'page_count': 2,
          'total_pages_count': 3,
          'total_items': 25,
        },
      });

      final result = await datasource.getLoginAudit(userId: 'user-1');

      expect(result.currentPage, 1);
      expect(result.totalPages, 3);
      expect(result.hasMore, isTrue);
      expect(result.entries, hasLength(2));
      expect(result.entries.first.id, 'audit-1');
      expect(result.entries.first.device, 'Chrome');
      expect(result.entries.first.loginAt, DateTime.utc(2026, 5, 8, 13, 7));
      expect(result.entries.first.isLive, isTrue);
      expect(result.entries.last.id, 'audit-2');
      expect(result.entries.last.loginAt, isNull);
      expect(result.entries.last.isLive, isFalse);
    });

    test('returns an empty page when the envelope has no pagination', () async {
      stub(const {'data': null});

      final result = await datasource.getLoginAudit(userId: 'user-1', page: 4);

      expect(result.entries, isEmpty);
      expect(result.currentPage, 4);
      expect(result.totalPages, 0);
      expect(result.hasMore, isFalse);
    });

    test(
      'returns an empty page in mock mode without calling the API',
      () async {
        final mock = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(apiBaseUrl: '', usesMockData: true),
          apiBaseService: api,
        );

        final result = await mock.getLoginAudit(userId: 'user-1');

        expect(result.entries, isEmpty);
        expect(result.totalPages, 0);
        verifyNever(
          () => api.get<Map<String, dynamic>>(
            path: any(named: 'path'),
            queryParameters: any(named: 'queryParameters'),
          ),
        );
      },
    );
  });
}
