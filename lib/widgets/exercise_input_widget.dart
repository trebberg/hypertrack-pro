// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseInputWidget
// PURPOSE: Weight/reps input, set completion (BACK TO ORIGINAL SIGNATURE)
// DEPENDENCIES: Material, AppDatabase, drift, HyperTrackTheme
// RELATIONSHIPS: Child of ContainerScreen, handles all input and save operations
// THEMING: HyperTrack theme applied where possible, functionality prioritized
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../theme/app_theme.dart';
import '../database/database.dart';
import '../models/exercise_set.dart';

class ExerciseInputWidget extends StatefulWidget {
  // BACK TO ORIGINAL SIGNATURE (so Container can call it)
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
  // MIGRATED STATE FROM ORIGINAL SCREEN
  // ─────────────────────────────────────────────────────────────

  final AppDatabase _database = AppDatabase();

  // Input Controllers (ORIGINAL LOGIC)
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  int _selectedRir = 2; // Default RIR

  // State (ORIGINAL LOGIC)
  var _isLoading = true;
  String _lastPerformance = "";
  List<Map<String, dynamic>> _plannedSets = [];
  int _currentSetNumber = 1;

  // Exercise Settings (ORIGINAL LOGIC - would come from database)
  double _weightIncrement = 2.5; // kg
  int _repsIncrement = 1;
  int _defaultRestTime = 180; // seconds

  // Myo-Reps Settings (ORIGINAL LOGIC)
  var _myoRepsEnabled = true;
  int _myoRestSeconds = 15;
  int _maxMyoSets = 3;
  int _myoTargetReps = 3;
  int _myoRirThreshold = 1;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _database.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS (MIGRATED FROM ORIGINAL)
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
            } else {
              reps = value.numericValue!.toInt();
            }
          }
        }

        if (weight != null && reps != null) {
          setState(() {
            _lastPerformance = "Last time: ${weight}kg × $reps reps";
            _weightController.text = weight.toString();
            _repsController.text = reps.toString();
          });
        }
      }

      setState(() {
        _isLoading = false;
      });

      widget.onStatusUpdate("Exercise data loaded successfully");
    } catch (e) {
      widget.onError('Error loading exercise data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ORIGINAL ADD SET LOGIC
  Future<void> _addPlannedSet() async {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || reps == null || weight <= 0 || reps <= 0) {
      widget.onError("Please enter valid weight and reps");
      return;
    }

    try {
      widget.onStatusUpdate("Adding planned set...");

      final setData = {
        'setNumber': _currentSetNumber,
        'weight': weight,
        'reps': reps,
        'rir': _selectedRir,
        'completed': false,
        'id': 'planned_${DateTime.now().millisecondsSinceEpoch}',
      };

      setState(() {
        _plannedSets.add(setData);
        _currentSetNumber++;
      });

      widget.onStatusUpdate("Set ${_currentSetNumber - 1} planned");
    } catch (e) {
      widget.onError('Error adding set: $e');
    }
  }

  // ORIGINAL COMPLETE SET LOGIC
  Future<void> _completeSet(Map<String, dynamic> setData) async {
    try {
      widget.onStatusUpdate("Completing set...");

      // Save to database (ORIGINAL logNewSet call)
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
  // UI BUILD METHODS (SIMPLIFIED FOR NOW - THEME LATER)
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            Icon(LucideIcons.dumbbell, size: 20, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Exercise Input',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading) ...[
          const Center(child: CircularProgressIndicator()),
        ] else ...[
          // Smart History Display (ORIGINAL LOGIC)
          if (_lastPerformance.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.shade50,
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    _lastPerformance,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Input Section (ORIGINAL LAYOUT)
          _buildInputSection(),
          const SizedBox(height: 16),

          // Add Set Button (ORIGINAL LOGIC)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addPlannedSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("ADD PLANNED SET $_currentSetNumber"),
            ),
          ),
          const SizedBox(height: 16),

          // Planned Sets List (ORIGINAL LOGIC)
          _buildPlannedSetsList(),
        ],
      ],
    );
  }

  Widget _buildInputSection() {
    return Row(
      children: [
        // Weight Input (ORIGINAL)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weight (kg)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '80.0',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Reps Input (ORIGINAL)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reps', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '8',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // RIR Selection (ORIGINAL LOGIC)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RIR', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedRir,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: List.generate(6, (index) {
                  return DropdownMenuItem(value: index, child: Text('$index'));
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedRir = value ?? 2;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlannedSetsList() {
    if (_plannedSets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No sets planned yet.\nAdd your first set above!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _plannedSets.map((setData) => _buildSetCard(setData)).toList(),
    );
  }

  Widget _buildSetCard(Map<String, dynamic> setData) {
    final isCompleted = setData['completed'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCompleted ? Colors.green.shade50 : Colors.white,
      ),
      child: Row(
        children: [
          // Set Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.shade100
                  : Colors.purple.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${setData['setNumber']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.purple.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Set Details
          Expanded(
            child: Text(
              '${setData['weight']}kg × ${setData['reps']} reps @ RIR ${setData['rir']}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCompleted ? Colors.green.shade700 : Colors.black,
              ),
            ),
          ),

          // Complete Button
          if (!isCompleted)
            IconButton(
              onPressed: () => _completeSet(setData),
              icon: const Icon(LucideIcons.check, color: Colors.green),
              tooltip: 'Complete Set',
            )
          else
            const Icon(LucideIcons.checkCircle, color: Colors.green),
        ],
      ),
    );
  }
}
