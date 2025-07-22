// ═══════════════════════════════════════════════════════════════
// WIDGET: SetCountingWidget
// PURPOSE: Track current set progress and display set history
// DEPENDENCIES: HyperTrackTheme, LucideIcons, ExerciseSet model
// RELATIONSHIPS: Used by ExerciseInputContainer for set progression
// THEMING: Exercise purple for current set, monotone for completed
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/exercise_set.dart';

class SetCountingWidget extends StatelessWidget {
  final int currentSetNumber;
  final int plannedTotalSets;
  final List<ExerciseSet> completedSets;
  final ExerciseSet? currentSetData;
  final Function(int setNumber) onSetSelected;
  final VoidCallback? onAddSet;
  final Function(int setNumber)? onRemoveSet;

  const SetCountingWidget({
    Key? key,
    required this.currentSetNumber,
    required this.plannedTotalSets,
    required this.completedSets,
    this.currentSetData,
    required this.onSetSelected,
    this.onAddSet,
    this.onRemoveSet,
  }) : super(key: key);

  // ─────────────────────────────────────────────────────────────
  // THEME & UI HELPERS
  // ─────────────────────────────────────────────────────────────

  Color _getExerciseColor() => HyperTrackTheme.getIconColor('exercise');

  Widget _exerciseIcon(IconData icon, {Color? color}) {
    return Icon(
      icon,
      size: 16,
      color: color ?? HyperTrackTheme.getIconColor('exercise'),
    );
  }

  bool _isSetCompleted(int setNumber) {
    return completedSets.any(
      (set) => set.setNumber == setNumber && set.isCompleted,
    );
  }

  bool _isCurrentSet(int setNumber) {
    return setNumber == currentSetNumber;
  }

  ExerciseSet? _getSetData(int setNumber) {
    try {
      return completedSets.firstWhere((set) => set.setNumber == setNumber);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          _buildSetsList(),
          if (onAddSet != null) ...[
            const SizedBox(height: 12),
            _buildSetManagementButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(LucideIcons.layers, size: 16, color: Colors.purple.shade600),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Set Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Text(
            'Set $currentSetNumber of $plannedTotalSets',
            style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (currentSetNumber - 1) / plannedTotalSets;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_getExerciseColor()),
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 12),
            HyperTrackTheme.bodyText(
              '${((progress * 100).round())}%',
              color: _getExerciseColor(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        HyperTrackTheme.captionText(
          completedSets.isEmpty
              ? 'Ready to start first set'
              : '${completedSets.length} sets completed',
        ),
      ],
    );
  }

  Widget _buildSetsList() {
    return Column(
      children: List.generate(plannedTotalSets, (index) {
        final setNumber = index + 1;
        return _buildSetItem(setNumber);
      }),
    );
  }

  Widget _buildSetItem(int setNumber) {
    final isCompleted = _isSetCompleted(setNumber);
    final isCurrent = _isCurrentSet(setNumber);
    final setData = _getSetData(setNumber);

    return GestureDetector(
      onTap: () => onSetSelected(setNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent
              ? _getExerciseColor().withOpacity(0.05)
              : isCompleted
              ? Colors.green.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? _getExerciseColor()
                : isCompleted
                ? Colors.green.shade300
                : Colors.grey.shade200,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildSetIcon(setNumber, isCompleted, isCurrent),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSetInfo(setNumber, setData, isCompleted, isCurrent),
            ),
            if (onRemoveSet != null && setNumber > 1)
              _buildRemoveSetButton(setNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildSetIcon(int setNumber, bool isCompleted, bool isCurrent) {
    IconData icon;
    Color color;

    if (isCompleted) {
      icon = LucideIcons.checkCircle2;
      color = Colors.green.shade600;
    } else if (isCurrent) {
      icon = LucideIcons.play;
      color = _getExerciseColor();
    } else {
      icon = LucideIcons.circle;
      color = Colors.grey.shade400;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildSetInfo(
    int setNumber,
    ExerciseSet? setData,
    bool isCompleted,
    bool isCurrent,
  ) {
    if (isCompleted && setData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyperTrackTheme.bodyText(
            'Set $setNumber',
            color: Colors.green.shade700,
          ),
          HyperTrackTheme.captionText(
            '${setData.weight}kg × ${setData.reps} reps @ RIR ${setData.rir}',
            color: Colors.green.shade600,
          ),
        ],
      );
    } else if (isCurrent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyperTrackTheme.bodyText(
            'Set $setNumber',
            color: _getExerciseColor(),
          ),
          HyperTrackTheme.captionText(
            currentSetData != null
                ? 'Planning: ${currentSetData!.weight}kg × ${currentSetData!.reps} reps'
                : 'Enter weight and reps below',
            color: _getExerciseColor(),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyperTrackTheme.bodyText(
            'Set $setNumber',
            color: Colors.grey.shade600,
          ),
          HyperTrackTheme.captionText(
            'Not started',
            color: Colors.grey.shade500,
          ),
        ],
      );
    }
  }

  Widget _buildRemoveSetButton(int setNumber) {
    return GestureDetector(
      onTap: () => onRemoveSet?.call(setNumber),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(LucideIcons.x, size: 14, color: Colors.red.shade600),
      ),
    );
  }

  Widget _buildSetManagementButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddSet,
            icon: _exerciseIcon(LucideIcons.plus, color: _getExerciseColor()),
            label: HyperTrackTheme.bodyText(
              'Add Set',
              color: _getExerciseColor(),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _getExerciseColor()),
            ),
          ),
        ),
        if (plannedTotalSets > 1) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: plannedTotalSets > 1
                ? () => onRemoveSet?.call(plannedTotalSets)
                : null,
            icon: Icon(LucideIcons.minus, size: 16, color: Colors.red.shade600),
            label: HyperTrackTheme.bodyText(
              'Remove',
              color: Colors.red.shade600,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ],
      ],
    );
  }
}
