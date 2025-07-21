import 'package:flutter/material.dart';
import '../database/database.dart';

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
  late AppDatabase _database;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _rirController =
      TextEditingController(); // NEW: RIR controller

  List<Map<String, dynamic>> _completedSets = [];
  String _lastPerformance = "Loading...";
  int _currentSetNumber = 1;
  int? _currentWorkoutId;
  bool _isLoading = true;

  // Timer variables
  bool _timerRunning = false;
  int _restTimerSeconds = 0;
  static const int _defaultRestTimeSeconds = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _initializeData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rirController.dispose(); // NEW: Dispose RIR controller
    _database.close();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _currentWorkoutId = widget.workoutId;

      await _loadLastPerformance();
      await _loadCompletedSets();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error initializing data: $e");
      setState(() {
        _isLoading = false;
        _lastPerformance = "Error loading data";
      });
    }
  }

  Future<void> _loadLastPerformance() async {
    try {
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      if (lastPerformance != null && lastPerformance.isNotEmpty) {
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
            _lastPerformance = "Last time: ${weight}kg × $reps reps";
            _weightController.text = weight.toString();
            _repsController.text = reps.toString();
            // Don't auto-populate RIR as it's session-specific
          });
        } else {
          setState(() {
            _lastPerformance = "No previous performance data";
          });
        }
      } else {
        setState(() {
          _lastPerformance = "No previous performance";
        });
      }
    } catch (e) {
      print("Error loading last performance: $e");
      setState(() {
        _lastPerformance = "Error loading last performance";
      });
    }
  }

  Future<void> _loadCompletedSets() async {
    if (_currentWorkoutId == null) return;

    try {
      final sets = await _database.getAllSetsForExerciseRaw(
        widget.userId,
        widget.exerciseId,
        _currentWorkoutId!,
      );
      setState(() {
        _completedSets = sets;
        if (sets.isNotEmpty) {
          _currentSetNumber =
              sets.where((set) => set['isCurrentSession'] == true).length + 1;
        }
      });
    } catch (e) {
      print("Error loading completed sets: $e");
    }
  }

  Future<void> _completeSet() async {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final rir = int.tryParse(_rirController.text); // NEW: Get RIR value

    if (weight == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid weight and reps")),
      );
      return;
    }

    try {
      await _database.logNewSet(
        workoutId: _currentWorkoutId!,
        exerciseId: widget.exerciseId,
        setNumber: _currentSetNumber,
        weight: weight,
        reps: reps,
        repsInReserve: rir, // NEW: Include RIR in database call
      );

      setState(() {
        _currentSetNumber++;
        _weightController.clear();
        _repsController.clear();
        _rirController.clear(); // NEW: Clear RIR field
      });

      await _loadCompletedSets();
      _startRestTimer();

      if (mounted) {
        final rirText = rir != null ? " (RIR: $rir)" : "";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Set ${_currentSetNumber - 1} completed: ${weight}kg × $reps reps$rirText",
            ), // FIXED: String interpolation
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error logging set: $e")));
      }
    }
  }

  void _startRestTimer() {
    setState(() {
      _restTimerSeconds = _defaultRestTimeSeconds;
      _timerRunning = true;
    });

    _runTimer();
  }

  void _runTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_timerRunning && _restTimerSeconds > 0) {
        setState(() {
          _restTimerSeconds--;
        });
        _runTimer();
      } else {
        setState(() {
          _timerRunning = false;
        });
      }
    });
  }

  void _adjustTimer(int seconds) {
    setState(() {
      _restTimerSeconds = (_restTimerSeconds + seconds).clamp(0, 999);
    });
  }

  void _stopTimer() {
    setState(() {
      _timerRunning = false;
      _restTimerSeconds = 0;
    });
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return "Unknown";
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) return "Today";
      if (targetDate == yesterday) return "Yesterday";
      return "${date.day}/${date.month}";
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> _editSet(Map<String, dynamic> set) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SetEditDialog(set: set),
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        try {
          await _database.deleteExistingSet(set['setId']);
          await _loadCompletedSets();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Set deleted")));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error deleting set: $e")));
          }
        }
      } else if (result['action'] == 'save') {
        try {
          await _database.updateExistingSet(
            setId: set['setId'],
            weight: result['weight'],
            reps: result['reps'],
            repsInReserve: result['rir'],
          );
          await _loadCompletedSets();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Set updated")));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error updating set: $e")));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: Colors.blue.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Exercise Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastPerformance,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Completed Sets List
                Expanded(
                  flex: 2,
                  child: _completedSets.isEmpty
                      ? const Center(
                          child: Text(
                            "No previous sets",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _completedSets.length,
                          itemBuilder: (context, index) {
                            final set = _completedSets[index];
                            return _CompletedSetTile(
                              set: set,
                              onTap: () => _editSet(set),
                              formatDate: _formatDate,
                            );
                          },
                        ),
                ),

                // Active Set Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ACTIVE SET $_currentSetNumber:",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NEW: Updated Row with 3 fields (Weight, Reps, RIR)
                      Row(
                        children: [
                          // Weight Field
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Weight (kg)",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _weightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: const TextStyle(fontSize: 20),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Reps Field
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Reps",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _repsController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 20),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // NEW: RIR Field
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "RIR",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _rirController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    hintText: "0-10",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _completeSet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("✅ Complete Set"),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timer Section
                if (_timerRunning || _restTimerSeconds > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: _timerRunning
                        ? Colors.orange.shade50
                        : Colors.grey.shade50,
                    child: Column(
                      children: [
                        Text(
                          "Rest Timer: ${_formatTimer(_restTimerSeconds)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _timerRunning
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => _adjustTimer(30),
                              child: const Text("+30s"),
                            ),
                            ElevatedButton(
                              onPressed: () => _adjustTimer(60),
                              child: const Text("+1m"),
                            ),
                            ElevatedButton(
                              onPressed: () => _adjustTimer(120),
                              child: const Text("+2m"),
                            ),
                            ElevatedButton(
                              onPressed: _stopTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Stop"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CompletedSetTile extends StatelessWidget {
  final Map<String, dynamic> set;
  final VoidCallback onTap;
  final String Function(dynamic) formatDate;

  const _CompletedSetTile({
    required this.set,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentSession = set['isCurrentSession'] == true;
    final rirText = set['repsInReserve'] != null
        ? " (RIR: ${set['repsInReserve']})"
        : "";
    final displayText =
        "Set ${set['setNumber']}: ${set['weight']}kg × ${set['reps']} reps$rirText ${isCurrentSession ? '🏆' : '⏱️'}";
    final contextText = isCurrentSession
        ? ""
        : "📅 From: \"${set['workoutName']}\" (${formatDate(set['completedAt'])})";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          displayText,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isCurrentSession ? Colors.black : Colors.grey.shade600,
          ),
        ),
        subtitle: contextText.isNotEmpty
            ? Text(
                contextText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              )
            : null,
        trailing: Icon(Icons.edit, color: Colors.grey.shade400),
      ),
    );
  }
}

class _SetEditDialog extends StatefulWidget {
  final Map<String, dynamic> set;

  const _SetEditDialog({required this.set});

  @override
  State<_SetEditDialog> createState() => _SetEditDialogState();
}

class _SetEditDialogState extends State<_SetEditDialog> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _rirController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set['weight'].toString(),
    );
    _repsController = TextEditingController(
      text: widget.set['reps'].toString(),
    );
    _rirController = TextEditingController(
      text: widget.set['repsInReserve']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contextText = widget.set['isCurrentSession']
        ? ""
        : "📅 From: \"${widget.set['workoutName']}\"";

    return AlertDialog(
      title: Text("✏️ Edit Set ${widget.set['setNumber']}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contextText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                contextText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Weight (kg)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Reps",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rirController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "RIR (1-10, optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, {'action': 'delete'}),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("🗑️ Delete"),
        ),
        ElevatedButton(
          onPressed: () {
            final weight = double.tryParse(_weightController.text);
            final reps = int.tryParse(_repsController.text);
            final rir = int.tryParse(_rirController.text);

            if (weight != null && reps != null) {
              Navigator.pop(context, {
                'action': 'save',
                'weight': weight,
                'reps': reps,
                'rir': rir,
              });
            }
          },
          child: const Text("💾 Save"),
        ),
      ],
    );
  }
}
