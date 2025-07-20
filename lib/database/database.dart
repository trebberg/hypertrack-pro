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

  // CRUD methods for Exercise Logging Screen
  Future<List<Map<String, dynamic>>> getAllSetsForExerciseRaw(
    int userId,
    int exerciseId,
    int currentWorkoutId,
  ) async {
    final query = '''
      SELECT 
        s.id as set_id,
        s.set_number,
        s.reps_in_reserve,
        s.rest_time_seconds,
        s.completed_at,
        sv_weight.numeric_value as weight,
        sv_reps.numeric_value as reps,
        w.name as workout_name,
        false as is_personal_record,
        (w.id = ?) as is_current_session
      FROM sets s
      JOIN workout_exercises we ON s.workout_exercise_id = we.id
      JOIN workouts w ON we.workout_id = w.id
      JOIN set_values sv_weight ON s.id = sv_weight.set_id
      JOIN set_values sv_reps ON s.id = sv_reps.set_id
      JOIN value_types vt_weight ON sv_weight.value_type_id = vt_weight.id AND vt_weight.name = 'weight'
      JOIN value_types vt_reps ON sv_reps.value_type_id = vt_reps.id AND vt_reps.name = 'reps'
      WHERE we.exercise_id = ? AND w.user_id = ?
      ORDER BY s.completed_at DESC
      LIMIT 20
    ''';

    final result = await customSelect(
      query,
      variables: [
        Variable.withInt(currentWorkoutId),
        Variable.withInt(exerciseId),
        Variable.withInt(userId),
      ],
    ).get();

    return result.map((row) {
      return {
        'setId': row.read<int>('set_id'),
        'setNumber': row.read<int>('set_number'),
        'weight': row.read<double>('weight'),
        'reps': row.read<double>('reps').toInt(),
        'repsInReserve': row.readNullable<int>('reps_in_reserve'),
        'restTimeSeconds': row.readNullable<int>('rest_time_seconds') ?? 0,
        'isPersonalRecord': row.read<bool>('is_personal_record'),
        'completedAt': row.read<DateTime>('completed_at'),
        'workoutName': row.readNullable<String>('workout_name') ?? 'Unknown',
        'isCurrentSession': row.read<bool>('is_current_session'),
      };
    }).toList();
  }

  Future<int> logNewSet({
    required int workoutId,
    required int exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    int? repsInReserve,
  }) async {
    return await transaction(() async {
      // Get or create workout exercise
      final workoutExerciseQuery = select(workoutExercises)
        ..where(
          (we) =>
              we.workoutId.equals(workoutId) & we.exerciseId.equals(exerciseId),
        );

      WorkoutExercise? workoutExercise = await workoutExerciseQuery
          .getSingleOrNull();

      if (workoutExercise == null) {
        final workoutExerciseId = await into(workoutExercises).insert(
          WorkoutExercisesCompanion.insert(
            workoutId: workoutId,
            exerciseId: exerciseId,
          ),
        );
        workoutExercise = await (select(
          workoutExercises,
        )..where((we) => we.id.equals(workoutExerciseId))).getSingle();
      }

      // Create the set
      final setId = await into(sets).insert(
        SetsCompanion.insert(
          workoutExerciseId: workoutExercise.id,
          setNumber: setNumber,
          repsInReserve: Value(repsInReserve),
        ),
      );

      // Get value type IDs
      final weightType = await (select(
        valueTypes,
      )..where((vt) => vt.name.equals('weight'))).getSingle();
      final repsType = await (select(
        valueTypes,
      )..where((vt) => vt.name.equals('reps'))).getSingle();

      // Insert weight value
      await into(setValues).insert(
        SetValuesCompanion.insert(
          setId: setId,
          valueTypeId: weightType.id,
          numericValue: Value(weight),
        ),
      );

      // Insert reps value
      await into(setValues).insert(
        SetValuesCompanion.insert(
          setId: setId,
          valueTypeId: repsType.id,
          numericValue: Value(reps.toDouble()),
        ),
      );

      return setId;
    });
  }

  Future<void> updateExistingSet({
    required int setId,
    required double weight,
    required int reps,
    int? repsInReserve,
  }) async {
    await transaction(() async {
      // Update RIR in sets table
      await (update(sets)..where((s) => s.id.equals(setId))).write(
        SetsCompanion(repsInReserve: Value(repsInReserve)),
      );

      // Get value type IDs
      final weightType = await (select(
        valueTypes,
      )..where((vt) => vt.name.equals('weight'))).getSingle();
      final repsType = await (select(
        valueTypes,
      )..where((vt) => vt.name.equals('reps'))).getSingle();

      // Update weight value
      await (update(setValues)..where(
            (sv) =>
                sv.setId.equals(setId) & sv.valueTypeId.equals(weightType.id),
          ))
          .write(SetValuesCompanion(numericValue: Value(weight)));

      // Update reps value
      await (update(setValues)..where(
            (sv) => sv.setId.equals(setId) & sv.valueTypeId.equals(repsType.id),
          ))
          .write(SetValuesCompanion(numericValue: Value(reps.toDouble())));
    });
  }

  Future<void> deleteExistingSet(int setId) async {
    await transaction(() async {
      await (delete(setValues)..where((sv) => sv.setId.equals(setId))).go();
      await (delete(
        personalRecords,
      )..where((pr) => pr.setId.equals(setId))).go();
      await (delete(sets)..where((s) => s.id.equals(setId))).go();
    });
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
