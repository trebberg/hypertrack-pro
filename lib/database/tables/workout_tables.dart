import 'package:drift/drift.dart';
import 'user_tables.dart';
import 'gym_tables.dart';
import 'exercise_tables.dart';

// Main workout sessions
@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get gymId => integer().nullable().references(Gyms, #id)();
  TextColumn get name => text().nullable()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get totalDurationSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Exercises within a workout
@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

// Individual sets within workout exercises
@DataClassName('Set')
class Sets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId =>
      integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn get restTimeSeconds => integer().nullable()();
  IntColumn get repsInReserve =>
      integer().nullable()(); // RIR for scientific analysis
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// Flexible measurement storage (CORE of smart history)
@DataClassName('SetValue')
class SetValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get setId => integer().references(Sets, #id)();
  IntColumn get valueTypeId => integer().references(ValueTypes, #id)();
  RealColumn get numericValue => real().nullable()(); // For weight, reps, time
  IntColumn get categoricalValueId => integer().nullable().references(
    CategoricalValues,
    #id,
  )(); // For resistance bands
  TextColumn get textValue => text().nullable()(); // For notes, custom values
}
