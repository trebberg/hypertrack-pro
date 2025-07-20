import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import only the tables we'll actually use
import 'tables/user_tables.dart';
import 'tables/workout_tables.dart';

// Generated file
part 'database.g.dart';

@DriftDatabase(
  tables: [
    // Start simple - just users and workouts
    Users,
    Workouts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Simple method - get last workout for user
  Future<Workout?> getLastWorkout(int userId) async {
    return await (select(workouts)
          ..where((w) => w.userId.equals(userId))
          ..orderBy([(w) => OrderingTerm.desc(w.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hypertrack_pro.db'));
    return NativeDatabase.createInBackground(file);
  });
}
