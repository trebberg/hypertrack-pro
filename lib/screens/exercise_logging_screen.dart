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
  var _isLoading = true;
  String _lastPerformance = "";
  List<Map<String, dynamic>> _plannedSets = [];
  int _currentSetNumber = 1;

  // Timer State
  var _timerRunning = false;
  int _restTimerSeconds = 0;

  // Exercise Settings (would come from database)
  double _weightIncrement = 2.5; // kg
  int _repsIncrement = 1;
  int _defaultRestTime = 180; // seconds

  // Myo-Reps Settings
  var _myoRepsEnabled = true;
  int _myoRestSeconds = 15;
  int _maxMyoSets = 3;
  int _myoTargetReps = 3;
  int _myoRirThreshold = 1;

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
    } catch (e) {
      print('Error loading exercise data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showExerciseSettings(BuildContext context) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) =>
          ExerciseSettingsScreen(exerciseId: widget.exerciseId),
    );

    if (result == true) {
      await _loadExerciseData();
    }
  }

  void _adjustWeight(double delta) {
    final currentWeight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final newWeight = (currentWeight + delta).clamp(0.0, 99999.0);
    _weightController.text = newWeight.toStringAsFixed(
      newWeight == newWeight.roundToDouble() ? 0 : 1,
    );
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
        'isNewPR': false,
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
    // Step 1: Mark set as completed
    final completedSet = _plannedSets[setIndex];
    setState(() {
      _plannedSets[setIndex]['isCompleted'] = true;
    });

    // Step 2: Show RIR assessment dialog
    final assessedRir = await _showSimpleRirDialog();

    if (assessedRir == null) {
      // User cancelled - revert completion
      setState(() {
        _plannedSets[setIndex]['isCompleted'] = false;
      });
      return;
    }

    // Update set with assessed RIR
    setState(() {
      _plannedSets[setIndex]['rir'] = assessedRir;
    });

    // Step 3: Check if myo-reps should be offered
    var shouldOfferMyo = _myoRepsEnabled && assessedRir <= _myoRirThreshold;

    if (shouldOfferMyo && mounted) {
      // Show myo-reps decision dialog
      final acceptedMyo = await _showSimpleMyoDialog(assessedRir);

      if (acceptedMyo == true && mounted) {
        // Start simplified myo-reps session
        _startSimpleMyoSession();
        return; // Don't start regular rest timer
      }
    }

    // Step 4: Start regular rest timer
    setState(() {
      _timerRunning = true;
      _restTimerSeconds = _defaultRestTime;
    });
    _startRestTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Set completed! RIR: $assessedRir"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<int?> _showSimpleRirDialog() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("How was that set?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Rate your effort (RIR - Reps in Reserve)"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(8, (index) {
                final rir = index - 2; // -2 to +5
                return ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(rir),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRirColor(rir),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('$rir'),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<dynamic> _showSimpleMyoDialog(int rir) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.flame, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text("Myo-Reps?"),
          ],
        ),
        content: Text(
          "RIR was $rir - perfect for myo-reps!\n\nDo ${_myoRestSeconds}s mini-sets until failure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Just Rest"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("LET'S MYO!"),
          ),
        ],
      ),
    );
  }

  void _startSimpleMyoSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.flame, color: Colors.orange),
            const SizedBox(width: 8),
            Text("Myo-reps session! ${_myoRestSeconds}s between mini-sets"),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() {
      _timerRunning = true;
      _restTimerSeconds = _myoRestSeconds;
    });
    _startRestTimer();
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
    setState(() {
      _timerRunning = true;
      _restTimerSeconds = 15;
    });
    _startRestTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Myo break! 15s timer started"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showExerciseSettings(context),
            tooltip: "Exercise Settings",
          ),
        ],
      ),
      body: _isLoading
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

                // PRIORITY: Active Set Input Zone - AGRESSIEF COMPACTE VERSIE
                // PRIORITY: Active Set Input Zone - EXTRA COMPACTE VERSIE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12), // VERKLEIND: was 16, nu 12
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GECORRIGEERDE SET COUNTER - Icon en text samen naar rechts
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // ALLES naar rechts
                        children: [
                          Icon(
                            LucideIcons.plus,
                            color: Colors.green.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Set ${_plannedSets.length + 1}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // NOG KLEINER: was 6, nu 4
                      // Weight Input - VEEL LAGERE INPUT FIELDS
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Weight (kg)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6), // KLEINER: was 8, nu 6
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.minus,
                                    color: Colors.red.shade600,
                                  ),
                                  onPressed: () =>
                                      _adjustWeight(-_weightIncrement),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: TextField(
                                    controller: _weightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical:
                                            2, // ZEER LAAG: was 8, nu 2 (bijna gelijk aan buttons)
                                        horizontal: 12,
                                      ),
                                      hintText: "100.50",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.plus,
                                    color: Colors.green.shade600,
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

                      const SizedBox(height: 8), // KLEINER: was 16→12, nu 8
                      // Reps Input - VEEL LAGERE INPUT FIELDS
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reps",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6), // KLEINER: was 8, nu 6
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.minus,
                                    color: Colors.red.shade600,
                                  ),
                                  onPressed: () => _adjustReps(-_repsIncrement),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: TextField(
                                    controller: _repsController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical:
                                            2, // ZEER LAAG: was 8, nu 2 (bijna gelijk aan buttons)
                                        horizontal: 12,
                                      ),
                                      hintText: "12",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.plus,
                                    color: Colors.blue.shade600,
                                  ),
                                  onPressed: () => _adjustReps(_repsIncrement),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8), // KLEINER: was 16→12, nu 8
                      // RIR Selector - ONGEWIJZIGD
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "RIR:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: List.generate(8, (index) {
                              final rir = index - 2; // -2 to +5
                              final isSelected = rir == _selectedRir;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedRir = rir),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getRirColor(rir)
                                        : Colors.white,
                                    border: Border.all(
                                      color: _getRirColor(rir),
                                      width: isSelected ? 3 : 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      rir >= 0 ? '$rir' : '$rir',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : _getRirColor(rir),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16), // IETS KLEINER: was 20, nu 16
                      // Action Buttons - ONGEWIJZIGD
                      Row(
                        children: [
                          // Add Set (Primary Action)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(LucideIcons.plus),
                              label: const Text("ADD SET"),
                              onPressed: _savePlannedSet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
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
                              icon: const Icon(LucideIcons.refreshCcw),
                              label: const Text("CLEAR"),
                              onPressed: _clearInputs,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade100,
                                foregroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.blue.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Emergency Myo
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                LucideIcons.flame,
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
                ), // Planned Sets List (Scrollable)
                Expanded(
                  child: _plannedSets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.listChecks,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No sets planned yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add your first set above",
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
                            final isCompleted = set['isCompleted'];
                            final isNewPR = set['isNewPR'];

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
                                  width: isCompleted ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Set Number Badge
                                  Container(
                                    width: 40,
                                    height: 40,
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
                                                    ? TextDecoration.lineThrough
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
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Color _getRirColor(int rir) {
    if (rir <= -1) return Colors.red.shade600;
    if (rir == 0) return Colors.orange.shade600;
    if (rir == 1) return Colors.yellow.shade700;
    if (rir <= 3) return Colors.blue.shade600;
    return Colors.green.shade600;
  }

  Color _getTrophyColor(var isNewPR, var isNearPR) {
    if (isNewPR) return Colors.amber.shade600;
    if (isNearPR) return Colors.orange.shade600;
    return Colors.grey.shade400;
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
