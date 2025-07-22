// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget
// PURPOSE: Weight/reps/RIR input with smart history and validation
// DEPENDENCIES: Material, HyperTrackTheme, DatabaseHelper, ExerciseSet model
// RELATIONSHIPS: Child of ContainerScreen, communicates via props/callbacks
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import '../models/exercise_set.dart';

class ExerciseInputWidget extends StatefulWidget {
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
  // FORM CONTROLLERS & STATE
  // ─────────────────────────────────────────────────────────────

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedRIR = 0;
  bool _isLoading = false;
  String? _lastPerformance;
  int _currentSetNumber = 1;

  // RIR options (Rate of Perceived Exertion - reversed scale)
  final List<int> _rirOptions = [0, 1, 2, 3, 4, 5];

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSmartHistory();
    _getCurrentSetNumber();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadSmartHistory() async {
    try {
      setState(() => _isLoading = true);

      final lastSet = await DatabaseHelper.getLastPerformance(
        widget.userId,
        widget.exerciseId,
      );

      if (lastSet != null) {
        setState(() {
          _lastPerformance =
              "Last time: ${lastSet.weight}kg × ${lastSet.reps} reps (RIR ${lastSet.rir})";
        });
        widget.onStatusUpdate("Smart history loaded");
      } else {
        setState(() {
          _lastPerformance = "First time doing this exercise";
        });
      }
    } catch (e) {
      widget.onError("Failed to load exercise history: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentSetNumber() async {
    try {
      final setsCount = await DatabaseHelper.getWorkoutSetCount(
        widget.workoutId,
        widget.exerciseId,
      );
      setState(() {
        _currentSetNumber = setsCount + 1;
      });
    } catch (e) {
      widget.onError("Failed to get current set number: $e");
    }
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final exerciseSet = ExerciseSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: _currentSetNumber,
        weight: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        rir: _selectedRIR,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        isCompleted: true,
      );

      await DatabaseHelper.insertExerciseSet(exerciseSet);

      // Notify container of completion
      widget.onSetCompleted(exerciseSet);
      widget.onStatusUpdate(
        "Set $_currentSetNumber completed: ${exerciseSet.weight}kg × ${exerciseSet.reps} reps",
      );

      // Prepare for next set
      _prepareNextSet();
    } catch (e) {
      widget.onError("Failed to save set: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _prepareNextSet() {
    setState(() {
      _currentSetNumber++;
      // Keep weight, clear reps for next set
      _repsController.clear();
      _selectedRIR = 0;
    });
    widget.onStatusUpdate("Ready for set $_currentSetNumber");
  }

  // ─────────────────────────────────────────────────────────────
  // UI EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────

  void _onWeightChanged(String value) {
    // Auto-suggest weight increment logic could go here
    widget.onStatusUpdate("Weight updated: ${value}kg");
  }

  void _onRepsChanged(String value) {
    widget.onStatusUpdate("Reps updated: $value");
  }

  void _onRIRChanged(int? newRIR) {
    if (newRIR != null) {
      setState(() => _selectedRIR = newRIR);
      widget.onStatusUpdate("RIR updated: $newRIR");
    }
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Enter valid weight';
    }
    if (weight <= 0) {
      return 'Weight must be positive';
    }
    if (weight > 1000) {
      return 'Weight seems too high';
    }
    return null;
  }

  String? _validateReps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Reps required';
    }
    final reps = int.tryParse(value);
    if (reps == null) {
      return 'Enter valid reps';
    }
    if (reps <= 0) {
      return 'Reps must be positive';
    }
    if (reps > 100) {
      return 'Reps seem too high';
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return HyperTrackTheme.themedContainer(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_lastPerformance != null) _buildSmartHistory(),
            const SizedBox(height: 16),
            _buildInputFields(),
            const SizedBox(height: 20),
            _buildCompleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        HyperTrackTheme.coloredIcon(LucideIcons.dumbbell, 'exercises'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Set $_currentSetNumber", style: HyperTrackTheme.headerText),
              Text(widget.exerciseName, style: HyperTrackTheme.captionText),
            ],
          ),
        ),
        if (_isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildSmartHistory() {
    return HyperTrackTheme.outlinedCard(
      child: Row(
        children: [
          HyperTrackTheme.coloredIcon(LucideIcons.history, 'neutral'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_lastPerformance!, style: HyperTrackTheme.captionText),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Row(
      children: [
        // Weight Input
        Expanded(
          child: TextFormField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              border: const OutlineInputBorder(),
              prefixIcon: HyperTrackTheme.coloredIcon(
                LucideIcons.weight,
                'exercises',
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateWeight,
            onChanged: _onWeightChanged,
          ),
        ),
        const SizedBox(width: 12),
        // Reps Input
        Expanded(
          child: TextFormField(
            controller: _repsController,
            decoration: InputDecoration(
              labelText: 'Reps',
              border: const OutlineInputBorder(),
              prefixIcon: HyperTrackTheme.coloredIcon(
                LucideIcons.repeat,
                'exercises',
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateReps,
            onChanged: _onRepsChanged,
          ),
        ),
        const SizedBox(width: 12),
        // RIR Dropdown
        Container(
          width: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedRIR,
            decoration: const InputDecoration(
              labelText: 'RIR',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            items: _rirOptions
                .map((rir) => DropdownMenuItem(value: rir, child: Text('$rir')))
                .toList(),
            onChanged: _onRIRChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveSet,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : HyperTrackTheme.coloredIcon(
                LucideIcons.checkCircle2,
                'exercises',
              ),
        label: Text(
          _isLoading ? 'Saving...' : 'Complete Set $_currentSetNumber',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: HyperTrackTheme.getIconColor('exercises'),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
