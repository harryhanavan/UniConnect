import 'dart:async';

/// Manages loading states for async operations across the app
class LoadingStateManager {
  static final LoadingStateManager _instance = LoadingStateManager._internal();
  factory LoadingStateManager() => _instance;
  LoadingStateManager._internal();

  final Map<String, bool> _loadingStates = {};
  final _controller = StreamController<Map<String, bool>>.broadcast();

  Stream<Map<String, bool>> get loadingStatesStream => _controller.stream;

  /// Set loading state for a specific operation
  void setLoading(String operation, bool isLoading) {
    _loadingStates[operation] = isLoading;
    _controller.add(Map.from(_loadingStates));
  }

  /// Check if a specific operation is loading
  bool isLoading(String operation) {
    return _loadingStates[operation] ?? false;
  }

  /// Check if any operation is loading
  bool get hasAnyLoading => _loadingStates.values.any((loading) => loading);

  /// Get all current loading states
  Map<String, bool> get currentStates => Map.unmodifiable(_loadingStates);

  /// Execute an async operation with automatic loading state management
  Future<T> withLoading<T>(String operation, Future<T> Function() asyncOperation) async {
    setLoading(operation, true);
    try {
      final result = await asyncOperation();
      return result;
    } finally {
      setLoading(operation, false);
    }
  }

  /// Clear all loading states
  void clearAll() {
    _loadingStates.clear();
    _controller.add({});
  }

  /// Clear loading state for specific operation
  void clear(String operation) {
    _loadingStates.remove(operation);
    _controller.add(Map.from(_loadingStates));
  }

  void dispose() {
    _controller.close();
  }
}

/// Common loading operations
class LoadingOperations {
  static const String initializingDemoData = 'initializing_demo_data';
  static const String loadingUsers = 'loading_users';
  static const String loadingSocieties = 'loading_societies';
  static const String loadingEvents = 'loading_events';
  static const String loadingCalendar = 'loading_calendar';
  static const String sendingFriendRequest = 'sending_friend_request';
  static const String acceptingFriendRequest = 'accepting_friend_request';
  static const String loadingChats = 'loading_chats';
  static const String sendingMessage = 'sending_message';
  static const String updatingLocation = 'updating_location';
  static const String joiningSociety = 'joining_society';
  static const String leavingSociety = 'leaving_society';
}