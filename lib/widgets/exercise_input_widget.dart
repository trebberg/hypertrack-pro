// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget
// PURPOSE: HyperTrack gym interface - outline aesthetic + dynamic icons + RIR rondjes
// DEPENDENCIES: Material, HyperTrackTheme, AppDatabase, ExerciseSet model
// RELATIONSHIPS: Child of ContainerScreen, gym-optimized UX
// THEMING: Purple exercise icons, status-based color changes, fluid outlines
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../database/database.dart';
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
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();

  late AppDatabase _database;
  int _selectedRIR = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _lastPerformance;
  int _currentSetNumber = 1;

  // Form validation states
  bool _weightValid = false;
  bool _repsValid = false;
  bool _weightError = false;
  bool _repsError = false;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _setupFocusListeners();
    _loadSmartHistory();
    _getCurrentSetNumber();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    _database.close();
    super.dispose();
  }

  void _setupFocusListeners() {
    _weightFocus.addListener(() => setState(() {}));
    _repsFocus.addListener(() => setState(() {}));

    _weightController.addListener(() {
      final isValid = _validateWeight(_weightController.text) == null;
      setState(() {
        _weightValid = isValid && _weightController.text.isNotEmpty;
        _weightError = !isValid && _weightController.text.isNotEmpty;
      });
    });

    _repsController.addListener(() {
      final isValid = _validateReps(_repsController.text) == null;
      setState(() {
        _repsValid = isValid && _repsController.text.isNotEmpty;
        _repsError = !isValid && _repsController.text.isNotEmpty;
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadSmartHistory() async {
    try {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _lastPerformance = "Last time: 80kg × 8 reps (RIR 2)";
      });
      widget.onStatusUpdate("Smart history loaded");
    } catch (e) {
      widget.onError("Failed to load exercise history: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentSetNumber() async {
    try {
      setState(() => _currentSetNumber = 1);
    } catch (e) {
      widget.onError("Failed to get current set number: $e");
    }
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final exerciseSet = ExerciseSet.completed(
        exerciseId: widget.exerciseId.toString(),
        weight: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        rir: _selectedRIR,
        setNumber: _currentSetNumber,
      );

      await Future.delayed(const Duration(milliseconds: 800));

      widget.onSetCompleted(exerciseSet);
      widget.onStatusUpdate(
        "Set $_currentSetNumber completed: ${exerciseSet.weight}kg × ${exerciseSet.reps} reps",
      );

      _prepareNextSet();
    } catch (e) {
      widget.onError("Failed to save set: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _prepareNextSet() {
    setState(() {
      _currentSetNumber++;
      _repsController.clear();
      _selectedRIR = 0;
      _repsValid = false;
      _repsError = false;
    });
    widget.onStatusUpdate("Ready for set $_currentSetNumber");
  }

  void _clearInputs() {
    setState(() {
      _weightController.clear();
      _repsController.clear();
      _selectedRIR = 0;
      _weightValid = false;
      _repsValid = false;
      _weightError = false;
      _repsError = false;
    });
    widget.onStatusUpdate("Inputs cleared");
  }

  void _adjustWeight(double increment) {
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    final newWeight = (currentWeight + increment).clamp(0.0, 1000.0);
    _weightController.text = newWeight % 1 == 0
        ? newWeight.toInt().toString()
        : newWeight.toStringAsFixed(1);
    widget.onStatusUpdate("Weight adjusted: ${_weightController.text}kg");
  }

  void _adjustReps(int increment) {
    final currentReps = int.tryParse(_repsController.text) ?? 0;
    final newReps = (currentReps + increment).clamp(0, 100);
    _repsController.text = newReps.toString();
    widget.onStatusUpdate("Reps adjusted: ${_repsController.text}");
  }

  // ─────────────────────────────────────────────────────────────
  // THEME & UI HELPERS
  // ─────────────────────────────────────────────────────────────

  String _getWeightIconStatus() {
    if (_weightError) return 'delete';
    if (_weightValid) return 'add';
    if (_weightFocus.hasFocus) return 'exercises';
    return 'settings';
  }

  String _getRepsIconStatus() {
    if (_repsError) return 'delete';
    if (_repsValid) return 'add';
    if (_repsFocus.hasFocus) return 'exercises';
    return 'settings';
  }

  String _getHistoryIconStatus() {
    if (_isLoading) return 'settings';
    if (_lastPerformance != null) return 'exercises';
    return 'delete';
  }

  String _getCompleteButtonStatus() {
    if (_isSaving) return 'exercises';
    if (_weightValid && _repsValid) return 'add';
    return 'exercises';
  }

  Color _getRirColor(int rir) {
    // RIR Color mapping: 4 RIR (links) naar -3 RIR (rechts)
    if (rir >= 3) return Colors.blue.shade500; // 3+ reps left (easy)
    if (rir == 2) return Colors.green.shade500; // 2 reps left (good)
    if (rir == 1) return Colors.yellow.shade600; // 1 rep left (moderate)
    if (rir == 0) return Colors.orange.shade500; // To failure (hard)
    if (rir == -1) return Colors.red.shade400; // Past failure
    if (rir <= -2) return Colors.red.shade600; // Failure zone
    return Colors.grey.shade500;
  }

  // ─────────────────────────────────────────────────────────────
  // VALIDATION METHODS
  // ─────────────────────────────────────────────────────────────

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Weight required';
    final weight = double.tryParse(value);
    if (weight == null) return 'Enter valid weight';
    if (weight <= 0) return 'Weight must be positive';
    if (weight > 1000) return 'Weight too high';
    return null;
  }

  String? _validateReps(String? value) {
    if (value == null || value.isEmpty) return 'Reps required';
    final reps = int.tryParse(value);
    if (reps == null) return 'Enter valid reps';
    if (reps <= 0) return 'Reps must be positive';
    if (reps > 100) return 'Reps too high';
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
            if (_lastPerformance != null) ...[
              _buildSmartHistory(),
              const SizedBox(height: 16),
            ],
            _buildWeightInput(),
            const SizedBox(height: 12),
            _buildRepsInput(),
            const SizedBox(height: 16),
            _buildRIRSelector(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        HyperTrackTheme.coloredIcon(
          LucideIcons.dumbbell,
          'exercises',
          size: 24,
        ),
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
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HyperTrackTheme.getIconColor('exercises'),
            ),
          ),
      ],
    );
  }

  Widget _buildSmartHistory() {
    return HyperTrackTheme.outlinedCard(
      child: Row(
        children: [
          HyperTrackTheme.coloredIcon(
            LucideIcons.history,
            _getHistoryIconStatus(),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_lastPerformance!, style: HyperTrackTheme.captionText),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput() {
    return Row(
      children: [
        // Minus button (links) - EXPLICIT dimensions
        Container(
          width: 56, // ⭐ EXPLICIT width
          height: 56, // ⭐ EXPLICIT height
          decoration: BoxDecoration(
            border: Border.all(color: HyperTrackTheme.lightGrey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: HyperTrackTheme.coloredIcon(
              LucideIcons.minus,
              'delete',
              size: 18,
            ),
            onPressed: () => _adjustWeight(-2.5),
            padding: const EdgeInsets.all(8),
            constraints:
                const BoxConstraints.expand(), // Fill container exactly
          ),
        ),
        const SizedBox(width: 8),
        // Weight input field (middle)
        Expanded(
          child: SizedBox(
            height: 56, // ⭐ EXPLICIT height wrapper
            child: TextFormField(
              controller: _weightController,
              focusNode: _weightFocus,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HyperTrackTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HyperTrackTheme.getIconColor(_getWeightIconStatus()),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HyperTrackTheme.warningOrange,
                    width: 2,
                  ),
                ),
                filled: false,
                prefixIcon: HyperTrackTheme.coloredIcon(
                  LucideIcons.dumbbell,
                  _getWeightIconStatus(),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: _validateWeight,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _repsFocus.requestFocus(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Plus button (rechts) - EXPLICIT dimensions
        Container(
          width: 56, // ⭐ EXPLICIT width
          height: 56, // ⭐ EXPLICIT height
          decoration: BoxDecoration(
            border: Border.all(color: HyperTrackTheme.lightGrey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: HyperTrackTheme.coloredIcon(
              LucideIcons.plus,
              'add',
              size: 18,
            ),
            onPressed: () => _adjustWeight(2.5),
            padding: const EdgeInsets.all(8),
            constraints:
                const BoxConstraints.expand(), // Fill container exactly
          ),
        ),
      ],
    );
  }

  Widget _buildRepsInput() {
    return Row(
      children: [
        // Minus button (links) - IDENTIEK AAN WEIGHT
        Container(
          width: 56, // ⭐ EXPLICIT width
          height: 56, // ⭐ EXPLICIT height
          decoration: BoxDecoration(
            border: Border.all(color: HyperTrackTheme.lightGrey),
            borderRadius: BorderRadius.circular(8), // ⭐ 8 zoals weight
          ),
          child: IconButton(
            icon: HyperTrackTheme.coloredIcon(
              LucideIcons.minus,
              'delete',
              size: 18,
            ),
            onPressed: () => _adjustReps(-1),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints.expand(), // ⭐ expand zoals weight
          ),
        ),
        const SizedBox(width: 8),
        // Reps input field (middle) - IDENTIEK AAN WEIGHT
        Expanded(
          child: SizedBox(
            height: 56, // ⭐ EXPLICIT height wrapper zoals weight
            child: TextFormField(
              controller: _repsController,
              focusNode: _repsFocus,
              decoration: InputDecoration(
                labelText: 'Reps',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HyperTrackTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HyperTrackTheme.getIconColor(_getRepsIconStatus()),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HyperTrackTheme.warningOrange,
                    width: 2,
                  ),
                ),
                filled: false,
                prefixIcon: HyperTrackTheme.coloredIcon(
                  LucideIcons.repeat,
                  _getRepsIconStatus(),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ), // ⭐ zoals weight
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateReps,
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Plus button (rechts) - IDENTIEK AAN WEIGHT
        Container(
          width: 56, // ⭐ EXPLICIT width
          height: 56, // ⭐ EXPLICIT height
          decoration: BoxDecoration(
            border: Border.all(color: HyperTrackTheme.lightGrey),
            borderRadius: BorderRadius.circular(8), // ⭐ 8 zoals weight
          ),
          child: IconButton(
            icon: HyperTrackTheme.coloredIcon(
              LucideIcons.plus,
              'add',
              size: 18,
            ),
            onPressed: () => _adjustReps(1),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints.expand(), // ⭐ expand zoals weight
          ),
        ),
      ],
    );
  }

  Widget _buildRIRSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RIR (Reps In Reserve):",
          style: HyperTrackTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // RIR rondjes: 4 RIR links naar -3 RIR rechts, responsive fit (geen scroll)
        Row(
          children: [4, 3, 2, 1, 0, -1, -2, -3].map((rir) {
            final isSelected = rir == _selectedRIR;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                ), // Minimal spacing to fit
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRIR = rir),
                  child: Container(
                    height: 36, // Fixed height
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getRirColor(rir)
                          : Colors.transparent,
                      border: Border.all(
                        color: _getRirColor(rir),
                        width: isSelected ? 3 : 2,
                      ),
                      borderRadius: BorderRadius.circular(18), // Perfect circle
                    ),
                    child: Center(
                      child: Text(
                        rir >= 0 ? '$rir' : '$rir',
                        style: TextStyle(
                          color: isSelected ? Colors.white : _getRirColor(rir),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Complete Set (Primary Action)
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: (_weightValid && _repsValid && !_isSaving)
                ? _saveSet
                : null,
            icon: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : HyperTrackTheme.coloredIcon(
                    LucideIcons.checkCircle2,
                    _getCompleteButtonStatus(),
                    size: 18,
                  ),
            label: Text(
              _isSaving ? "SAVING..." : "COMPLETE SET $_currentSetNumber",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: HyperTrackTheme.getIconColor('exercises'),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Clear Button
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _clearInputs,
            icon: HyperTrackTheme.coloredIcon(
              LucideIcons.refreshCcw,
              'settings',
            ),
            label: const Text("CLEAR"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: HyperTrackTheme.mediumGrey,
              side: BorderSide(color: HyperTrackTheme.lightGrey, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
