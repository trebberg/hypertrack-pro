// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget - HyperTrack Design System Styled
// PURPOSE: Weight/reps input, ADD SET planning (RIR assessment removed)
// DEPENDENCIES: Material, AppDatabase, drift, HyperTrackTheme
// RELATIONSHIPS: Child of ContainerScreen, handles planning via callbacks
// THEMING: Full HyperTrack Design System - outline-only aesthetic with colored icons
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../theme/app_theme.dart';
import '../database/database.dart';
import '../models/exercise_set.dart';

class ExerciseInputWidget extends StatefulWidget {
  // ORIGINAL SIGNATURE PRESERVED - NO CHANGES TO INTERFACE
  final int userId;
  final int workoutId;
  final int exerciseId;
  final String exerciseName;
  final Function(String message) onStatusUpdate;
  final Function(ExerciseSet setData) onSetCompleted;
  final Function(String error) onError;

  const ExerciseInputWidget({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.onStatusUpdate,
    required this.onSetCompleted,
    required this.onError,
  });

  @override
  State<ExerciseInputWidget> createState() => _ExerciseInputWidgetState();
}

class _ExerciseInputWidgetState extends State<ExerciseInputWidget> {
  // ─────────────────────────────────────────────────────────────
  // PRESERVED STATE FROM ORIGINAL IMPLEMENTATION
  // ─────────────────────────────────────────────────────────────

  final AppDatabase _database = AppDatabase();

  // Input Controllers (ORIGINAL LOGIC PRESERVED)
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  // Focus nodes for floating label effect
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _repsFocusNode = FocusNode();

  // State (ORIGINAL LOGIC PRESERVED)
  var _isLoading = true;
  String _lastPerformance = "";
  int _currentSetNumber = 1;

