// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget
// PURPOSE: Weight and reps input fields with increment/decrement controls
// DEPENDENCIES: HyperTrackTheme, LucideIcons
// RELATIONSHIPS: Used by ExerciseInputContainer for data entry
// THEMING: Exercise purple accents, monotone input styling
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class ExerciseInputWidget extends StatefulWidget {
  final double initialWeight;
  final int initialReps;
  final double weightIncrement;
  final int repsIncrement;
  final double minimumWeight;
  final int minimumReps;
  final Function(double weight, int reps) onValuesChanged;
  final VoidCallback? onWeightFocused;
  final VoidCallback? onRepsFocused;
  final bool isEnabled;
  final String? validationError;

  const ExerciseInputWidget({
    Key? key,
    required this.initialWeight,
    required this.initialReps,
    required this.onValuesChanged,
    this.weightIncrement = 2.5,
    this.repsIncrement = 1,
    this.minimumWeight = 2.5,
    this.minimumReps = 1,
    this.onWeightFocused,
    this.onRepsFocused,
    this.isEnabled = true,
    this.validationError,
  }) : super(key: key);

  @override
  State<ExerciseInputWidget> createState() => _ExerciseInputWidgetState();
}

class _ExerciseInputWidgetState extends State<ExerciseInputWidget> {
  // ─────────────────────────────────────────────────────────────
  // CONSTRUCTOR & PROPERTIES
  // ─────────────────────────────────────────────────────────────

  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late double _currentWeight;
  late int _currentReps;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight;
    _currentReps = widget.initialReps;

    _weightController = TextEditingController(
      text: _formatWeight(_currentWeight),
    );
    _repsController = TextEditingController(text: _currentReps.toString());
  }

  @override
  void didUpdateWidget(ExerciseInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers if initial values changed
    if (oldWidget.initialWeight != widget.initialWeight) {
      _currentWeight = widget.initialWeight;
      _weightController.text = _formatWeight(_currentWeight);
    }

    if (oldWidget.initialReps != widget.initialReps) {
      _currentReps = widget.initialReps;
      _repsController.text = _currentReps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // THEME & UI HELPERS
  // ─────────────────────────────────────────────────────────────

  Color _getExerciseColor() => HyperTrackTheme.getIconColor('exercise');

  Widget _exerciseIcon(IconData icon) {
    return HyperTrackTheme.coloredIcon(icon, 'exercise');
  }

  String _formatWeight(double weight) {
    return weight.toStringAsFixed(1).replaceAll('.0', '');
  }

  bool _canDecrementWeight() {
    return widget.isEnabled && _currentWeight > widget.minimumWeight;
  }

  bool _canDecrementReps() {
    return widget.isEnabled && _currentReps > widget.minimumReps;
  }

  // ─────────────────────────────────────────────────────────────
  // INPUT HANDLERS
  // ─────────────────────────────────────────────────────────────

  void _onWeightChanged(String value) {
    final weight = double.tryParse(value);
    if (weight != null && weight >= 0) {
      setState(() => _currentWeight = weight);
      _notifyValuesChanged();
    }
  }

  void _onRepsChanged(String value) {
    final reps = int.tryParse(value);
    if (reps != null && reps >= 0) {
      setState(() => _currentReps = reps);
      _notifyValuesChanged();
    }
  }

  void _incrementWeight() {
    if (!widget.isEnabled) return;
    setState(() {
      _currentWeight += widget.weightIncrement;
      _weightController.text = _formatWeight(_currentWeight);
    });
    _notifyValuesChanged();
  }

  void _decrementWeight() {
    if (!_canDecrementWeight()) return;
    setState(() {
      _currentWeight -= widget.weightIncrement;
      _weightController.text = _formatWeight(_currentWeight);
    });
    _notifyValuesChanged();
  }

  void _incrementReps() {
    if (!widget.isEnabled) return;
    setState(() {
      _currentReps += widget.repsIncrement;
      _repsController.text = _currentReps.toString();
    });
    _notifyValuesChanged();
  }

  void _decrementReps() {
    if (!_canDecrementReps()) return;
    setState(() {
      _currentReps -= widget.repsIncrement;
      _repsController.text = _currentReps.toString();
    });
    _notifyValuesChanged();
  }

  void _notifyValuesChanged() {
    widget.onValuesChanged(_currentWeight, _currentReps);
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return HyperTrackTheme.outlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildWeightInput(),
            const SizedBox(height: 16),
            _buildRepsInput(),
            if (widget.validationError != null) ...[
              const SizedBox(height: 12),
              _buildValidationError(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(LucideIcons.edit3, size: 16, color: Colors.purple.shade600),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Weight & Reps',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDecrementButton(
              onTap: _decrementWeight,
              canDecrement: _canDecrementWeight(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                enabled: widget.isEnabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  suffixText: 'kg',
                  prefixIcon: _exerciseIcon(LucideIcons.dumbbell),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _getExerciseColor()),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: _onWeightChanged,
                onTap: widget.onWeightFocused,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getExerciseColor(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildIncrementButton(onTap: _incrementWeight),
          ],
        ),
      ],
    );
  }

  Widget _buildRepsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reps',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDecrementButton(
              onTap: _decrementReps,
              canDecrement: _canDecrementReps(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _repsController,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  suffixText: 'reps',
                  prefixIcon: _exerciseIcon(LucideIcons.hash),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _getExerciseColor()),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: _onRepsChanged,
                onTap: widget.onRepsFocused,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getExerciseColor(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildIncrementButton(onTap: _incrementReps),
          ],
        ),
      ],
    );
  }

  Widget _buildDecrementButton({
    required VoidCallback onTap,
    required bool canDecrement,
  }) {
    return GestureDetector(
      onTap: canDecrement ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: canDecrement ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canDecrement ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          LucideIcons.minus,
          size: 20,
          color: canDecrement ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildIncrementButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: widget.isEnabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.isEnabled
              ? _getExerciseColor().withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isEnabled
                ? _getExerciseColor().withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          LucideIcons.plus,
          size: 20,
          color: widget.isEnabled ? _getExerciseColor() : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildValidationError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.validationError!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
