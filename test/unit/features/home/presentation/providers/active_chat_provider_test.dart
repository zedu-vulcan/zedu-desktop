import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ActiveChatNotifier', () {
    test('selectPeopleDirectory opens the people directory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeChatProvider).type, ActiveChatType.channel);

      container.read(activeChatProvider.notifier).selectPeopleDirectory();

      expect(
        container.read(activeChatProvider),
        ActiveChatState.peopleDirectory,
      );
    });

    test('selecting a channel leaves the people directory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(activeChatProvider.notifier);

      notifier.selectPeopleDirectory();
      notifier.selectChannel('general');

      expect(container.read(activeChatProvider), ActiveChatState.generalChannel);
    });
  });
}
