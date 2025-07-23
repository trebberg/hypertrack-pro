// ═══════════════════════════════════════════════════════════════
// WIDGET: SetExecutionWidget - Execution & Assessment Phase
// PURPOSE: Planned sets execution, RIR assessment, myo-reps workflow
// DEPENDENCIES: Material, AppDatabase, drift, HyperTrackTheme
// RELATIONSHIPS: Receives planned sets from parent, manages execution flow
// THEMING: Full HyperTrack Design System - outline + colored icons
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

  // RIR Selection State
  int _selectedRir = 2; // Default RIR for next completion

  // Execution State
  List<ExerciseSet> _completedSets = [];
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

  // RIR COLOR CODING (PRESERVED FROM ORIGINAL)
  Color _getRirColor(int rir) {
    if (rir >= 3) return HyperTrackTheme.successGreen; // Easy sets
    if (rir >= 1) return HyperTrackTheme.exerciseBlue; // Moderate effort
    if (rir >= 0) return HyperTrackTheme.warningOrange; // Hard sets
    return HyperTrackTheme.timerRed; // Failure/negatives
  }

  // UPDATE RIR SELECTION
  void _updateRir(int rir) {
    setState(() {
      _selectedRir = rir;
    });
  }

  // COMPLETE SET WITH SELECTED RIR
  Future<void> _completeSet(ExerciseSet plannedSet) async {
    if (_isExecuting) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      // Save to database with selected RIR
      final setId = await _database.logNewSet(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: plannedSet.setNumber,
        weight: plannedSet.weight,
        reps: plannedSet.reps,
        repsInReserve: _selectedRir,
      );

      // Create completed set
      final completedSet = ExerciseSet.completed(
        exerciseId: widget.exerciseId.toString(),
        weight: plannedSet.weight,
        reps: plannedSet.reps,
        rir: _selectedRir,
        setNumber: plannedSet.setNumber,
      );

      // Add to completed sets (slides down)
      setState(() {
        _completedSets.add(completedSet);
        _isExecuting = false;
      });

      widget.onSetCompleted(completedSet);
      widget.onStatusUpdate(
        "Set ${plannedSet.setNumber} completed with RIR $_selectedRir",
      );

      // Check for myo-reps
      if (_myoRepsEnabled && _selectedRir <= _myoRirThreshold) {
        _showMyoRepsDecision();
      } else {
        _startRestTimer();
      }
    } catch (e) {
      setState(() {
        _isExecuting = false;
      });
      widget.onError('Error completing set: $e');
    }
  }

  // MYO-REPS DECISION
  void _showMyoRepsDecision() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            HyperTrackTheme.coloredIcon(LucideIcons.flame, 'timer', size: 20),
            const SizedBox(width: 8),
            const Text("Myo-Reps?"),
          ],
        ),
        content: Text(
          "RIR was $_selectedRir - perfect for myo-reps!\n\nDo ${_myoRestSeconds}s mini-sets until failure?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRestTimer();
            },
            child: const Text("Just Rest"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startMyoSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HyperTrackTheme.timerRed,
            ),
            child: const Text(
              "LET'S MYO!",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // START MYO SESSION
  void _startMyoSession() {
    widget.onStatusUpdate("Myo-reps session started! ${_myoRestSeconds}s rest");
    // Start short myo rest timer
    setState(() {
      _timerRunning = true;
      _restTimerSeconds = _myoRestSeconds;
    });
    // Timer logic would go here
  }

  // START REST TIMER
  void _startRestTimer() {
    setState(() {
      _timerRunning = true;
      _restTimerSeconds = 180; // Regular rest
    });
    widget.onStatusUpdate("Rest timer started: 3:00");
    // Timer logic would go here
  }

  @override
  Widget build(BuildContext context) {
    return HyperTrackTheme.themedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.checkCircle,
                'saving',
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Execute Sets', style: HyperTrackTheme.headerText),
              const Spacer(),
              if (_timerRunning) ...[
                HyperTrackTheme.coloredIcon(
                  LucideIcons.timer,
                  'timer',
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // RIR Selection Bar (PRESERVED STYLING)
          _buildRirSelection(),
          const SizedBox(height: 16),

          // Planned Sets List
          if (widget.plannedSets.isNotEmpty) ...[
            Text('Planned Sets', style: HyperTrackTheme.captionText),
            const SizedBox(height: 8),
            ...widget.plannedSets
                .where((set) => !_isSetCompleted(set))
                .map((set) => _buildPlannedSetCard(set))
                .toList(),
            const SizedBox(height: 16),
          ],

          // Completed Sets (Slide Down)
          if (_completedSets.isNotEmpty) ...[
            Text('Completed Sets', style: HyperTrackTheme.captionText),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _completedSets.length,
                itemBuilder: (context, index) =>
                    _buildCompletedSetCard(_completedSets[index]),
              ),
            ),
          ],

          // Rest Timer Display
          if (_timerRunning) ...[const SizedBox(height: 16), _buildRestTimer()],
        ],
      ),
    );
  }

  // RIR SELECTION WITH CIRCLES (PRESERVED FROM ORIGINAL)
  Widget _buildRirSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HyperTrackTheme.coloredIcon(LucideIcons.gauge, 'timer', size: 16),
            const SizedBox(width: 6),
            Text(
              'Select RIR for next completion',
              style: HyperTrackTheme.captionText,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Compact RIR row with circles (4 to -3)
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: HyperTrackTheme.lightGrey, width: 1),
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int rir = 4; rir >= -3; rir--) ...[
                  GestureDetector(
                    onTap: () => _updateRir(rir),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: EdgeInsets.only(right: rir > -3 ? 4 : 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getRirColor(rir),
                          width: _selectedRir == rir ? 2 : 1,
                        ),
                        color: _selectedRir == rir
                            ? _getRirColor(rir)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          rir >= 0 ? '$rir' : '$rir',
                          style: HyperTrackTheme.bodyText.copyWith(
                            color: _selectedRir == rir
                                ? Colors.white
                                : HyperTrackTheme.mediumGrey,
                            fontWeight: _selectedRir == rir
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // PLANNED SET CARD WITH CHECKMARK
  Widget _buildPlannedSetCard(ExerciseSet set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: HyperTrackTheme.lightGrey, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Text(
            'Set ${set.setNumber}',
            style: HyperTrackTheme.bodyText.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${set.weight}kg × ${set.reps} reps',
            style: HyperTrackTheme.bodyText,
          ),
          const Spacer(),
          GestureDetector(
            onTap: _isExecuting ? null : () => _completeSet(set),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isExecuting
                      ? HyperTrackTheme.lightGrey
                      : HyperTrackTheme.successGreen,
                  width: 2,
                ),
              ),
              child: _isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : HyperTrackTheme.coloredIcon(
                      LucideIcons.check,
                      'saving',
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // COMPLETED SET CARD (SLIDES DOWN)
  Widget _buildCompletedSetCard(ExerciseSet set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: HyperTrackTheme.successGreen, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: HyperTrackTheme.successGreen.withOpacity(0.05),
      ),
      child: Row(
        children: [
          HyperTrackTheme.coloredIcon(
            LucideIcons.checkCircle,
            'saving',
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Set ${set.setNumber}',
            style: HyperTrackTheme.bodyText.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${set.weight}kg × ${set.reps}',
            style: HyperTrackTheme.bodyText,
          ),
          const Spacer(),
          Text(
            'RIR ${set.rir}',
            style: HyperTrackTheme.bodyText.copyWith(
              color: _getRirColor(set.rir),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // REST TIMER DISPLAY
  Widget _buildRestTimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: HyperTrackTheme.timerRed, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: HyperTrackTheme.timerRed.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HyperTrackTheme.coloredIcon(LucideIcons.timer, 'timer', size: 20),
          const SizedBox(width: 8),
          Text(
            'Rest Timer: ${_formatTimer(_restTimerSeconds)}',
            style: HyperTrackTheme.bodyText.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // HELPER METHODS
  bool _isSetCompleted(ExerciseSet set) {
    return _completedSets.any(
      (completed) => completed.setNumber == set.setNumber,
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
