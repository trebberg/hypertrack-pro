import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lucide_icons/lucide_icons.dart';
import '../database/database.dart';
import 'exercise_settings_screen.dart';

class ExerciseLoggingScreen extends StatefulWidget {
  final int userId;
  final int workoutId;
  final int exerciseId;
  final String exerciseName;

  const ExerciseLoggingScreen({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends State<ExerciseLoggingScreen> {
  final AppDatabase _database = AppDatabase();

  // Input Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  int _selectedRir = 2; // Default RIR

  // State
  bool _isLoading = true;
  String _lastPerformance = "";
  List<Map<String, dynamic>> _plannedSets = [];
  int _currentSetNumber = 1;

  // Timer State
  bool _timerRunning = false;
  int _restTimerSeconds = 0;

  // Exercise Settings (would come from database)
  double _weightIncrement = 2.5; // kg
  int _repsIncrement = 1;
  int _defaultRestTime = 180; // seconds

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    try {
      // Load last performance for smart suggestions
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      if (lastPerformance != null && lastPerformance.isNotEmpty) {
        // Extract weight and reps from SetValue objects
        double? weight;
        int? reps;

        for (final value in lastPerformance) {
          if (value.numericValue != null) {
            if (weight == null) {
              weight = value.numericValue!;
            } else {
              reps = value.numericValue!.toInt();
              break;
            }
          }
        }

        if (weight != null && reps != null) {
          setState(() {
            _lastPerformance = "Last: ${weight}kg × $reps reps";
            // Pre-fill with last performance
            _weightController.text = weight.toString();
            _repsController.text = reps.toString();
          });
        }
      } else {
        setState(() {
          _lastPerformance = "No previous data";
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastPerformance = "Error loading data";
        _isLoading = false;
      });
    }
  }

  Future<void> _showExerciseSettings() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSettingsScreen(
        exerciseId: widget.exerciseId,
        exerciseName: widget.exerciseName,
      ),
    );

    // Reload exercise data if settings were changed
    if (result == true) {
      await _loadExerciseData();

      // Show confirmation snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exercise settings updated'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _adjustWeight(double delta) {
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    final newWeight = (currentWeight + delta).clamp(0.0, 999.9);
    _weightController.text = newWeight % 1 == 0
        ? newWeight.toInt().toString()
        : newWeight.toStringAsFixed(1);
  }

  void _adjustReps(int delta) {
    final currentReps = int.tryParse(_repsController.text) ?? 0;
    final newReps = (currentReps + delta).clamp(0, 999);
    _repsController.text = newReps.toString();
  }

  void _savePlannedSet() {
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter weight and reps")),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    setState(() {
      _plannedSets.add({
        'setNumber': _plannedSets.length + 1,
        'weight': weight,
        'reps': reps,
        'rir': _selectedRir,
        'isCompleted': false,
        'isNewPR': false, // Would be calculated
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Set added to plan"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearInputs() {
    _weightController.clear();
    _repsController.clear();
    setState(() {
      _selectedRir = 2;
    });
  }

  Future<void> _completeSet(int setIndex) async {
    setState(() {
      _plannedSets[setIndex]['isCompleted'] = true;
      _timerRunning = true;
      _restTimerSeconds = _defaultRestTime;
    });

    // Start rest timer
    _startRestTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Set completed! Rest timer started"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startRestTimer() {
    if (_restTimerSeconds <= 0) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timerRunning) {
        setState(() {
          _restTimerSeconds--;
          if (_restTimerSeconds <= 0) {
            _timerRunning = false;
          }
        });
        if (_restTimerSeconds > 0) {
          _startRestTimer();
        }
      }
    });
  }

  void _emergencyMyo() {
    // Emergency myo - quick 15 second break
    setState(() {
      _timerRunning = true;
      _restTimerSeconds = 15; // Short myo break
    });
    _startRestTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Myo break! 15 seconds"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTrophyColor(bool isNewPR, bool isNearPR) {
    if (isNewPR) return Colors.green;
    if (isNearPR) return Colors.orange;
    return Colors.grey.shade400;
  }

  Color _getRirColor(int rir) {
    if (rir < 0) return Colors.red.shade600;
    if (rir == 0) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: Colors.blue.shade100,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: _showExerciseSettings,
            tooltip: 'Exercise Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // COMPACT Exercise Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.target,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exerciseName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_lastPerformance.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _lastPerformance,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PRIORITY: Active Set Input Zone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.zap,
                              color: Colors.green.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "ACTIVE SET ${_plannedSets.length + 1}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Weight and Reps Row
                        Row(
                          children: [
                            // Weight Input with +/- buttons
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weight (kg)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Minus Button
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            LucideIcons.minus,
                                            color: Colors.blue.shade600,
                                          ),
                                          onPressed: () =>
                                              _adjustWeight(-_weightIncrement),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Weight Input
                                      Expanded(
                                        child: TextField(
                                          controller: _weightController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Plus Button
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            LucideIcons.plus,
                                            color: Colors.blue.shade600,
                                          ),
                                          onPressed: () =>
                                              _adjustWeight(_weightIncrement),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Reps Input with +/- buttons
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Reps",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Minus Button
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            LucideIcons.minus,
                                            color: Colors.blue.shade600,
                                          ),
                                          onPressed: () =>
                                              _adjustReps(-_repsIncrement),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Reps Input
                                      Expanded(
                                        child: TextField(
                                          controller: _repsController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Plus Button
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            LucideIcons.plus,
                                            color: Colors.blue.shade600,
                                          ),
                                          onPressed: () =>
                                              _adjustReps(_repsIncrement),
                                          padding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // RIR Selector Row
                        Row(
                          children: [
                            Text(
                              "RIR:",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(8, (index) {
                                  final rir = index - 2; // -2 to +5
                                  final isSelected = _selectedRir == rir;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedRir = rir),
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _getRirColor(rir)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _getRirColor(rir),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child: Text(
                                          rir >= 0 ? '+$rir' : '$rir',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : _getRirColor(rir),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons Row
                        Row(
                          children: [
                            // Save Planned Set
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: const Icon(LucideIcons.save),
                                label: const Text("SAVE SET"),
                                onPressed: _savePlannedSet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Clear Inputs
                            Expanded(
                              flex: 1,
                              child: ElevatedButton.icon(
                                icon: const Icon(LucideIcons.x),
                                label: const Text("CLEAR"),
                                onPressed: _clearInputs,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Emergency Myo
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.orange.shade400,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.alertCircle,
                                  color: Colors.orange.shade600,
                                ),
                                onPressed: _emergencyMyo,
                                tooltip: "Emergency Myo",
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Planned Sets List (Scrollable)
                  Expanded(
                    child: _plannedSets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.listChecks,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No planned sets yet",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Add sets above to create your workout plan",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _plannedSets.length,
                            itemBuilder: (context, index) {
                              final set = _plannedSets[index];
                              final isCompleted = set['isCompleted'] as bool;
                              final isNewPR = set['isNewPR'] as bool;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.shade50
                                      : Colors.white,
                                  border: Border.all(
                                    color: isCompleted
                                        ? Colors.green.shade200
                                        : Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade100,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Set Number Badge
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.green.shade600
                                            : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${set['setNumber']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Set Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${set['weight']}kg × ${set['reps']} reps',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCompleted
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade800,
                                                  decoration: isCompleted
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              if (isNewPR) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  LucideIcons.trophy,
                                                  color: _getTrophyColor(
                                                    true,
                                                    false,
                                                  ),
                                                  size: 16,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RIR: ${set['rir'] >= 0 ? '+${set['rir']}' : '${set['rir']}'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _getRirColor(set['rir']),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Complete Set Button
                                    if (!isCompleted)
                                      IconButton(
                                        icon: Icon(
                                          LucideIcons.checkCircle,
                                          color: Colors.grey.shade400,
                                        ),
                                        onPressed: () => _completeSet(index),
                                        tooltip: "Complete Set",
                                      )
                                    else
                                      Icon(
                                        LucideIcons.checkCircle,
                                        color: Colors.green.shade600,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Rest Timer (when active)
                  if (_timerRunning || _restTimerSeconds > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _timerRunning
                            ? Colors.orange.shade50
                            : Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.timer,
                            color: _timerRunning
                                ? Colors.orange.shade600
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timerRunning
                                ? "Rest Timer: ${_formatTimer(_restTimerSeconds)}"
                                : "Rest complete!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _timerRunning
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _database.close();
    super.dispose();
  }
}
