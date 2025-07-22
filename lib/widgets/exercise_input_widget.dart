// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget - HyperTrack Design System Styled
// PURPOSE: Weight/reps input, set completion (PRESERVE ALL FUNCTIONALITY)
// DEPENDENCIES: Material, AppDatabase, drift, HyperTrackTheme
// RELATIONSHIPS: Child of ContainerScreen, handles all input and save operations
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
  int _selectedRir = 2; // Default RIR

  // Focus nodes for floating label effect
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _repsFocusNode = FocusNode();

  // State (ORIGINAL LOGIC PRESERVED)
  var _isLoading = true;
  String _lastPerformance = "";
  List<Map<String, dynamic>> _plannedSets = [];
  int _currentSetNumber = 1;

  // Exercise Settings (ORIGINAL LOGIC PRESERVED)
  double _weightIncrement = 2.5; // kg
  int _repsIncrement = 1;
  int _defaultRestTime = 180; // seconds

  // Myo-Reps Settings (ORIGINAL LOGIC PRESERVED)
  var _myoRepsEnabled = true;
  int _myoRestSeconds = 15;
  int _maxMyoSets = 3;
  int _myoTargetReps = 3;
  int _myoRirThreshold = 1;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS (ORIGINAL LOGIC PRESERVED)
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Add listeners for floating label effect
    _weightFocusNode.addListener(() => setState(() {}));
    _repsFocusNode.addListener(() => setState(() {}));

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

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS (ORIGINAL LOGIC PRESERVED EXACTLY)
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadExerciseData() async {
    try {
      widget.onStatusUpdate("Loading exercise data...");

      // Load last performance for smart suggestions (ORIGINAL LOGIC)
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      if (lastPerformance != null && lastPerformance.isNotEmpty) {
        // Extract weight and reps from SetValue objects (ORIGINAL LOGIC)
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

      // Initialize planned sets for current workout (ORIGINAL LOGIC)
      _plannedSets = [
        {
          'setNumber': 1,
          'weight': 0.0,
          'reps': 0,
          'rir': 2,
          'completed': false,
        },
      ];

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

  // INPUT VALIDATION (ORIGINAL LOGIC PRESERVED)
  void _updateWeight(String value) {
    try {
      final weight = double.parse(value);
      if (weight >= 0 && weight <= 1000) {
        // Valid weight range
        _plannedSets[0]['weight'] = weight;
      }
    } catch (e) {
      // Invalid input, ignore
    }
  }

  void _updateReps(String value) {
    try {
      final reps = int.parse(value);
      if (reps >= 0 && reps <= 50) {
        // Valid reps range
        _plannedSets[0]['reps'] = reps;
      }
    } catch (e) {
      // Invalid input, ignore
    }
  }

  void _updateRir(int rir) {
    setState(() {
      _selectedRir = rir;
      _plannedSets[0]['rir'] = rir;
    });
  }

  // SET COMPLETION (ORIGINAL LOGIC PRESERVED EXACTLY)
  Future<void> _completeSet() async {
    if (_plannedSets.isEmpty) return;

    final setData = _plannedSets[0];
    if (setData['weight'] <= 0 || setData['reps'] <= 0) {
      widget.onError('Please enter valid weight and reps');
      return;
    }

    try {
      // Save to database (ORIGINAL LOGIC - NO userId parameter)
      final setId = await _database.logNewSet(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: setData['setNumber'],
        weight: setData['weight'],
        reps: setData['reps'],
        repsInReserve: setData['rir'],
      );

      // Mark as completed (ORIGINAL LOGIC)
      setState(() {
        setData['completed'] = true;
        setData['setId'] = setId;
      });

      // Create ExerciseSet for callback (maintain original interface)
      final exerciseSet = ExerciseSet.completed(
        exerciseId: widget.exerciseId.toString(),
        weight: setData['weight'],
        reps: setData['reps'],
        rir: setData['rir'],
        setNumber: setData['setNumber'],
      );

      widget.onSetCompleted(exerciseSet);
      widget.onStatusUpdate("Set ${setData['setNumber']} completed and saved");
    } catch (e) {
      widget.onError('Error completing set: $e');
    }
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
                backgroundColor: HyperTrackTheme.lightGrey.withOpacity(0.3),
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
              Text('Exercise Input', style: HyperTrackTheme.headerText),
              const Spacer(),
              // Status indicator icon
              HyperTrackTheme.coloredIcon(
                _plannedSets.isNotEmpty && _plannedSets[0]['completed']
                    ? LucideIcons.checkCircle
                    : LucideIcons.circle,
                _plannedSets.isNotEmpty && _plannedSets[0]['completed']
                    ? 'add'
                    : 'exercises',
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smart History Display
          if (_lastPerformance.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: HyperTrackTheme.mediumGrey, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: HyperTrackTheme.almostWhite,
              ),
              child: Row(
                children: [
                  HyperTrackTheme.coloredIcon(
                    LucideIcons.history,
                    'stats',
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastPerformance,
                      style: HyperTrackTheme.captionText.copyWith(
                        color: HyperTrackTheme.statsGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Weight Input (Full Width)
          _buildInputWithButtons(
            controller: _weightController,
            focusNode: _weightFocusNode,
            label: 'Weight (kg)',
            icon: LucideIcons.scale,
            onChanged: _updateWeight,
            onIncrement: _incrementWeight,
            onDecrement: _decrementWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Reps Input (Full Width)
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
          const SizedBox(height: 16),

          // RIR Selection
          _buildRirSelection(),
          const SizedBox(height: 20),

          // Complete Set Button
          _buildCompleteSetButton(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HyperTrackTheme.coloredIcon(icon, 'exercises', size: 16),
            const SizedBox(width: 6),
            Text(label, style: HyperTrackTheme.captionText),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: HyperTrackTheme.mediumGrey, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: HyperTrackTheme.bodyText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: HyperTrackTheme.captionText,
            ),
          ),
        ),
      ],
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
                            ? HyperTrackTheme.exerciseBlue.withOpacity(0.8)
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
                        color: shouldFloat
                            ? HyperTrackTheme.almostWhite
                            : Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (shouldFloat) ...[
                              HyperTrackTheme.coloredIcon(
                                icon,
                                'exercises',
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                            ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: HyperTrackTheme.mediumGrey, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Center(
          child: HyperTrackTheme.coloredIcon(
            LucideIcons.minus,
            'delete',
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: HyperTrackTheme.exerciseBlue, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: HyperTrackTheme.exerciseBlue.withOpacity(0.1),
        ),
        child: Center(
          child: HyperTrackTheme.coloredIcon(LucideIcons.plus, 'add', size: 20),
        ),
      ),
    );
  }

  // Helper methods for increment/decrement functionality
  void _incrementWeight() {
    try {
      final currentWeight = double.parse(_weightController.text);
      final newWeight = currentWeight + _weightIncrement;
      _weightController.text = newWeight.toString();
      _updateWeight(newWeight.toString());
    } catch (e) {
      // If parsing fails, start from increment value
      _weightController.text = _weightIncrement.toString();
      _updateWeight(_weightIncrement.toString());
    }
    setState(() {}); // Update floating label
  }

  void _decrementWeight() {
    try {
      final currentWeight = double.parse(_weightController.text);
      final newWeight = (currentWeight - _weightIncrement).clamp(
        0.0,
        double.infinity,
      );
      _weightController.text = newWeight.toString();
      _updateWeight(newWeight.toString());
    } catch (e) {
      // If parsing fails, set to 0
      _weightController.text = "0";
      _updateWeight("0");
    }
    setState(() {}); // Update floating label
  }

  void _incrementReps() {
    try {
      final currentReps = int.parse(_repsController.text);
      final newReps = currentReps + _repsIncrement;
      _repsController.text = newReps.toString();
      _updateReps(newReps.toString());
    } catch (e) {
      // If parsing fails, start from increment value
      _repsController.text = _repsIncrement.toString();
      _updateReps(_repsIncrement.toString());
    }
    setState(() {}); // Update floating label
  }

  void _decrementReps() {
    try {
      final currentReps = int.parse(_repsController.text);
      final newReps = (currentReps - _repsIncrement).clamp(0, 999);
      _repsController.text = newReps.toString();
      _updateReps(newReps.toString());
    } catch (e) {
      // If parsing fails, set to 0
      _repsController.text = "0";
      _updateReps("0");
    }
    setState(() {}); // Update floating label
  }

  // RIR color coding
  Color _getRirColor(int rir) {
    if (rir >= 3) return HyperTrackTheme.successGreen; // Easy sets
    if (rir >= 1) return HyperTrackTheme.exerciseBlue; // Moderate effort
    if (rir >= 0) return HyperTrackTheme.warningOrange; // Hard sets
    return HyperTrackTheme.timerRed; // Failure/negatives
  }

  Widget _buildRirSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HyperTrackTheme.coloredIcon(LucideIcons.gauge, 'timer', size: 16),
            const SizedBox(width: 6),
            Text('Reps in Reserve (RIR)', style: HyperTrackTheme.captionText),
          ],
        ),
        const SizedBox(height: 12),

        // Compact RIR row with smaller circles (4 to -3)
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
                                : FontWeight.normal,
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

  Widget _buildCompleteSetButton() {
    final isCompleted = _plannedSets.isNotEmpty && _plannedSets[0]['completed'];
    final canComplete =
        _plannedSets.isNotEmpty &&
        _plannedSets[0]['weight'] > 0 &&
        _plannedSets[0]['reps'] > 0;

    return GestureDetector(
      onTap: isCompleted ? null : (canComplete ? _completeSet : null),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: isCompleted
                ? HyperTrackTheme.successGreen
                : canComplete
                ? HyperTrackTheme.exerciseBlue
                : HyperTrackTheme.lightGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isCompleted
              ? HyperTrackTheme.successGreen.withOpacity(0.1)
              : canComplete
              ? HyperTrackTheme.exerciseBlue.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HyperTrackTheme.coloredIcon(
              isCompleted ? LucideIcons.checkCircle2 : LucideIcons.plus,
              isCompleted ? 'add' : 'exercises',
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCompleted ? 'Set Completed' : 'Complete Set',
              style: HyperTrackTheme.bodyText.copyWith(
                color: isCompleted
                    ? HyperTrackTheme.successGreen
                    : canComplete
                    ? HyperTrackTheme.exerciseBlue
                    : HyperTrackTheme.lightGrey,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
