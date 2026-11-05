import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/features/features.dart';

class MockDmRepository extends Mock implements DmRepository {}

void main() {
  group('ChatHistoryNotifier load errors and retry (#2655)', () {
    late MockDmRepository mockRepo;

    setUp(() {
      mockRepo = MockDmRepository();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          dmRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    }

    test('initial load failure sets hasLoadError, leaves messages empty, and retryInitialLoad recovers', () async {
      int callCount = 0;
      when(() => mockRepo.getMessages('channel-err', page: 1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Network connection refused');
        }
        return [
          {'id': 'msg-1', 'content': 'Hello world', 'userId': 'u-1', 'created_at': DateTime.now().toIso8601String()},
        ];
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatHistoryProvider('channel-err'));

      // Wait a tick for _loadInitial to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.isLoading, isFalse);
      expect(notifier.hasLoadError, isTrue);
      expect(notifier.loadError, contains('Network connection refused'));
      expect(notifier.messages, isEmpty);

      // Now retry initial load
      await notifier.retryInitialLoad();

      expect(notifier.isLoading, isFalse);
      expect(notifier.hasLoadError, isFalse);
      expect(notifier.loadError, isNull);
      expect(notifier.messages.length, equals(1));
      expect(notifier.messages.first['content'], equals('Hello world'));
    });

    test('loadMore failure sets hasLoadMoreError and retryLoadMore recovers', () async {
      final initialMessages = List.generate(
        DmRepository.pageSize,
        (i) => {'id': 'msg-$i', 'content': 'Message $i', 'userId': 'u-1'},
      );

      when(() => mockRepo.getMessages('channel-more', page: 1)).thenAnswer((_) async => initialMessages);

      int loadMoreCalls = 0;
      when(() => mockRepo.getMessages('channel-more', page: 2)).thenAnswer((_) async {
        loadMoreCalls++;
        if (loadMoreCalls == 1) {
          throw Exception('500 Internal Server Error');
        }
        return [
          {'id': 'msg-older', 'content': 'Older message', 'userId': 'u-1'},
        ];
      });

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatHistoryProvider('channel-more'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.hasLoadError, isFalse);
      expect(notifier.hasMore, isTrue);
      expect(notifier.messages.length, equals(DmRepository.pageSize));

      // Trigger loadMore which fails
      await notifier.loadMore();

      expect(notifier.hasLoadMoreError, isTrue);
      expect(notifier.loadMoreError, contains('500 Internal Server Error'));
      expect(notifier.messages.length, equals(DmRepository.pageSize));

      // Retry loadMore which now succeeds
      await notifier.retryLoadMore();

      expect(notifier.hasLoadMoreError, isFalse);
      expect(notifier.loadMoreError, isNull);
      expect(notifier.messages.length, equals(DmRepository.pageSize + 1));
      expect(notifier.messages.last['content'], equals('Older message'));
    });
  });
}
