import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift; // Alias to avoid Column conflict
import 'database/database.dart'; // Correct path to database folder

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
  final AppDatabase _database =
      AppDatabase(); // Correct class name from database.dart
  String _lastPerformance = "No previous data";
  bool _isLoading = false;

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a test user first
      final userId = await _database
          .into(_database.users)
          .insert(UsersCompanion.insert(name: "Test User"));

      // Add a test workout
      final workoutId = await _database
          .into(_database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              userId: userId,
              exerciseName: "Bench Press",
              weight: const drift.Value(80.0),
              reps: const drift.Value(8),
              notes: const drift.Value("Good form"),
            ),
          );

      // Get last workout using the method from database.dart
      final lastWorkout = await _database.getLastWorkout(userId);

      setState(() {
        _lastPerformance = lastWorkout != null
            ? "Last time: ${lastWorkout.weight}kg × ${lastWorkout.reps} reps"
            : "No previous performance";
        _isLoading = false;
      });

      print(
        "✅ Database test successful! User ID: $userId, Workout ID: $workoutId",
      );
    } catch (e) {
      setState(() {
        _lastPerformance = "Error: $e";
        _isLoading = false;
      });
      print("❌ Database test failed: $e");
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
              'Phase 1: Smart History Demo',
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
                    onPressed: _testDatabase,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Database'),
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
