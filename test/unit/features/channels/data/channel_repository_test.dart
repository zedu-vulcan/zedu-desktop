import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRemoteDataSource extends Mock
    implements ChannelRemoteDataSource {}

void main() {
  group('ChannelRepositoryImpl.joinChannel', () {
    late MockChannelRemoteDataSource datasource;
    late ChannelRepository repository;

    setUp(() {
      datasource = MockChannelRemoteDataSource();
      repository = ChannelRepositoryImpl(remoteDataSource: datasource);
    });

    test('returns success when the join completes', () async {
      when(
        () => datasource.joinChannel(channelId: 'ch-1', username: 'ada'),
      ).thenAnswer((_) async {});

      final result = await repository.joinChannel(
        channelId: 'ch-1',
        username: 'ada',
      );

      expect(result, isA<Success<void>>());
      verify(
        () => datasource.joinChannel(channelId: 'ch-1', username: 'ada'),
      ).called(1);
      verifyNoMoreInteractions(datasource);
    });

    test('preserves the API failure in the result', () async {
      const failure = ApiFailure(
        message: 'channel not found',
        kind: ApiFailureKind.notFound,
      );
      when(
        () => datasource.joinChannel(channelId: 'ch-1', username: 'ada'),
      ).thenThrow(failure);

      final result = await repository.joinChannel(
        channelId: 'ch-1',
        username: 'ada',
      );

      expect(
        result,
        isA<Failure<void>>().having(
          (value) => value.error,
          'error',
          same(failure),
        ),
      );
    });

    test(
      'wraps an unexpected error instead of throwing across layers',
      () async {
        final error = Exception('unexpected response');
        when(
          () => datasource.joinChannel(channelId: 'ch-1', username: 'ada'),
        ).thenThrow(error);

        final result = await repository.joinChannel(
          channelId: 'ch-1',
          username: 'ada',
        );

        expect(
          result,
          isA<Failure<void>>().having(
            (value) => value.error.message,
            'message',
            error.toString(),
          ),
        );
      },
    );
  });
}
