import 'package:drift/drift.dart';
import 'user_tables.dart';
import 'exercise_tables.dart';

// Timer management (rest timers, workout timers)
@DataClassName('Timer')
class Timers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get timerType =>
      text().withLength(min: 1, max: 20)(); // rest, workout, custom
  IntColumn get durationSeconds => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get exerciseId => integer().nullable().references(
    Exercises,
    #id,
  )(); // null for general timers
}

// Workout routines/schedules
@DataClassName('Routine')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get cycleDays => integer().withDefault(
    const Constant(7),
  )(); // 7 for weekly, 14 for bi-weekly
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Days within a routine cycle
@DataClassName('RoutineDay')
class RoutineDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get dayNumber => integer()(); // 1-7 for weekly, 1-14 for bi-weekly
  TextColumn get workoutTemplateName => text().nullable()();
  BoolColumn get isRestDay => boolean().withDefault(const Constant(false))();
}

// Exercises planned for routine days
@DataClassName('RoutineDayExercise')
class RoutineDayExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineDayId => integer().references(RoutineDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
  RealColumn get targetWeight => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
