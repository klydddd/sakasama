import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service monitoring network connectivity status.
///
/// Exposes a stream of connectivity state and a synchronous getter.
/// Used by SyncService to trigger sync on reconnection.
class ConnectivityService {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  /// Stream of connectivity status (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _isOnline;

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _controller.add(_isOnline);

    // If we just came back online, this will be used by SyncService
    if (wasOffline && _isOnline) {
      // The stream listener in SyncService handles the trigger
    }
  }

  /// Check current connectivity (one-shot).
  Future<bool> checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  /// Dispose the subscription.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
