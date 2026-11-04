import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockCreditsRepository extends Mock implements CreditsRepository {}

void main() {
  group('CreditsNotifier.load', () {
    late MockCreditsRepository repository;

    setUp(() {
      repository = MockCreditsRepository();
      when(
        repository.getPackages,
      ).thenAnswer((_) async => const Success<List<CreditPackage>>([]));
      when(
        () => repository.getUsageReport(any()),
      ).thenAnswer((_) async => const Success(CreditUsageReport.empty));
      when(
        () => repository.getTransactions(any()),
      ).thenAnswer((_) async => const Success<List<CreditTransaction>>([]));
    });

    ProviderContainer containerWith() {
      final container = ProviderContainer(
        overrides: [creditsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'an older load that finishes last does not overwrite the newer balance',
      () async {
        final slowUsage = Completer<Result<CreditUsage>>();
        when(
          () => repository.getUsage('org-a'),
        ).thenAnswer((_) => slowUsage.future);
        when(() => repository.getUsage('org-b')).thenAnswer(
          (_) async => const Success(
            CreditUsage(balance: 500, totalPurchased: 500, totalConsumed: 0),
          ),
        );

        final container = containerWith();
        final notifier = container.read(creditsNotifierProvider.notifier);

        final olderLoad = notifier.load(orgId: 'org-a');
        await notifier.load(orgId: 'org-b');

        slowUsage.complete(
          const Success(
            CreditUsage(balance: 10, totalPurchased: 10, totalConsumed: 0),
          ),
        );
        await olderLoad;

        final state = container.read(creditsNotifierProvider);
        expect(state.usage.balance, 500);
        expect(state.status, CreditsStatus.ready);
      },
    );

    test('a single load still stores its usage', () async {
      when(() => repository.getUsage('org-a')).thenAnswer(
        (_) async => const Success(
          CreditUsage(balance: 42, totalPurchased: 42, totalConsumed: 0),
        ),
      );

      final container = containerWith();
      await container
          .read(creditsNotifierProvider.notifier)
          .load(orgId: 'org-a');

      expect(container.read(creditsNotifierProvider).usage.balance, 42);
    });
  });
}
