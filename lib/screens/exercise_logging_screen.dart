import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';

class ExerciseLoggingScreen extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;
  final int userId;
  final int workoutId;

  const ExerciseLoggingScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.userId,
    required this.workoutId,
  });

  @override
  State<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends State<ExerciseLoggingScreen> {
  final AppDatabase _database = AppDatabase();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  List<Map<String, dynamic>> _completedSets = [];
  String _lastPerformance = "Loading...";
  bool _isLoading = false;
  int _currentSetNumber = 1;
  int _restTimerSeconds = 0;
  bool _timerRunning = false;

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

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);

    try {
      await _loadLastPerformance();
      await _loadCompletedSets();
      _prepopulateInputs();
    } catch (e) {
      _showError("Failed to load exercise data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLastPerformance() async {
    final lastPerformance = await _database.getLastPerformanceForExercise(
      widget.userId,
      widget.exerciseId,
    );

    if (lastPerformance.isNotEmpty) {
      // Find weight and reps from the flexible value system
      double? weight;
      int? reps;

      for (final value in lastPerformance) {
        // We need to get the value type name - this is a simplified approach
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
        });
      } else {
        setState(() => _lastPerformance = "No previous data");
      }
    } else {
      setState(() => _lastPerformance = "No previous data");
    }
  }

  Future<void> _loadCompletedSets() async {
    final sets = await _database.getAllSetsForExerciseRaw(
      widget.userId,
      widget.exerciseId,
      widget.workoutId,
    );

    setState(() {
      _completedSets = sets;
      _currentSetNumber = _getCurrentSessionSets().length + 1;
    });
  }

  List<Map<String, dynamic>> _getCurrentSessionSets() {
    return _completedSets
        .where((set) => set['isCurrentSession'] == true)
        .toList();
  }

  void _prepopulateInputs() {
    if (_completedSets.isNotEmpty) {
      final lastSet = _completedSets.first;
      _weightController.text = lastSet['weight'].toString();
      _repsController.text = lastSet['reps'].toString();
    } else if (_lastPerformance.contains("kg")) {
      final regex = RegExp(r'(\d+\.?\d*)kg × (\d+) reps');
      final match = regex.firstMatch(_lastPerformance);
      if (match != null) {
        _weightController.text = match.group(1)!;
        _repsController.text = match.group(2)!;
      }
    }
  }

  Future<void> _completeSet() async {
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) {
      _showError("Please enter weight and reps");
      return;
    }

    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || reps == null) {
      _showError("Invalid weight or reps values");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _database.logNewSet(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setNumber: _currentSetNumber,
        weight: weight,
        reps: reps,
        repsInReserve: 2,
      );

      // Check for personal record (simple calculation)
      final currentValue = weight * reps;
      final isNewRecord = await _database.isNewRecord(
        widget.userId,
        widget.exerciseId,
        currentValue,
      );

      if (isNewRecord) {
        _showSuccess("🏆 New Personal Record!");
      }

      _startRestTimer();
      await _loadCompletedSets();
      _currentSetNumber++;
    } catch (e) {
      _showError("Failed to log set: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startRestTimer() {
    setState(() {
      _restTimerSeconds = 180; // 3 minutes
      _timerRunning = true;
    });
    _runTimer();
  }

  void _runTimer() {
    if (_timerRunning && _restTimerSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _timerRunning) {
          setState(() => _restTimerSeconds--);
          _runTimer();
        }
      });
    } else if (_restTimerSeconds <= 0) {
      setState(() => _timerRunning = false);
      _showSuccess("Rest time complete!");
    }
  }

  void _adjustTimer(int seconds) {
    setState(() {
      _restTimerSeconds += seconds;
      if (_restTimerSeconds < 0) _restTimerSeconds = 0;
    });
  }

  void _stopTimer() {
    setState(() => _timerRunning = false);
  }

  Future<void> _editSet(Map<String, dynamic> set) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SetEditDialog(set: set),
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        await _deleteSet(set);
      } else if (result['action'] == 'save') {
        await _updateSet(set, result);
      }
      await _loadExerciseData();
    }
  }

  Future<void> _updateSet(
    Map<String, dynamic> set,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _database.updateExistingSet(
        setId: set['setId'],
        weight: updates['weight'],
        reps: updates['reps'],
        repsInReserve: updates['rir'],
      );
      _showSuccess("Set updated successfully");
    } catch (e) {
      _showError("Failed to update set: $e");
    }
  }

  Future<void> _deleteSet(Map<String, dynamic> set) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Set"),
        content: Text(
          "Delete Set ${set['setNumber']} (${set['weight']}kg × ${set['reps']} reps)?\n\n"
          "${set['isPersonalRecord'] ? '⚠️ This set is a personal record!\n\n' : ''}"
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _database.deleteExistingSet(set['setId']);
        _showSuccess("Set deleted successfully");
      } catch (e) {
        _showError("Failed to delete set: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    if (difference < 7) return "$difference days ago";
    return "${date.day}/${date.month}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 16),
                          Expanded(
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
                            color: _timerRunning ? Colors.orange : Colors.grey,
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
  final String Function(DateTime) formatDate;

  const _CompletedSetTile({
    required this.set,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentSession = set['isCurrentSession'] as bool;
    final displayText =
        "Set ${set['setNumber']}: ${set['weight']}kg × ${set['reps']} ✅ ${set['isPersonalRecord'] ? '🏆' : '⏱️'}";
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
