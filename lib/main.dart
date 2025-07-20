import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'database/database.dart';
import 'screens/exercise_logging_screen.dart';

void main() {
  runApp(const HyperTrackApp());
}

class HyperTrackApp extends StatelessWidget {
  const HyperTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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

  int? _userId;
  int? _workoutId;
  int? _benchPressId;

  @override
  void initState() {
    super.initState();
    _setupTestData();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _setupTestData() async {
    setState(() => _isLoading = true);

    try {
      // Create test user
      _userId = await _database
          .into(_database.users)
          .insert(UsersCompanion.insert(name: "Test User"));

      // Create test gym
      final gymId = await _database
          .into(_database.gyms)
          .insert(
            GymsCompanion.insert(
              userId: _userId!,
              name: "Test Gym",
              isFavorite: const drift.Value(true),
            ),
          );

      // Create test exercise
      _benchPressId = await _database
          .into(_database.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: "Bench Press",
              instructions: const drift.Value("Keep back flat"),
              defaultRestSeconds: const drift.Value(180),
            ),
          );

      // Create value types
      await _createValueTypesIfNeeded();

      // Create test workout
      _workoutId = await _database
          .into(_database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              userId: _userId!,
              gymId: drift.Value(gymId),
              name: const drift.Value("Push Day Test"),
            ),
          );

      // Create historical data
      await _createHistoricalData();

      // Load last performance
      await _testDatabase();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _lastPerformance = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _createValueTypesIfNeeded() async {
    try {
      // Debug: check how many weight types exist
      final allWeightTypes = await (_database.select(
        _database.valueTypes,
      )..where((vt) => vt.name.equals('weight'))).get();
      print("DEBUG: Found ${allWeightTypes.length} weight types");

      if (allWeightTypes.isEmpty) {
        await _database
            .into(_database.valueTypes)
            .insert(
              ValueTypesCompanion.insert(
                name: "weight",
                dataType: "numeric",
                unit: const drift.Value("kg"),
              ),
            );
        print("DEBUG: Created weight type");
      }

      // Same for reps
      final allRepsTypes = await (_database.select(
        _database.valueTypes,
      )..where((vt) => vt.name.equals('reps'))).get();
      print("DEBUG: Found ${allRepsTypes.length} reps types");

      if (allRepsTypes.isEmpty) {
        await _database
            .into(_database.valueTypes)
            .insert(
              ValueTypesCompanion.insert(
                name: "reps",
                dataType: "numeric",
                unit: const drift.Value("count"),
              ),
            );
        print("DEBUG: Created reps type");
      }
    } catch (e) {
      print("ERROR in _createValueTypesIfNeeded: $e");
    }
  }

  Future<void> _createHistoricalData() async {
    if (_userId == null || _benchPressId == null) return;

    // Create yesterday's workout
    final yesterdayWorkout = await _database
        .into(_database.workouts)
        .insert(
          WorkoutsCompanion.insert(
            userId: _userId!,
            name: const drift.Value("Push Day - Yesterday"),
            createdAt: drift.Value(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        );

    // Create workout exercise
    final workoutExerciseId = await _database
        .into(_database.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            workoutId: yesterdayWorkout,
            exerciseId: _benchPressId!,
          ),
        );

    // Get value types
    final weightType = await (_database.select(
      _database.valueTypes,
    )..where((vt) => vt.name.equals('weight'))).getSingle();
    final repsType = await (_database.select(
      _database.valueTypes,
    )..where((vt) => vt.name.equals('reps'))).getSingle();

    // Create 3 historical sets
    for (int i = 1; i <= 3; i++) {
      final setId = await _database
          .into(_database.sets)
          .insert(
            SetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: i,
              repsInReserve: drift.Value(i == 3 ? 1 : 2),
            ),
          );

      // Add weight values
      await _database
          .into(_database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: weightType.id,
              numericValue: const drift.Value(80.0),
            ),
          );

      // Add reps values (8, 8, 7 reps)
      await _database
          .into(_database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: repsType.id,
              numericValue: drift.Value((i == 3 ? 7 : 8).toDouble()),
            ),
          );
    }
  }

  Future<void> _testDatabase() async {
    try {
      final lastPerformance = await _database.getLastPerformanceForExercise(
        _userId!,
        _benchPressId!,
      );

      if (lastPerformance.isNotEmpty) {
        setState(() {
          _lastPerformance = "Last time: 80kg × 8 reps";
        });
      }
    } catch (e) {
      setState(() {
        _lastPerformance = "Error: $e";
      });
    }
  }

  void _openExerciseLogging() {
    if (_userId != null && _workoutId != null && _benchPressId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseLoggingScreen(
            exerciseId: _benchPressId!,
            exerciseName: "Bench Press",
            userId: _userId!,
            workoutId: _workoutId!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperTrack Pro - Exercise Logging'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Exercise Logging Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _lastPerformance,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (!_isLoading && _userId != null)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _openExerciseLogging,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Start Bench Press Logging',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Features:\n'
                '• View historical sets from yesterday\n'
                '• Click any set to edit/delete\n'
                '• Log new sets with timer\n'
                '• Personal record detection',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
