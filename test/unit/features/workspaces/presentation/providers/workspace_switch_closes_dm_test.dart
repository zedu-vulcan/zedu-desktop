import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

const _workspaceA = Workspace(
  id: 'ws-a',
  name: 'Workspace A',
  avatar: '',
  channelsCount: 1,
);
const _workspaceB = Workspace(
  id: 'ws-b',
  name: 'Workspace B',
  avatar: '',
  channelsCount: 1,
);

/// Starts on workspace A without loading organisations from the API, but
/// keeps the real switchWorkspace.
class _LoadedWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [_workspaceA, _workspaceB],
    selectedWorkspace: _workspaceA,
  );
}

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [workspaceProvider.overrideWith(_LoadedWorkspaceNotifier.new)],
    );
    addTearDown(container.dispose);
    container
        .read(selectedDmProvider.notifier)
        .select(
          DmConversation(
            channelId: 'dm-1',
            username: 'Ada',
            participantId: 'user-2',
            previewMessage: 'Hi',
            unreadCount: 0,
          ),
        );
    return container;
  }

  test('switching workspace closes the open DM (#1442)', () async {
    final container = makeContainer();
    expect(container.read(selectedDmProvider)?.channelId, 'dm-1');

    await container
        .read(workspaceProvider.notifier)
        .switchWorkspace(_workspaceB);

    expect(container.read(workspaceProvider).selectedWorkspace?.id, 'ws-b');
    expect(container.read(selectedDmProvider), isNull);
  });

  test('picking the workspace already open keeps the DM open', () async {
    final container = makeContainer();

    await container
        .read(workspaceProvider.notifier)
        .switchWorkspace(_workspaceA);

    expect(container.read(selectedDmProvider)?.channelId, 'dm-1');
  });
}
