import 'dart:async';
import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GroupDM {
  final String id;
  final String name;
  final List<TeamMember> members;
  final int unreadCount;
  final List<String> messages;

  const GroupDM({
    required this.id,
    required this.name,
    required this.members,
    this.unreadCount = 0,
    this.messages = const [],
  });

  GroupDM copyWith({
    String? id,
    String? name,
    List<TeamMember>? members,
    int? unreadCount,
    List<String>? messages,
  }) {
    return GroupDM(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDM &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          unreadCount == other.unreadCount;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ unreadCount.hashCode;
}

class GroupDmNotifier extends Notifier<List<GroupDM>> {
  final Map<String, List<String>> _offlineQueue = {};
  StreamSubscription<ChatWebsocketMessage>? _wsSubscription;
  Future<void>? _ready;
  Future<void>? _flushing;
  Future<void> _writeTail = Future<void>.value();
  String? _storageKey;

  ApiBaseService get _api => locator<ApiBaseService>();
  SecureStorageService get _storage => locator<SecureStorageService>();

  @override
  List<GroupDM> build() {
    final user = ref.watch(authNotifierProvider).user;
    final userId = user?.id;
    final orgId = user?.currentOrg;
    final key = userId == null || orgId == null
        ? null
        : 'pending_group_dms_${userId}_$orgId';

    if (key != _storageKey) {
      _storageKey = key;
      _offlineQueue.clear();
      _writeTail = Future<void>.value();
      _ready = _restoreQueue(key);
    }

    _listenToWebsockets();
    _listenToNetwork();
    return [];
  }

  Future<void> _restoreQueue(String? key) async {
    if (key == null) return;
    try {
      final raw = await _storage.readData(key);
      if (_storageKey != key || raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _offlineQueue.clear();
      for (final entry in decoded.entries) {
        if (entry.key is String && entry.value is List) {
          _offlineQueue[entry.key as String] = (entry.value as List)
              .whereType<String>()
              .toList();
        }
      }
      if (ref.mounted &&
          ref.read(networkStatusProvider) == NetworkStatus.online) {
        unawaited(_flushOfflineQueue());
      }
    } catch (error) {
      debugPrint('Could not restore pending Group DM messages: $error');
    }
  }

  Future<void> _persistQueue() {
    final key = _storageKey;
    if (key == null) {
      return Future<void>.error(StateError('No authenticated workspace'));
    }
    final snapshot = jsonEncode(_offlineQueue);
    // Serialize writes so an older snapshot cannot overwrite a newer one.
    final next = _writeTail.then((_) => _storage.writeData(key, snapshot));
    _writeTail = next.catchError((Object error) {
      debugPrint('Could not persist Group DM queue: $error');
    });
    return next;
  }

  void _listenToWebsockets() {
    _wsSubscription?.cancel();
    final ws = ref.read(chatWebsocketProvider);
    _wsSubscription = ws.messageStream.listen((msg) {
      if (!ref.mounted) return;
      _handleIncomingMessage(msg.groupDmId, msg.text);
    });
    ref.onDispose(() {
      _wsSubscription?.cancel();
      _wsSubscription = null;
    });
  }

  void _listenToNetwork() {
    ref.listen<NetworkStatus>(networkStatusProvider, (previous, next) {
      if (next == NetworkStatus.online) {
        unawaited(_flushOfflineQueue());
      }
    });
  }

  void _handleIncomingMessage(String groupId, String text) {
    if (!ref.mounted) return;
    state = [
      for (final group in state)
        if (group.id == groupId)
          group.copyWith(
            messages: [...group.messages, text],
            unreadCount: group.unreadCount + 1,
          )
        else
          group,
    ];
  }

  Future<Result<GroupDM>> createGroupDm(
    List<TeamMember> selectedMembers,
  ) async {
    final members = selectedMembers.map((m) => m.id).toSet();
    if (members.length < 2 || members.length > 9) {
      return const Failure<GroupDM>(
        ApiFailure(
          message: 'Select between 2 and 9 people.',
          kind: ApiFailureKind.client,
        ),
      );
    }

    for (final group in state) {
      final existing = group.members.map((m) => m.id).toSet();
      if (existing.length == members.length && existing.containsAll(members)) {
        return Success(group);
      }
    }

    final orgId = ref.read(authNotifierProvider).user?.currentOrg;
    if (orgId == null || orgId.isEmpty) {
      return const Failure<GroupDM>(
        ApiFailure(
          message: 'Select an organisation before creating a group.',
          kind: ApiFailureKind.client,
        ),
      );
    }

    try {
      final response = await _api.post<Map<String, dynamic>>(
        path: '/organisations/$orgId/group-dms',
        data: {
          'chat_type': 'user',
          'participants': selectedMembers.map((m) => m.id).toList(),
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiFailure(message: 'Group creation failed.');
      }
      final raw = response.data['data'];
      final channelId = raw is Map ? raw['channel_id'] : null;
      if (channelId is! String || channelId.isEmpty) {
        throw const ApiFailure(message: 'Missing server Group DM channel ID.');
      }
      final name = selectedMembers
          .map((m) => m.name ?? m.email.split('@').first)
          .join(', ');
      final group = GroupDM(
        id: channelId,
        name: name,
        members: selectedMembers,
      );
      if (!ref.mounted) {
        return Failure<GroupDM>(ApiFailure.unknown(StateError('Disposed')));
      }
      state = [...state, group];
      ref.read(chatWebsocketProvider).connect(state.map((g) => g.id).toList());
      return Success(group);
    } on ApiFailure catch (error) {
      return Failure<GroupDM>(error);
    } catch (error) {
      return Failure<GroupDM>(ApiFailure.unknown(error));
    }
  }

  Future<void> sendMessage(String groupDmId, String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty) return;
    await (_ready ?? Future<void>.value());
    if (_storageKey == null) {
      throw StateError('No authenticated workspace');
    }
    // Always persist first, including when the device appears online.
    _offlineQueue.putIfAbsent(groupDmId, () => []).add(text);
    try {
      await _persistQueue();
    } catch (_) {
      // Do not show a queued message as safely saved if storage failed.
      _offlineQueue[groupDmId]!.removeLast();
      if (_offlineQueue[groupDmId]!.isEmpty) _offlineQueue.remove(groupDmId);
      rethrow;
    }
    if (!ref.mounted) return;
    state = [
      for (final group in state)
        if (group.id == groupDmId)
          group.copyWith(messages: [...group.messages, '$text (Pending...)'])
        else
          group,
    ];
    if (ref.read(networkStatusProvider) == NetworkStatus.online) {
      await _flushOfflineQueue();
    }
  }

  Future<void> _flushOfflineQueue() {
    if (_flushing != null) return _flushing!;
    final work = _flushPending();
    _flushing = work;
    return work.whenComplete(() => _flushing = null);
  }

  Future<void> _flushPending() async {
    await (_ready ?? Future<void>.value());
    if (_storageKey == null) return;
    for (final groupId in _offlineQueue.keys.toList()) {
      while (_offlineQueue[groupId]?.isNotEmpty ?? false) {
        if (!ref.mounted ||
            ref.read(networkStatusProvider) != NetworkStatus.online) {
          return;
        }
        final text = _offlineQueue[groupId]!.first;
        try {
          final response = await _api.post<Map<String, dynamic>>(
            path: '/group-dms/channels/$groupId/threads',
            data: {'content': text, 'media': <dynamic>[]},
          );
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw ApiFailure(message: 'Send returned ${response.statusCode}');
          }
          // Remove only after successful server response.
          _offlineQueue[groupId]!.removeAt(0);
          if (_offlineQueue[groupId]!.isEmpty) _offlineQueue.remove(groupId);
          await _persistQueue();
          if (!ref.mounted) return;
          state = [
            for (final group in state)
              if (group.id == groupId)
                group.copyWith(messages: _confirmPending(group.messages, text))
              else
                group,
          ];
          await ref.read(chatStorageProvider).appendMessage(groupId, text);
        } catch (error) {
          debugPrint('Group DM delivery failed, queued for retry: $error');
          return;
        }
      }
    }
  }

  List<String> _confirmPending(List<String> messages, String text) {
    final result = List<String>.of(messages);
    final index = result.indexOf('$text (Pending...)');
    if (index != -1) result[index] = text;
    return result;
  }

  /// Allows an explicit retry after a transient server failure.
  Future<void> retryPendingMessages() => _flushOfflineQueue();

  void renameGroupDm(String groupId, String newName) {
    state = [
      for (final group in state)
        if (group.id == groupId) group.copyWith(name: newName) else group,
    ];
  }
}

final groupDmProvider = NotifierProvider<GroupDmNotifier, List<GroupDM>>(
  GroupDmNotifier.new,
);
