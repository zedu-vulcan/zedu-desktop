import 'package:zedu/core/core.dart';

class NavigationGroupState {
  final bool personalExpanded;
  final bool organizationExpanded;

  const NavigationGroupState({
    this.personalExpanded = true,
    this.organizationExpanded = true,
  });

  NavigationGroupState copyWith({
    bool? personalExpanded,
    bool? organizationExpanded,
  }) {
    return NavigationGroupState(
      personalExpanded: personalExpanded ?? this.personalExpanded,
      organizationExpanded: organizationExpanded ?? this.organizationExpanded,
    );
  }
}

final navigationGroupProvider =
    NotifierProvider<NavigationGroupNotifier, NavigationGroupState>(
  NavigationGroupNotifier.new,
);

class NavigationGroupNotifier extends Notifier<NavigationGroupState> {
  @override
  NavigationGroupState build() => const NavigationGroupState();

  void togglePersonal() {
    state = state.copyWith(personalExpanded: !state.personalExpanded);
  }

  void toggleOrganization() {
    state = state.copyWith(organizationExpanded: !state.organizationExpanded);
  }
}