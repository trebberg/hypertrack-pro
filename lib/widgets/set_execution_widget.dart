// ═══════════════════════════════════════════════════════════════
// WIDGET: SetExecutionWidget - Complete with compact RIR selection
// PURPOSE: Execution phase with working RIR balk 4→0→-3
// FILE: lib/widgets/set_execution_widget.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../database/database.dart';
import '../models/exercise_set.dart';

class SetExecutionWidget extends StatefulWidget {
  final int userId;
  final int workoutId;
  final int exerciseId;
  final String exerciseName;
  final List<ExerciseSet> plannedSets;
  final Function(String message) onStatusUpdate;
  final Function(ExerciseSet setData) onSetCompleted;
  final Function(String error) onError;

  const SetExecutionWidget({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.plannedSets,
    required this.onStatusUpdate,
    required this.onSetCompleted,
    required this.onError,
  });

  @override
  State<SetExecutionWidget> createState() => _SetExecutionWidgetState();
}

class _SetExecutionWidgetState extends State<SetExecutionWidget> {
  final AppDatabase _database = AppDatabase();

  // RIR Selection State - NEEDED for user selection
  int _selectedRir = 2; // Default RIR value

  // Execution State
  Set<int> _completedSetNumbers = {}; // Track which set numbers are completed
  bool _isExecuting = false;

  // Rest Timer State
  bool _timerRunning = false;
  int _restTimerSeconds = 180;

  // Myo-Reps Settings
  var _myoRepsEnabled = true;
  int _myoRestSeconds = 15;
  int _maxMyoSets = 3;
  int _myoTargetReps = 3;
  int _myoRirThreshold = 1;

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  // RIR COLOR CODING
  Color _getRirColor(int rir) {
    if (rir >= 3) return HyperTrackTheme.successGreen; // Easy sets
    if (rir >= 1) return HyperTrackTheme.exerciseBlue; // Moderate effort
    if (rir >= 0) return HyperTrackTheme.warningOrange; // Hard sets
    return HyperTrackTheme.timerRed; // Failure/negatives
  }

  // COMPLETE SET WITH SELECTED RIR - FIXED: Don't clear all sets
  Future<void> _completeSet(ExerciseSet plannedSet) async {
    if (_isExecuting) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      // Save to database with selected RIR - FIXED: Remove userId parameter
      final setId = await _database.logNewSet(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: plannedSet.setNumber,
        weight: plannedSet.weight,
        reps: plannedSet.reps,
        repsInReserve: _selectedRir, // Uses selected RIR from balk
      );

      // Create completed set for parent callback
      final completedSet = ExerciseSet.completed(
        exerciseId: plannedSet.exerciseId,
        weight: plannedSet.weight,
        reps: plannedSet.reps,
        rir: _selectedRir,
        setNumber: plannedSet.setNumber,
      );

      // FIXED: Only mark this specific set as completed
      setState(() {
        _completedSetNumbers.add(plannedSet.setNumber);
      });

      // Notify parent container
      widget.onSetCompleted(completedSet);

      widget.onStatusUpdate(
        "Set ${plannedSet.setNumber} completed with RIR $_selectedRir",
      );

      // Check for myo-reps decision
      if (_selectedRir <= _myoRirThreshold) {
        _showMyoRepsDecision(completedSet);
      }
    } catch (e) {
      widget.onError('Failed to complete set: $e');
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Future<void> _showMyoRepsDecision(ExerciseSet completedSet) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Myo-Reps Opportunity'),
        content: Text(
          'You completed set ${completedSet.setNumber} with RIR ${completedSet.rir}. '
          'Would you like to continue with myo-reps?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, finish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, myo-reps'),
          ),
        ],
      ),
    );

    if (shouldContinue == true) {
      widget.onStatusUpdate(
        "Starting myo-reps after set ${completedSet.setNumber}",
      );
      // Future: Implement myo-reps workflow
    }
  }

  // HELPER METHODS - FIXED: Use set numbers instead of set objects
  bool _isSetCompleted(ExerciseSet set) {
    return _completedSetNumbers.contains(set.setNumber);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plannedSets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HyperTrackTheme.lightGrey),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.clock, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text(
              'No planned sets yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Add sets in the planning section above',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

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
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.gauge,
                color: HyperTrackTheme.exerciseBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Execute Sets with RIR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compact RIR Selection - FIXED: 4→0→-3, fitting in container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [4, 3, 2, 1, 0, -1, -2, -3]
                .map(
                  (rir) => GestureDetector(
                    onTap: () => setState(() => _selectedRir = rir),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedRir == rir
                            ? _getRirColor(rir)
                            : Colors.transparent,
                        border: Border.all(color: _getRirColor(rir), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          rir.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedRir == rir
                                ? Colors.white
                                : _getRirColor(rir),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Planned Sets List - FIXED: Show pending and completed separately
          Column(
            children: widget.plannedSets.map((set) {
              final isCompleted = _isSetCompleted(set);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade50 : Colors.white,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.shade300
                        : HyperTrackTheme.lightGrey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Set Number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green.shade600
                            : HyperTrackTheme.exerciseBlue.withOpacity(0.1),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                set.setNumber.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: HyperTrackTheme.exerciseBlue,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Set Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${set.weight}kg × ${set.reps} reps',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCompleted)
                            Text(
                              'Completed with RIR $_selectedRir',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Action Button
                    if (!isCompleted && !_isExecuting)
                      ElevatedButton.icon(
                        onPressed: () => _completeSet(set),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HyperTrackTheme.exerciseBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
