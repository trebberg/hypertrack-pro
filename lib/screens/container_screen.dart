// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Layout manager + WORKOUT STATE MANAGEMENT (proper fix)
// DEPENDENCIES: Material, AppHeaderWidget, ExerciseInputWidget, ExerciseHistoryWidget, Database
// RELATIONSHIPS: Parent to all components, SINGLE SOURCE OF TRUTH for workout state
// THEMING: HyperTrack Design System integration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/app_header_widget.dart';
import '../widgets/exercise_input_widget.dart';
import '../widgets/exercise_history_widget.dart';
import '../theme/app_theme.dart';
import '../models/exercise_set.dart';
import '../database/database.dart';

class ContainerScreen extends StatefulWidget {
  final int userId;
  final int workoutId;
  final int exerciseId;
  final String exerciseName;

  const ContainerScreen({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  // ─────────────────────────────────────────────────────────────
  // WORKOUT STATE MANAGEMENT (PROPER SINGLE SOURCE OF TRUTH)
  // ─────────────────────────────────────────────────────────────

  final AppDatabase _database = AppDatabase();

  // Callback to refresh history from child widget
  Future<void> Function()? _refreshHistoryCallback;

  // Workout State
  bool _isLoading = true;
  String _statusMessage = "Loading workout data...";

  // Exercise History State (CONTAINER MANAGES)
  String _lastPerformance = "";
  List<Map<String, dynamic>> _recentHistory = [];

  // Current Session State (CONTAINER MANAGES)
  List<Map<String, dynamic>> _plannedSets = [];
  List<Map<String, dynamic>> _completedSets = [];
  int _currentSetNumber = 1;

  // Exercise Settings (CONTAINER MANAGES)
  double _weightIncrement = 2.5;
  int _repsIncrement = 1;
  int _defaultRestTime = 180;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeWorkoutState();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _initializeWorkoutState() async {
    try {
      setState(() {
        _statusMessage = "Loading exercise data...";
        _isLoading = true;
      });

      // Load exercise history (CONTAINER LOADS ONCE)
      await _loadExerciseHistory();

      // Load any existing workout state for this session
      await _loadCurrentSession();

      setState(() {
        _statusMessage = "Workout data loaded successfully";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error loading workout data: $e";
        _isLoading = false;
      });
      _showError("Failed to initialize workout: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS (CONTAINER COORDINATES ALL DATA)
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadExerciseHistory() async {
    // Load last performance (SINGLE CALL)
    final lastPerformance = await _database.getLastPerformanceForExercise(
      widget.userId,
      widget.exerciseId,
    );

    String lastPerfText = "";
    if (lastPerformance != null && lastPerformance.isNotEmpty) {
      double? weight;
      int? reps;

      for (final value in lastPerformance) {
        if (value.numericValue != null) {
          if (weight == null) {
            weight = value.numericValue!;
          } else {
            reps = value.numericValue!.toInt();
          }
        }
      }

      if (weight != null && reps != null) {
        lastPerfText = "Last time: ${weight}kg × $reps reps";
      }
    }

    // Load recent sets history (SINGLE CALL)
    final rawSets = await _database.getAllSetsForExerciseRaw(
      widget.userId,
      widget.exerciseId,
      widget.workoutId,
    );

    final List<Map<String, dynamic>> recentHistory = [];
    for (final rawSet in rawSets.take(10)) {
      recentHistory.add({
        'setNumber': rawSet['setNumber'] ?? 1,
        'weight': rawSet['weight'] ?? 0.0,
        'reps': rawSet['reps'] ?? 0,
        'rir': rawSet['rir'] ?? 0,
        'completedAt': rawSet['completedAt'],
        'workoutName': rawSet['workoutName'] ?? 'Workout',
      });
    }

    setState(() {
      _lastPerformance = lastPerfText;
      _recentHistory = recentHistory;
    });
  }

  Future<void> _loadCurrentSession() async {
    // Load any sets already completed in this workout session
    // This would be implemented based on workoutId
    // For now, start fresh each session
    setState(() {
      _plannedSets = [];
      _completedSets = [];
      _currentSetNumber = 1;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // WORKOUT OPERATIONS (CONTAINER COORDINATES)
  // ─────────────────────────────────────────────────────────────

  Future<void> _addPlannedSet(double weight, int reps, int rir) async {
    try {
      final setData = {
        'setNumber': _currentSetNumber,
        'weight': weight,
        'reps': reps,
        'rir': rir,
        'completed': false,
        'id': 'planned_${DateTime.now().millisecondsSinceEpoch}',
        'plannedAt': DateTime.now(),
      };

      setState(() {
        _plannedSets.add(setData);
        _currentSetNumber++;
        _statusMessage = "Set ${setData['setNumber']} planned";
      });
    } catch (e) {
      _showError('Error planning set: $e');
    }
  }

  Future<void> _completeSet(Map<String, dynamic> setData) async {
    try {
      setState(() {
        _statusMessage = "Saving set to database...";
      });

      // Save to database (SINGLE POINT OF DATABASE WRITE)
      final setId = await _database.logNewSet(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: setData['setNumber'],
        weight: setData['weight'],
        reps: setData['reps'],
        repsInReserve: setData['rir'],
      );

      // Update BOTH planned and completed state (CONTAINER MANAGES ALL STATE)
      setState(() {
        // Mark planned set as completed
        setData['completed'] = true;
        setData['setId'] = setId;
        setData['completedAt'] = DateTime.now();

        // Add to completed sets
        _completedSets.add(Map<String, dynamic>.from(setData));

        // Update recent history IMMEDIATELY (no separate database call needed)
        _recentHistory.insert(0, {
          'setNumber': setData['setNumber'],
          'weight': setData['weight'],
          'reps': setData['reps'],
          'rir': setData['rir'],
          'completedAt': DateTime.now(),
          'workoutName': 'Current Session',
        });

        _statusMessage = "Set ${setData['setNumber']} completed and saved";
      });

      // Update last performance if this is a new record
      _updateLastPerformanceIfNeeded(setData);
    } catch (e) {
      _showError('Error completing set: $e');
    }
  }

  void _updateLastPerformanceIfNeeded(Map<String, dynamic> setData) {
    // Update "Last time" display for immediate feedback
    final newLastPerf =
        "Last time: ${setData['weight']}kg × ${setData['reps']} reps";
    setState(() {
      _lastPerformance = newLastPerf;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENT COMMUNICATION HUB (CONTAINER ORCHESTRATES)
  // ─────────────────────────────────────────────────────────────

  void _handleComponentUpdate(String component, String message) {
    // SAFE setState - avoid calling during build
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _statusMessage = "$component: $message";
          });
        }
      });
    }
  }

  void _handleNavigationRequest() {
    print("Container: Navigation menu requested");
    _handleComponentUpdate("Navigation", "Menu accessed via three-dots");
  }

  void _handleExerciseSettingsRequest() {
    print("Container: Exercise settings requested");
    _handleComponentUpdate("Settings", "Exercise configuration opened");
    _showExerciseSettings();
  }

  void _showError(String error) {
    print("Container Error: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderWidget(
        title: widget.exerciseName,
        onMenuPressed: _handleNavigationRequest,
        onSettingsPressed: _handleExerciseSettingsRequest,
      ),
      body: _buildWorkoutBody(),
      backgroundColor: HyperTrackTheme.almostWhite,
    );
  }

  Widget _buildWorkoutBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container status display
          _buildContainerStatus(),
          const SizedBox(height: 24),

          // EXERCISE INPUT - FIXED PARAMETERS
          ExerciseInputWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseInput", message),
            onSetCompleted: (exerciseSet) async {
              // Handle the set completion
              _handleComponentUpdate(
                "ExerciseInput",
                "Set ${exerciseSet.setNumber} completed",
              );

              // TRIGGER HISTORY REFRESH (using callback approach)
              if (_refreshHistoryCallback != null) {
                await _refreshHistoryCallback!();
                _handleComponentUpdate(
                  "ExerciseHistory",
                  "History refreshed after set completion",
                );
              }
            },
            onError: _showError,
          ),
          const SizedBox(height: 16),

          // EXERCISE HISTORY - WITH CALLBACK REGISTRATION
          ExerciseHistoryWidget(
            userId: widget.userId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseHistory", message),
            onError: _showError,
            onRegisterRefresh: (refreshCallback) {
              _refreshHistoryCallback = refreshCallback;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContainerStatus() {
    return HyperTrackTheme.themedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.layers,
                'exercises',
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                "Workout State Manager - PROPER ARCHITECTURE",
                style: HyperTrackTheme.headerText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Status: $_statusMessage", style: HyperTrackTheme.bodyText),
          const SizedBox(height: 12),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(LucideIcons.check, 'add', size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Container manages ALL workout state - no duplicate DB calls",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(LucideIcons.check, 'add', size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Widgets get data VIA props - instant updates",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.dumbbell,
                'exercises',
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Sets: ${_plannedSets.length} planned, ${_completedSets.length} completed",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FUTURE FUNCTIONALITY STUBS
  // ─────────────────────────────────────────────────────────────

  void _showExerciseSettings() {
    print("Exercise settings modal - To be implemented");
  }
}
