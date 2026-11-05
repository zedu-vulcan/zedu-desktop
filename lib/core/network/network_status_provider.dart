import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

import 'package:zedu/core/core.dart';

enum NetworkStatus { online, offline }

typedef ReachabilityChecker = Future<bool> Function();

/// Provides a reachability check strategy. Defaults to resolving DNS via `InternetAddress.lookup`.
final reachabilityCheckerProvider = Provider<ReachabilityChecker>((ref) {
  return NetworkStatusNotifier.defaultReachabilityChecker;
});

class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  NetworkStatus build() {
    _checkAndSetConnectivity();
    _startListening();
    return _isOnline ? NetworkStatus.online : NetworkStatus.offline;
  }

  Future<void> _checkAndSetConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isOnline = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet);
      if (!ref.mounted) return;
      state = isOnline ? NetworkStatus.online : NetworkStatus.offline;
    } catch (_) {
      if (!ref.mounted) return;
      state = NetworkStatus.offline;
    }
  }

  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        final isOnline = result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.ethernet);
        if (!ref.mounted) return;
        state = isOnline ? NetworkStatus.online : NetworkStatus.offline;
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startMonitoring(ReachabilityChecker checker) {
    _checkTimer?.cancel();
    _checkReachability(checker);
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReachability(checker);
    });
  }

  Future<void> checkReachability([ReachabilityChecker? customChecker]) async {
    final ReachabilityChecker checker =
        customChecker ?? ref.read(reachabilityCheckerProvider);
    await _checkReachability(checker);
  }

  Future<void> _checkReachability(ReachabilityChecker checker) async {
    try {
      final isOnline = await checker();
      if (!ref.mounted) return;
      state = isOnline ? NetworkStatus.online : NetworkStatus.offline;
    } catch (_) {
      if (!ref.mounted) return;
      state = NetworkStatus.offline;
    }
  }

  void setOffline() {
    state = NetworkStatus.offline;
  }

  void setOnline() {
    state = NetworkStatus.online;
  }

  void toggle() {
    state = state == NetworkStatus.online ? NetworkStatus.offline : NetworkStatus.online;
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, NetworkStatus>(
      NetworkStatusNotifier.new,
    );