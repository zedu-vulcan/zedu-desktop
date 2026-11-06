import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Client-side storage for the messages the signed-in user kept.
///
/// One JSON list per user and org, so signing into another account or
/// workspace never shows someone else's saved messages. Mirrors the draft
/// stores: an in-memory cache for instant list rebuilds, and best-effort disk
/// writes that never break the UI.
class SavedMessagesStore extends ChangeNotifier {
  final SecureStorageService _storage;

  /// Storage key scoped to the signed-in user and org.
  final String _key;

  /// Saved messages by [SavedMessage.key], newest first when read back.
  final Map<String, SavedMessage> _items = {};

  bool _loaded = false;
  bool _disposed = false;

  SavedMessagesStore(
    this._storage, {
    required String userId,
    required String orgId,
  }) : _key = 'saved_messages_${userId}_$orgId';

  static String _userPrefix(String userId) => 'saved_messages_${userId}_';

  /// True once this store has read its list from disk.
  bool get isLoaded => _loaded;

  /// The saved messages, most recently saved first.
  List<SavedMessage> get items {
    final all = _items.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(all);
  }

  bool contains(String channelId, String messageId) =>
      _items.containsKey('$channelId|$messageId');

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Reads this user's saved messages. Safe to call more than once.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final raw = await _storage.readData(_key);
    for (final message in SavedMessage.decodeAll(raw)) {
      _items[message.key] = message;
    }
    _notify();
  }

  /// Keeps [message]. Saving the same message twice replaces the old copy
  /// rather than adding a duplicate.
  Future<void> save(SavedMessage message) async {
    if (message.id.isEmpty) return;
    _items[message.key] = message;
    _notify();
    await _persist();
  }

  Future<void> remove(String channelId, String messageId) async {
    final removed = _items.remove('$channelId|$messageId');
    if (removed == null) return;
    _notify();
    await _persist();
  }

  /// Saves [message] when it isn't saved, removes it when it is. Returns true
  /// when the message is saved afterwards.
  Future<bool> toggle(SavedMessage message) async {
    if (contains(message.channelId, message.id)) {
      await remove(message.channelId, message.id);
      return false;
    }
    await save(message);
    return true;
  }

  Future<void> _persist() async {
    try {
      await _storage.writeData(_key, SavedMessage.encodeAll(_items.values));
    } catch (_) {
      // Storage failure should not break the app; the cache stays valid.
    }
  }

  /// Deletes every saved message [userId] kept on this computer, in every org,
  /// so a saved copy of a private message doesn't outlive signing out.
  static Future<void> deleteAllForUser(
    SecureStorageService storage,
    String userId,
  ) async {
    if (userId.isEmpty) return;
    final prefix = _userPrefix(userId);
    final stored = await storage.readAll();
    for (final key in stored.keys.where((key) => key.startsWith(prefix))) {
      await storage.deleteValue(key);
    }
  }
}

final savedMessagesProvider = ChangeNotifierProvider<SavedMessagesStore>((ref) {
  // Rebuilding on a user or org change also drops the previous cache.
  final userId = ref.watch(
    authNotifierProvider.select((state) => state.user?.id ?? ''),
  );
  final orgId = ref.watch(currentOrgIdProvider);
  return SavedMessagesStore(
    locator<SecureStorageService>(),
    userId: userId,
    orgId: orgId,
  );
});
