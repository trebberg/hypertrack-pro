import 'package:drift/drift.dart';
import 'user_tables.dart';

@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get exerciseName => text()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
