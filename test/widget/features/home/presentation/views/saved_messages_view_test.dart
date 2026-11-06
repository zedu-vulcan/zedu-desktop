import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class _FakeActiveChatNotifier extends ActiveChatNotifier {
  String? selectedName;
  String? selectedChannelId;

  @override
  ActiveChatState build() => ActiveChatState.generalChannel;

  @override
  void selectChannel(String channelName, {String? channelId}) {
    selectedName = channelName;
    selectedChannelId = channelId;
  }
}

SavedMessage _message({
  String id = 'm-1',
  String channelId = 'ch-1',
  String text = 'hello team',
  String channelName = 'general',
  DateTime? savedAt,
}) => SavedMessage(
  id: id,
  channelId: channelId,
  channelName: channelName,
  senderName: 'Ada',
  text: text,
  savedAt: savedAt ?? DateTime(2026, 11, 6, 12),
);

void main() {
  late MockSecureStorageService storage;
  late Map<String, String> values;
  late SavedMessagesStore store;

  setUp(() {
    storage = MockSecureStorageService();
    values = <String, String>{};

    when(() => storage.readData(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      return values[key];
    });
    when(() => storage.writeData(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as String;
      values[key] = value;
    });
    when(() => storage.deleteValue(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      values.remove(key);
    });
    when(() => storage.readAll()).thenAnswer((_) async => {...values});

    store = SavedMessagesStore(storage, userId: 'user-1', orgId: 'org-1');
  });

  Future<void> pumpView(
    WidgetTester tester, {
    ActiveChatNotifier Function()? activeChat,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        savedMessagesProvider.overrideWith((ref) => store),
        if (activeChat != null) activeChatProvider.overrideWith(activeChat),
      ],
      retry: (_, _) => null,
      child: buildTestMaterialApp(const Scaffold(body: SavedMessagesView())),
    ),
  );

  testWidgets('shows the empty state when nothing is saved', (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Saved messages'), findsOneWidget);
  });

  testWidgets('lists saved messages with sender and channel', (tester) async {
    await store.save(_message(id: 'm-1', text: 'first note'));
    await store.save(
      _message(
        id: 'm-2',
        channelId: 'ch-2',
        channelName: 'design',
        text: 'second note',
        savedAt: DateTime(2026, 11, 6, 13),
      ),
    );

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('first note'), findsOneWidget);
    expect(find.text('second note'), findsOneWidget);
    expect(find.text('#design'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsNothing);
  });

  testWidgets('removing a saved message updates the list', (tester) async {
    await store.save(_message(text: 'remove me'));

    await pumpView(tester);
    await tester.pumpAndSettle();
    expect(find.text('remove me'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from saved'));
    await tester.pumpAndSettle();

    expect(find.text('remove me'), findsNothing);
    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('tapping a saved message opens its channel', (tester) async {
    final activeChat = _FakeActiveChatNotifier();
    await store.save(_message(text: 'open me'));

    await pumpView(tester, activeChat: () => activeChat);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open me'));
    await tester.pumpAndSettle();

    expect(activeChat.selectedName, 'general');
    expect(activeChat.selectedChannelId, 'ch-1');
  });
}
