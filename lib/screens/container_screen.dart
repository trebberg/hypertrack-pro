// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Layout manager + WORKOUT STATE MANAGEMENT (proper fix)
// DEPENDENCIES: Material, AppHeaderWidget, ExerciseInputWidget, ExerciseHistoryWidget, SetExecutionWidget, Database
// RELATIONSHIPS: Parent to all components, SINGLE SOURCE OF TRUTH for workout state
// THEMING: HyperTrack Design System integration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/app_header_widget.dart';
import '../widgets/exercise_input_widget.dart';
import '../widgets/exercise_history_widget.dart';
import '../widgets/set_execution_widget.dart';
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

  // Container state tracking
  String _statusMessage = "Initializing workout session...";
  List<ExerciseSet> _plannedSets = [];
  List<ExerciseSet> _completedSets = [];
  String _lastPerformance = "";
  List<Map<String, dynamic>> _recentHistory = [];
  bool _isLoading = true;
  int _currentSetNumber = 1;

  @override
  void initState() {
    super.initState();
    _initializeContainer();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // CONTAINER INITIALIZATION
  // ─────────────────────────────────────────────────────────────

  Future<void> _initializeContainer() async {
    await _loadLastPerformance();
    await _loadCurrentSession();
    setState(() {
      _isLoading = false;
      _statusMessage = "Workout session ready";
    });
  }

  Future<void> _loadLastPerformance() async {
    try {
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      String lastPerfText = "No previous performance";
      List<Map<String, dynamic>> recentHistory = [];

      if (lastPerformance.isNotEmpty) {
        double? weight;
        int? reps;

        for (final value in lastPerformance) {
          if (value.numericValue != null) {
            if (weight == null) {
              weight = value.numericValue!;
            } else if (reps == null) {
              reps = value.numericValue!.toInt();
              break;
            }
          }
        }

        if (weight != null && reps != null) {
          lastPerfText = "Last: ${weight}kg × $reps reps";
        }
      }

      // Get recent sets for history display
      final recentSets = await _database.getAllSetsForExerciseRaw(
        widget.userId,
        widget.exerciseId,
        widget.workoutId,
      );

      for (final rawSet in recentSets.take(5)) {
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
    } catch (e) {
      print("Container: Error loading last performance: $e");
    }
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
        _plannedSets.add(
          ExerciseSet.planned(
            exerciseId: widget.exerciseId.toString(),
            weight: weight,
            reps: reps,
            rir: rir,
            setNumber: _currentSetNumber,
          ),
        );
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

        // Add to completed sets for history
        _completedSets.add(
          ExerciseSet.completed(
            exerciseId: widget.exerciseId.toString(),
            weight: setData['weight'],
            reps: setData['reps'],
            rir: setData['rir'],
            setNumber: setData['setNumber'],
          ),
        );

        _statusMessage = "Set ${setData['setNumber']} completed and saved";
      });

      // Trigger history refresh via callback
      if (_refreshHistoryCallback != null) {
        await _refreshHistoryCallback!();
      }
    } catch (e) {
      _showError('Error completing set: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENT COMMUNICATION HUB (SINGLE COORDINATION POINT)
  // ─────────────────────────────────────────────────────────────

  void _handleComponentUpdate(String component, String message) {
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
    print("Container: Navigation request");
    // Implement navigation logic here
  }

  void _handleExerciseSettingsRequest() {
    print("Container: Exercise settings request");
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

          // EXERCISE INPUT - PLANNING PHASE
          ExerciseInputWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseInput", message),
            onSetCompleted: (exerciseSet) async {
              // Handle planned set (from ExerciseInputWidget)
              setState(() {
                _plannedSets.add(exerciseSet);
              });

              _handleComponentUpdate(
                "ExerciseInput",
                "Set ${exerciseSet.setNumber} planned: ${exerciseSet.weight}kg × ${exerciseSet.reps}",
              );
            },
            onError: (error) => _showError("ExerciseInput: $error"),
          ),
          const SizedBox(height: 20),

          // SET EXECUTION WIDGET - EXECUTION PHASE
          SetExecutionWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            plannedSets: _plannedSets,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("SetExecution", message),
            onSetCompleted: (exerciseSet) async {
              // Handle set completion
              _handleComponentUpdate(
                "SetExecution",
                "Set ${exerciseSet.setNumber} executed with RIR ${exerciseSet.rir}",
              );

              // Add to completed sets
              setState(() {
                _completedSets.add(exerciseSet);
              });

              // TRIGGER HISTORY REFRESH
              if (_refreshHistoryCallback != null) {
                await _refreshHistoryCallback!();
              }
            },
            onError: (error) => _showError("SetExecution: $error"),
          ),
          const SizedBox(height: 20),

          // EXERCISE HISTORY - DISPLAY PHASE
          ExerciseHistoryWidget(
            userId: widget.userId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseHistory", message),
            onError: (error) => _showError("ExerciseHistory: $error"),
            onRegisterRefresh: (callback) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _refreshHistoryCallback = callback;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContainerStatus() {
    return HyperTrackTheme.outlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.activity,
                'exercises',
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: HyperTrackTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.database,
                'exercises',
                size: 14,
              ),
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