  // Exercise Settings (ORIGINAL LOGIC PRESERVED)
  double _weightIncrement = 2.5; // kg
  int _repsIncrement = 1;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    _database.close();
    super.dispose();
  }

  // PRESERVED LOAD LOGIC (ORIGINAL IMPLEMENTATION)
  Future<void> _loadExerciseData() async {
    try {
      // Load last performance (ORIGINAL LOGIC - EXACT SAME)
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      if (lastPerformance.isNotEmpty && mounted) {
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

        // Format last performance display (ORIGINAL LOGIC)
        if (weight != null && reps != null) {
          _lastPerformance = "Last time: ${weight}kg × $reps reps";
        }
      }

      setState(() {
        _isLoading = false;
      });

      widget.onStatusUpdate("Exercise data loaded successfully");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onError('Error loading exercise data: $e');
    }
  }

  // PLANNING SET (MODIFIED FOR CALLBACK APPROACH)
  void _planSet() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (weight <= 0 || reps <= 0) {
      widget.onError('Please enter valid weight and reps');
      return;
    }

    // Create planned set data (RIR will be determined after execution)
    final plannedSet = ExerciseSet.planned(
      exerciseId: widget.exerciseId.toString(),
      weight: weight,
      reps: reps,
      rir: 0, // RIR unknown during planning
      setNumber: _currentSetNumber,
    );

    // Callback to parent
    widget.onSetCompleted(plannedSet);
    widget.onStatusUpdate("Set planned: ${weight}kg × $reps reps");

    // Clear inputs and increment set number
    _clearInputs();
    _currentSetNumber++;
  }

  void _clearInputs() {
    _weightController.clear();
    _repsController.clear();
    setState(() {});
  }

  // INPUT VALIDATION (ORIGINAL LOGIC PRESERVED)
  void _updateWeight(String value) {
    setState(() {}); // Update button state
  }

  void _updateReps(String value) {
    setState(() {}); // Update button state
  }

  // +/- BUTTON LOGIC (ORIGINAL PRESERVED)
  void _incrementWeight() {
    try {
      final current = double.tryParse(_weightController.text) ?? 0.0;
      final newWeight = (current + _weightIncrement).clamp(0, 1000);
      _weightController.text = newWeight.toString();
      _updateWeight(newWeight.toString());
    } catch (e) {
      _weightController.text = _weightIncrement.toString();
      _updateWeight(_weightIncrement.toString());
    }
    setState(() {}); // Update floating label
  }

  void _decrementWeight() {
    try {
      final current = double.tryParse(_weightController.text) ?? 0.0;
      final newWeight = (current - _weightIncrement).clamp(0, 1000);
      _weightController.text = newWeight.toString();
      _updateWeight(newWeight.toString());
    } catch (e) {
      _weightController.text = "0";
      _updateWeight("0");
    }
    setState(() {}); // Update floating label
  }

  void _incrementReps() {
    try {
      final current = int.tryParse(_repsController.text) ?? 0;
      final newReps = (current + _repsIncrement).clamp(0, 999);
      _repsController.text = newReps.toString();
      _updateReps(newReps.toString());
    } catch (e) {
      _repsController.text = _repsIncrement.toString();
      _updateReps(_repsIncrement.toString());
    }
    setState(() {}); // Update floating label
  }

  void _decrementReps() {
    try {
      final current = int.tryParse(_repsController.text) ?? 0;
      final newReps = (current - _repsIncrement).clamp(0, 999);
      _repsController.text = newReps.toString();
      _updateReps(newReps.toString());
    } catch (e) {
      _repsController.text = "0";
      _updateReps("0");
    }
    setState(() {}); // Update floating label
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS - HYPERTRACK DESIGN SYSTEM IMPLEMENTATION
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return HyperTrackTheme.themedContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: HyperTrackTheme.exerciseBlue,
                backgroundColor: HyperTrackTheme.lightGrey,
              ),
              const SizedBox(height: 12),
              Text(
                "Loading exercise data...",
                style: HyperTrackTheme.captionText,
              ),
            ],
          ),
        ),
      );
    }

    return HyperTrackTheme.themedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with exercise icon
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.dumbbell,
                'exercises',
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Plan Set', style: HyperTrackTheme.headerText),
              const Spacer(),
              // Status indicator icon
              HyperTrackTheme.coloredIcon(
                LucideIcons.plus,
                'exercises',
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Last performance display (PRESERVED)
          if (_lastPerformance.isNotEmpty) ...[
            HyperTrackTheme.outlinedCard(
              child: Row(
                children: [
                  HyperTrackTheme.coloredIcon(
                    LucideIcons.history,
                    'exercises',
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(_lastPerformance, style: HyperTrackTheme.captionText),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Weight Input (PRESERVED STYLING)
          _buildInputWithButtons(
            controller: _weightController,
            focusNode: _weightFocusNode,
            label: 'Weight (kg)',
            icon: LucideIcons.dumbbell,
            onChanged: _updateWeight,
            onIncrement: _incrementWeight,
            onDecrement: _decrementWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Reps Input (PRESERVED STYLING)
          _buildInputWithButtons(
            controller: _repsController,
            focusNode: _repsFocusNode,
            label: 'Reps',
            icon: LucideIcons.repeat,
            onChanged: _updateReps,
            onIncrement: _incrementReps,
            onDecrement: _decrementReps,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ADD SET Button (MODIFIED FROM COMPLETE SET)
          _buildAddSetButton(),
        ],
      ),
    );
  }

  Widget _buildInputWithButtons({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required TextInputType keyboardType,
  }) {
    final hasValue = controller.text.isNotEmpty;
    final shouldFloat = hasValue || focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20), // More space for floating label
        Row(
          children: [
            // Decrement Button
            _buildDecrementButton(onDecrement),
            const SizedBox(width: 12),

            // Input Field with Material Design Floating Label
            Expanded(
              child: Stack(
                clipBehavior: Clip.none, // Allow label to overflow
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: HyperTrackTheme.lightGrey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (value) {
                        onChanged(value);
                        setState(() {}); // Rebuild for floating label
                      },
                      keyboardType: keyboardType,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: HyperTrackTheme.bodyText.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: HyperTrackTheme.exerciseBlue,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  // Material Design Floating Label
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: 16,
                    top: shouldFloat ? -8 : 18,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: HyperTrackTheme.captionText.copyWith(
                        fontSize: shouldFloat ? 12 : 14,
                        color: shouldFloat
                            ? HyperTrackTheme.exerciseBlue
                            : HyperTrackTheme.mediumGrey,
                        fontWeight: shouldFloat
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      child: Container(
                        padding: shouldFloat
                            ? const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              )
                            : EdgeInsets.zero,
                        color: shouldFloat ? Colors.white : Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HyperTrackTheme.coloredIcon(
                              icon,
                              'exercises',
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(label),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Increment Button
            _buildIncrementButton(onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildDecrementButton(VoidCallback onTap) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: HyperTrackTheme.lightGrey, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: HyperTrackTheme.coloredIcon(
              LucideIcons.minus,
              'exercises',
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementButton(VoidCallback onTap) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: HyperTrackTheme.lightGrey, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: HyperTrackTheme.coloredIcon(
              LucideIcons.plus,
              'exercises',
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddSetButton() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final isValid = weight > 0 && reps > 0;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isValid ? _planSet : null,
        icon: HyperTrackTheme.coloredIcon(LucideIcons.plus, 'saving', size: 20),
        label: Text(
          'ADD SET',
          style: HyperTrackTheme.bodyText.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? HyperTrackTheme.exerciseBlue
              : HyperTrackTheme.lightGrey,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
