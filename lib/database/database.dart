import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import all table definitions
import 'tables/user_tables.dart';
import 'tables/gym_tables.dart';
import 'tables/exercise_tables.dart';
import 'tables/workout_tables.dart';
import 'tables/timers_tables.dart';
import 'tables/records_tables.dart';

// Generated file
part 'database.g.dart';

@DriftDatabase(
  tables: [
    // User management
    Users,

    // Gym system
    Gyms,

    // Exercise system
    Categories,
    ExerciseTypes,
    Exercises,
    ValueTypes,
    CategoricalValues,
    ExerciseValueTypes,
    ExerciseGyms,
    ExerciseCategories,
    ExerciseTypeLinks,

    // Workout system (flexible measurement)
    Workouts,
    WorkoutExercises,
    Sets,
    SetValues,

    // Records tracking system
    ExerciseRecordFormulas,
    PersonalRecords,

    // Timers and routines
    Timers,
    Routines,
    RoutineDays,
    RoutineDayExercises,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add the records tables for schema version 2
          await m.createTable(exerciseRecordFormulas);
          await m.createTable(personalRecords);
        }
      },
    );
  }

  // Smart history query - get last performance for an exercise
  Future<List<SetValue>> getLastPerformanceForExercise(
    int userId,
    int exerciseId,
  ) async {
    return await (select(setValues).join([
            leftOuterJoin(sets, sets.id.equalsExp(setValues.setId)),
            leftOuterJoin(
              workoutExercises,
              workoutExercises.id.equalsExp(sets.workoutExerciseId),
            ),
            leftOuterJoin(
              workouts,
              workouts.id.equalsExp(workoutExercises.workoutId),
            ),
            leftOuterJoin(
              exercises,
              exercises.id.equalsExp(workoutExercises.exerciseId),
            ),
          ])
          ..where(
            workouts.userId.equals(userId) & exercises.id.equals(exerciseId),
          )
          ..orderBy([OrderingTerm.desc(workouts.createdAt)])
          ..limit(10)) // Get last set's values
        .map((row) => row.readTable(setValues))
        .get();
  }

  // Simple method for testing - get last workout (backwards compatibility)
  Future<Workout?> getLastWorkout(int userId) async {
    return await (select(workouts)
          ..where((w) => w.userId.equals(userId))
          ..orderBy([(w) => OrderingTerm.desc(w.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Get all exercises available at a specific gym
  Future<List<Exercise>> getExercisesForGym(int gymId) async {
    return await (select(exercises).join([
          innerJoin(
            exerciseGyms,
            exerciseGyms.exerciseId.equalsExp(exercises.id),
          ),
        ])..where(
          exerciseGyms.gymId.equals(gymId) &
              exerciseGyms.isAvailable.equals(true),
        ))
        .map((row) => row.readTable(exercises))
        .get();
  }

  // Get current personal record for an exercise
  Future<PersonalRecord?> getCurrentRecord(int userId, int exerciseId) async {
    return await (select(personalRecords)..where(
          (pr) => pr.userId.equals(userId) & pr.exerciseId.equals(exerciseId),
        ))
        .getSingleOrNull();
  }

  // Check if a new value would be a record
  Future<bool> isNewRecord(int userId, int exerciseId, double newValue) async {
    final currentRecord = await getCurrentRecord(userId, exerciseId);
    return currentRecord == null || newValue > currentRecord.recordValue;
  }

  // Calculate percentage compared to personal record
  Future<double?> getRecordPercentage(
    int userId,
    int exerciseId,
    double newValue,
  ) async {
    final currentRecord = await getCurrentRecord(userId, exerciseId);
    if (currentRecord == null || currentRecord.recordValue == 0) return null;

    return ((newValue - currentRecord.recordValue) /
            currentRecord.recordValue) *
        100;
  }

  // Get record formula for an exercise
  Future<ExerciseRecordFormula?> getRecordFormula(int exerciseId) async {
    return await (select(
      exerciseRecordFormulas,
    )..where((erf) => erf.exerciseId.equals(exerciseId))).getSingleOrNull();
  }
}

// Database connection setup
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hypertrack_pro.db'));
    return NativeDatabase.createInBackground(file);
  });
}
