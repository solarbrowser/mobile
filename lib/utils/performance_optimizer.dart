import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

/// Performance optimizer for the entire application
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  
  factory PerformanceOptimizer() => _instance;
  
  PerformanceOptimizer._internal();
  
  // Stores base memory usage to track leaks
  double? _baseMemoryUsage;
  
  // Performance tracking
  final Map<String, Stopwatch> _performanceTimers = {};
  
  // Cache registry to track and clear caches
  final Map<String, Function> _cacheCleanupCallbacks = {};
  
  /// Initialize performance optimizer
  Future<void> initialize() async {
    // Set system UI optimizations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Optimize system overlays for performance
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
      // Capture initial memory usage for leak detection
    _measureBaseMemoryUsage();
    
    // Setup periodic performance monitoring
    _setupPerformanceMonitoring();
  }
  
  /// Start timing an operation
  void startTiming(String operationName) {
    _performanceTimers[operationName] = Stopwatch()..start();
  }
  
  /// End timing an operation and return duration in ms
  int endTiming(String operationName) {
    final timer = _performanceTimers[operationName];
    if (timer == null) return -1;
    
    timer.stop();
    final duration = timer.elapsedMilliseconds;
    _performanceTimers.remove(operationName);
    
    if (kDebugMode) {
      print('Performance: $operationName took ${duration}ms');
    }
    
    return duration;
  }
  
  /// Register a cache for later cleanup
  void registerCache(String cacheName, Function cleanupCallback) {
    _cacheCleanupCallbacks[cacheName] = cleanupCallback;
  }
  
  /// Clear all registered caches
  void clearAllCaches() {
    for (final callback in _cacheCleanupCallbacks.values) {
      callback();
    }
  }
  
  /// Optimize a specific widget tree (use sparingly)
  Widget optimizeWidget(Widget child) {
    return RepaintBoundary(
      child: _OptimizedWidget(child: child),
    );
  }
  
  /// Handle low memory situation
  void _handleMemoryPressure() {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    
    // Clear all registered caches
    clearAllCaches();
    
    // Request garbage collection
    _attemptGC();
  }
  
  /// Attempt to trigger garbage collection
  void _attemptGC() {
    // Cannot force GC in Dart, but can hint
    // Create and drop large objects to encourage GC
    List<int>? largeList = List.filled(1000000, 0);
    largeList = null;
  }
  
  /// Measure base memory usage for leak detection
  Future<void> _measureBaseMemoryUsage() async {
    // Wait for app to stabilize
    await Future.delayed(const Duration(seconds: 5));
    
    try {
      // This is a best effort approximation since we cannot directly
      // measure memory usage in Flutter
      _baseMemoryUsage = 0;
      
      // Attempt GC before measuring
      _attemptGC();
    } catch (e) {
      // Ignore errors in memory measurement
    }
  }
  
  /// Setup periodic performance monitoring
  void _setupPerformanceMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      // Check for memory leaks
      _checkForMemoryLeaks();
      
      // Monitor frame rendering performance
      _checkFramePerformance();
    });
  }
  
  /// Check for potential memory leaks
  void _checkForMemoryLeaks() {
    // Best effort attempt to detect memory growth
    // Real memory leak detection would require platform-specific code
  }
  
  /// Monitor frame rendering performance
  void _checkFramePerformance() {
    final currentFrameTime = SchedulerBinding.instance.currentFrameTimeStamp;
    final lastFrameTime = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    
    if (currentFrameTime != null && lastFrameTime != null) {
      final diff = currentFrameTime - lastFrameTime;
      
      // Log slow frames (> 16ms indicates dropped frames)
      if (diff.inMilliseconds > 16 && kDebugMode) {
        print('Performance warning: Slow frame detected (${diff.inMilliseconds}ms)');
      }
    }
  }
}

/// Optimized widget with render optimizations
class _OptimizedWidget extends StatelessWidget {
  final Widget child;
  
  const _OptimizedWidget({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ExcludeSemantics(
          excluding: constraints.maxWidth == 0 || constraints.maxHeight == 0,
          child: child,
        );
      },
    );
  }
}

/// Extension methods for performance optimizations
extension PerformanceOptimizations on Widget {
  /// Applies performance optimizations to a widget
  Widget optimize() {
    return PerformanceOptimizer().optimizeWidget(this);
  }
}
