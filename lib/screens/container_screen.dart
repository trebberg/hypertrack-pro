// ═══════════════════════════════════════════════════════════════
// SCREEN: ContainerScreen - Data Flow Fixed
// PURPOSE: Coordinate three-phase workflow - Planning → Execution → Display
// FIX: Clean up dubbele implementatie, fix data flow ExerciseInputWidget → SetExecutionWidget
// FILE: lib/screens/container_screen.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/exercise_input_widget.dart';
import '../widgets/set_execution_widget.dart';
import '../widgets/exercise_history_widget.dart';
import '../theme/app_theme.dart';
import '../database/database.dart';
import '../models/exercise_set.dart';

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
  // STATE MANAGEMENT - SINGLE SOURCE OF TRUTH
  // ─────────────────────────────────────────────────────────────

  final AppDatabase _database = AppDatabase();
  bool _isLoading = true;

  // THREE-PHASE WORKFLOW STATE
  List<ExerciseSet> _plannedSets = []; // Planning phase output
  List<ExerciseSet> _completedSets = []; // Execution phase output
  Future<void> Function()? _refreshHistoryCallback; // Display phase callback

  // COMMUNICATION STATE
  String _statusMessage = "Initializing workout...";
  String _lastPerformance = "";
  List<Map<String, dynamic>> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // INITIALIZATION - LOAD WORKOUT CONTEXT
  // ─────────────────────────────────────────────────────────────

  Future<void> _initializeWorkout() async {
    try {
      await _loadLastPerformance();
      setState(() {
        _isLoading = false;
        _statusMessage = "Ready for ${widget.exerciseName}";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error loading workout data: $e";
      });
    }
  }

  Future<void> _loadLastPerformance() async {
    try {
      // Use the RAW method that returns Map<String, dynamic> with weight/reps/rir
      final lastPerfData = await _database.getAllSetsForExerciseRaw(
        widget.userId,
        widget.exerciseId,
        widget.workoutId,
      );

      String lastPerfText = "First time doing this exercise";
      List<Map<String, dynamic>> recentHistory = [];

      if (lastPerfData.isNotEmpty) {
        final last = lastPerfData.first;
        lastPerfText =
            "Last: ${last['weight']}kg × ${last['reps']} reps (RIR ${last['repsInReserve'] ?? 'N/A'})";

        for (var rawSet in lastPerfData.take(5)) {
          recentHistory.add({
            'setNumber': rawSet['setNumber'] ?? 1,
            'weight': rawSet['weight'] ?? 0.0,
            'reps': rawSet['reps'] ?? 0,
            'rir': rawSet['repsInReserve'] ?? 0,
            'completedAt': rawSet['completedAt'],
            'workoutName': rawSet['workoutName'] ?? 'Workout',
          });
        }
      }

      setState(() {
        _lastPerformance = lastPerfText;
        _recentHistory = recentHistory;
      });
    } catch (e) {
      print("Container: Error loading last performance: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  // WORKFLOW COORDINATION - CLEAN THREE-PHASE PATTERN
  // ─────────────────────────────────────────────────────────────

  // PLANNING PHASE: ExerciseInputWidget → Container
  void _handleSetPlanned(ExerciseSet plannedSet) {
    if (mounted) {
      setState(() {
        _plannedSets.add(plannedSet);
      });

      _handleComponentUpdate(
        "ExerciseInput",
        "Set ${plannedSet.setNumber} planned: ${plannedSet.weight}kg × ${plannedSet.reps} reps",
      );

      print(
        "Container: Planned set added. Total planned sets: ${_plannedSets.length}",
      );
    }
  }

  // EXECUTION PHASE: SetExecutionWidget → Container
  Future<void> _handleSetCompleted(ExerciseSet completedSet) async {
    if (mounted) {
      setState(() {
        _completedSets.add(completedSet);
      });

      _handleComponentUpdate(
        "SetExecution",
        "Set ${completedSet.setNumber} completed with RIR ${completedSet.rir}",
      );

      // TRIGGER HISTORY REFRESH
      if (_refreshHistoryCallback != null) {
        try {
          await _refreshHistoryCallback!();
        } catch (e) {
          print("Container: Error refreshing history: $e");
        }
      }

      print(
        "Container: Set completed. Total completed sets: ${_completedSets.length}",
      );
    }
  }

  // DISPLAY PHASE: ExerciseHistoryWidget → Container
  void _handleHistoryRefreshRegistration(
    Future<void> Function() refreshCallback,
  ) {
    _refreshHistoryCallback = refreshCallback;
    print("Container: History refresh callback registered");
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENT COMMUNICATION HUB
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

  void _handleComponentError(String component, String error) {
    print("Container Error from $component: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$component: $error"),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATION & SETTINGS
  // ─────────────────────────────────────────────────────────────

  void _handleNavigationRequest() {
    print("Container: Navigation request");
    // Future: Implement navigation logic
  }

  void _handleExerciseSettingsRequest() {
    print("Container: Exercise settings request");
    _showExerciseSettings();
  }

  void _showExerciseSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.exerciseName} Settings'),
        content: const Text('Exercise settings will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILDER METHODS
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading workout data...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CONTAINER STATUS DISPLAY
          _buildContainerStatus(),
          const SizedBox(height: 20),

          // PLANNING PHASE - ExerciseInputWidget
          ExerciseInputWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseInput", message),
            onSetCompleted: _handleSetPlanned, // CLEAN CALLBACK
            onError: (error) => _handleComponentError("ExerciseInput", error),
          ),
          const SizedBox(height: 24),

          // EXECUTION PHASE - SetExecutionWidget
          SetExecutionWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            plannedSets: _plannedSets, // PROPS DOWN - CLEAN DATA FLOW
            onStatusUpdate: (message) =>
                _handleComponentUpdate("SetExecution", message),
            onSetCompleted: _handleSetCompleted, // CLEAN CALLBACK
            onError: (error) => _handleComponentError("SetExecution", error),
          ),
          const SizedBox(height: 24),

          // DISPLAY PHASE - ExerciseHistoryWidget
          ExerciseHistoryWidget(
            userId: widget.userId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseHistory", message),
            onError: (error) => _handleComponentError("ExerciseHistory", error),
            onRegisterRefresh:
                _handleHistoryRefreshRegistration, // CLEAN CALLBACK
          ),
        ],
      ),
    );
  }

  Widget _buildContainerStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HyperTrackTheme.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Status
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: HyperTrackTheme.exerciseBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Indicators
          Row(
            children: [
              _buildProgressChip(
                "Planned",
                _plannedSets.length,
                Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              _buildProgressChip(
                "Completed",
                _completedSets.length,
                Colors.green.shade600,
              ),
            ],
          ),

          // Last Performance
          if (_lastPerformance.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _lastPerformance,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "$label: $count",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
