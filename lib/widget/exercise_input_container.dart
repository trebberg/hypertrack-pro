// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputContainer
// PURPOSE: Simple container for SetCountingWidget + ExerciseInputWidget
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/exercise_set.dart';
import '../widgets/set_counting_widget.dart';
import '../widgets/exercise_input_widget.dart';

class ExerciseInputContainer extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final Function(String message) onStatusUpdate;
  final Function(ExerciseSet) onSetCompleted;

  const ExerciseInputContainer({
    Key? key,
    required this.exerciseId,
    required this.exerciseName,
    required this.onStatusUpdate,
    required this.onSetCompleted,
  }) : super(key: key);

  @override
  State<ExerciseInputContainer> createState() => _ExerciseInputContainerState();
}

class _ExerciseInputContainerState extends State<ExerciseInputContainer> {
  // Set management
  int _currentSetNumber = 1;
  int _plannedTotalSets = 3;
  List<ExerciseSet> _completedSets = [];

  // Current input values
  double _currentWeight = 60.0;
  int _currentReps = 8;
  int _selectedRIR = 3;

  @override
  void initState() {
    super.initState();
    widget.onStatusUpdate('Ready for ${widget.exerciseName}');
  }

  void _onSetSelected(int setNumber) {
    setState(() {
      _currentSetNumber = setNumber;
    });
    widget.onStatusUpdate('Selected set $setNumber');
  }

  void _onAddSet() {
    setState(() {
      _plannedTotalSets += 1;
    });
    widget.onStatusUpdate('Added set $_plannedTotalSets');
  }

  void _onRemoveSet(int setNumber) {
    if (_plannedTotalSets <= 1) return;
    setState(() {
      _plannedTotalSets -= 1;
      _completedSets.removeWhere((set) => set.setNumber > _plannedTotalSets);
      if (_currentSetNumber > _plannedTotalSets) {
        _currentSetNumber = _plannedTotalSets;
      }
    });
    widget.onStatusUpdate('Removed set');
  }

  void _onValuesChanged(double weight, int reps) {
    setState(() {
      _currentWeight = weight;
      _currentReps = reps;
    });
    widget.onStatusUpdate('Set $_currentSetNumber: ${weight}kg × ${reps} reps');
  }

  void _completeCurrentSet() {
    if (_currentWeight <= 0 || _currentReps <= 0) {
      widget.onStatusUpdate('Error: Weight and reps must be greater than 0');
      return;
    }

    final completedSet = ExerciseSet(
      id: 'set_${_currentSetNumber}_${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: widget.exerciseId,
      setNumber: _currentSetNumber,
      weight: _currentWeight,
      reps: _currentReps,
      rir: _selectedRIR,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      isCompleted: true,
    );

    setState(() {
      _completedSets.removeWhere((set) => set.setNumber == _currentSetNumber);
      _completedSets.add(completedSet);
      _completedSets.sort((a, b) => a.setNumber.compareTo(b.setNumber));

      if (_currentSetNumber < _plannedTotalSets) {
        _currentSetNumber += 1;
      }
    });

    widget.onSetCompleted(completedSet);
  }

  ExerciseSet? get _currentSetData {
    return ExerciseSet(
      id: 'current',
      exerciseId: widget.exerciseId,
      setNumber: _currentSetNumber,
      weight: _currentWeight,
      reps: _currentReps,
      rir: _selectedRIR,
      createdAt: DateTime.now(),
      completedAt: null,
      isCompleted: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.dumbbell, color: Colors.purple.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Component Testing',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Set counting widget
          SetCountingWidget(
            currentSetNumber: _currentSetNumber,
            plannedTotalSets: _plannedTotalSets,
            completedSets: _completedSets,
            currentSetData: _currentSetData,
            onSetSelected: _onSetSelected,
            onAddSet: _onAddSet,
            onRemoveSet: _onRemoveSet,
          ),

          const SizedBox(height: 16),

          // Exercise input widget
          ExerciseInputWidget(
            initialWeight: _currentWeight,
            initialReps: _currentReps,
            onValuesChanged: _onValuesChanged,
            isEnabled: true,
          ),

          const SizedBox(height: 16),

          // Simple complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _completeCurrentSet,
              icon: const Icon(LucideIcons.checkCircle2),
              label: const Text('Complete Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Simple RIR placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.target,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'RIR Selection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'RIRSelectionWidget - Component 3 (Next)',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
