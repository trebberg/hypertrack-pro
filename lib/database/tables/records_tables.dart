import 'package:drift/drift.dart';
import 'user_tables.dart';
import 'exercise_tables.dart';
import 'workout_tables.dart';

// Define what constitutes a "record" for each exercise type
@DataClassName('ExerciseRecordFormula')
class ExerciseRecordFormulas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get formulaType => text().withLength(min: 1, max: 50)();

  @ReferenceName('primaryValueType')
  IntColumn get primaryValueTypeId => integer().references(ValueTypes, #id)();

  @ReferenceName('secondaryValueType')
  IntColumn get secondaryValueTypeId =>
      integer().nullable().references(ValueTypes, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Store personal records for each user per exercise
@DataClassName('PersonalRecord')
class PersonalRecords extends Table {
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  RealColumn get recordValue => real()();
  TextColumn get displayText => text()();
  DateTimeColumn get achievedAt => dateTime()();
  IntColumn get setId => integer().references(Sets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId, exerciseId};
}
