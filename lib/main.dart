import 'package:flutter/material.dart';
import 'database.dart';

void main() {
  runApp(const HyperTrackApp());
}

class HyperTrackApp extends StatelessWidget {
  const HyperTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WorkoutScreen(),
    );
  }
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final HyperTrackDatabase _database = HyperTrackDatabase();
  String _lastPerformance = "No previous data";
  bool _isLoading = false;

  Future<void> _testSmartHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add a test workout
      await _database.addWorkout("Bench Press", 80.0, 8, "Good form");

      // Get last performance
      final last = await _database.getLastPerformance("Bench Press");

      setState(() {
        _lastPerformance = last != null
            ? "Last time: ${last.weight}kg × ${last.reps} reps"
            : "No previous performance";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastPerformance = "Error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HyperTrack Pro - Smart History')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Smart History Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastPerformance,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _testSmartHistory,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Smart History'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}
