import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Workout table definition
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseName => text()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().withDefault(currentDateAndTime)();
}

// Database definition
@DriftDatabase(tables: [Workouts])
class HyperTrackDatabase extends _$HyperTrackDatabase {
  HyperTrackDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Smart history - get last performance for exercise
  Future<Workout?> getLastPerformance(String exercise) async {
    return await (select(workouts)
      ..where((w) => w.exerciseName.equals(exercise))
      ..orderBy([(w) => OrderingTerm.desc(w.completedAt)])
      ..limit(1)
    ).getSingleOrNull();
  }

  // Add workout
  Future<int> addWorkout(String exercise, double? weight, int? reps, String? notes) async {
    return await into(workouts).insert(
      WorkoutsCompanion.insert(
        exerciseName: exercise,
        weight: Value(weight),
        reps: Value(reps),
        notes: Value(notes),
      ),
    );
  }
}

// Database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hypertrack.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// Generated file will be created
part 'database.g.dart';