import 'dart:developer' as dev;

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _durations = {};
  
  static void start(String operation) {
    _startTimes[operation] = DateTime.now();
    dev.log('🚀 Starting: $operation', name: 'Performance');
  }
  
  static void end(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      // Track duration history
      if (!_durations.containsKey(operation)) {
        _durations[operation] = [];
      }
      _durations[operation]!.add(duration);
      
      // Log performance
      String level = '✅';
      if (duration > 100) level = '⚠️';
      if (duration > 500) level = '🚨';
      
      dev.log('$level Completed: $operation (${duration}ms)', name: 'Performance');
      
      _startTimes.remove(operation);
    }
  }
  
  static void logStats() {
    dev.log('📊 Performance Summary:', name: 'Performance');
    for (final entry in _durations.entries) {
      final durations = entry.value;
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final max = durations.reduce((a, b) => a > b ? a : b);
      dev.log('  ${entry.key}: avg=${avg.toStringAsFixed(1)}ms, max=${max}ms, count=${durations.length}', 
              name: 'Performance');
    }
  }
  
  static T measure<T>(String operation, T Function() fn) {
    start(operation);
    try {
      return fn();
    } finally {
      end(operation);
    }
  }
}