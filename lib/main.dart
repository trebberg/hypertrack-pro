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
  final AppDatabase _database = AppDatabase();
  String _lastPerformance = "No previous data";
  bool _isLoading = false;

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("🔄 Testing flexible database structure...");

      // 1. Create user
      final userId = await _database
          .into(_database.users)
          .insert(UsersCompanion.insert(name: "Test User"));

      // 2. Create gym
      final gymId = await _database
          .into(_database.gyms)
          .insert(
            GymsCompanion.insert(
              userId: userId,
              name: "Test Gym",
              isFavorite: const drift.Value(true),
            ),
          );

      // 3. Create exercise
      final exerciseId = await _database
          .into(_database.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: "Bench Press",
              instructions: const drift.Value("Keep back flat"),
              defaultRestSeconds: const drift.Value(120),
            ),
          );

      // 4. Create value types (weight, reps)
      final weightTypeId = await _database
          .into(_database.valueTypes)
          .insert(
            ValueTypesCompanion.insert(
              name: "weight",
              dataType: "numeric",
              unit: const drift.Value("kg"),
            ),
          );

      final repsTypeId = await _database
          .into(_database.valueTypes)
          .insert(
            ValueTypesCompanion.insert(
              name: "reps",
              dataType: "numeric",
              unit: const drift.Value("count"),
            ),
          );

      // 5. Create workout
      final workoutId = await _database
          .into(_database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              userId: userId,
              gymId: drift.Value(gymId),
              name: const drift.Value("Push Day"),
            ),
          );

      // 6. Add exercise to workout
      final workoutExerciseId = await _database
          .into(_database.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              workoutId: workoutId,
              exerciseId: exerciseId,
              sortOrder: const drift.Value(1),
            ),
          );

      // 7. Create set
      final setId = await _database
          .into(_database.sets)
          .insert(
            SetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: 1,
              repsInReserve: const drift.Value(2),
            ),
          );

      // 8. Add weight value
      await _database
          .into(_database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: weightTypeId,
              numericValue: const drift.Value(80.0),
            ),
          );

      // 9. Add reps value
      await _database
          .into(_database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: repsTypeId,
              numericValue: const drift.Value(8.0),
            ),
          );

      print("✅ Created complete flexible workout structure!");

      // 10. Test smart history query
      final lastPerformance = await _database.getLastPerformanceForExercise(
        userId,
        exerciseId,
      );

      String performanceText = "No previous performance";
      if (lastPerformance.isNotEmpty) {
        // Find weight and reps values
        double? weight;
        double? reps;

        for (final value in lastPerformance) {
          if (value.valueTypeId == weightTypeId) {
            weight = value.numericValue;
          } else if (value.valueTypeId == repsTypeId) {
            reps = value.numericValue;
          }
        }

        if (weight != null && reps != null) {
          performanceText =
              "Last time: ${weight.toInt()}kg × ${reps.toInt()} reps";
        }
      }

      setState(() {
        _lastPerformance = performanceText;
        _isLoading = false;
      });

      print("🎉 Smart history test successful!");
      print("📊 Database supports flexible measurements!");
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
      appBar: AppBar(
        title: const Text('HyperTrack Pro - Phase 1'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Flexible Database Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complex Workout Structure + Smart History',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  const Icon(Icons.history, color: Colors.green),
                  const SizedBox(height: 10),
                  Text(
                    _lastPerformance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _testDatabase,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              'Phase 1: Foundation Complete ✅',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
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
