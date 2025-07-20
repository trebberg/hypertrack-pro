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
import 'tables/timer_tables.dart';

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
  int get schemaVersion => 1;

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
          leftOuterJoin(
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

  // Get all value types for an exercise
  Future<List<ValueType>> getValueTypesForExercise(int exerciseId) async {
    return await (select(valueTypes).join([
            leftOuterJoin(
              exerciseValueTypes,
              exerciseValueTypes.valueTypeId.equalsExp(valueTypes.id),
            ),
          ])
          ..where(exerciseValueTypes.exerciseId.equals(exerciseId))
          ..orderBy([OrderingTerm.asc(exerciseValueTypes.sortOrder)]))
        .map((row) => row.readTable(valueTypes))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hypertrack_pro.db'));
    return NativeDatabase.createInBackground(file);
  });
}
