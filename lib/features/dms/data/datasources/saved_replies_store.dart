import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A reusable message stored locally for one signed-in user.
class SavedReply {
  const SavedReply({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;

  Map<String, String> toJson() => {'id': id, 'title': title, 'body': body};

  factory SavedReply.fromJson(Map<String, dynamic> json) => SavedReply(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
  );
}

/// Resolves only known placeholders. Everything else stays editable as typed.
String renderSavedReply(String body, {required String recipient}) =>
    body.replaceAll('{{recipient}}', recipient);

final savedRepliesProvider =
    AsyncNotifierProvider<SavedRepliesNotifier, List<SavedReply>>(
      SavedRepliesNotifier.new,
      retry: (_, _) => null,
    );

class SavedRepliesNotifier extends AsyncNotifier<List<SavedReply>> {
  int _generation = 0;
  bool _saving = false;
  String _userId = '';

  String _key(String userId) => 'saved_replies_${Uri.encodeComponent(userId)}';

  @override
  Future<List<SavedReply>> build() async {
    _generation++;
    ref.onDispose(() => _generation++);
    _userId = ref.watch(
      authNotifierProvider.select((auth) => auth.user?.id ?? ''),
    );
    if (_userId.isEmpty) return const [];
    final raw = await locator<SecureStorageService>().readData(_key(_userId));
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Invalid saved replies');
    return decoded
        .map(
          (item) => SavedReply.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// Persist first, so a storage error never appears as a successful change.
  Future<void> save(SavedReply reply) => _update((items) {
    final index = items.indexWhere((item) => item.id == reply.id);
    if (index < 0) {
      items.insert(0, reply);
    } else {
      items[index] = reply;
    }
  });

  Future<void> delete(String id) =>
      _update((items) => items.removeWhere((item) => item.id == id));

  Future<void> _update(void Function(List<SavedReply>) change) async {
    if (_userId.isEmpty) throw StateError('Sign in to use saved replies');
    if (_saving) throw StateError('A saved reply is already being updated');
    final current = state.value;
    if (current == null || state.hasError || state.isLoading) {
      throw StateError('Saved replies are not ready');
    }
    final userId = _userId;
    final generation = _generation;
    final next = [...current];
    change(next);
    _saving = true;
    try {
      await locator<SecureStorageService>().writeData(
        _key(userId),
        jsonEncode(next.map((reply) => reply.toJson()).toList()),
      );
      if (ref.mounted && generation == _generation) state = AsyncData(next);
    } finally {
      _saving = false;
    }
  }
}
