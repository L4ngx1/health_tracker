import 'dart:async';

/// Serializes permission prompts so only one permission request runs at a time.
class PermissionQueue {
  PermissionQueue._();

  static final PermissionQueue instance = PermissionQueue._();

  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    _tail = _tail
        .catchError((_) {})
        .then((_) async {
          try {
            final result = await task();
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e, st) {
            if (!completer.isCompleted) {
              completer.completeError(e, st);
            }
          }
        });

    return completer.future;
  }
}
