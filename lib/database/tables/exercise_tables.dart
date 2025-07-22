import 'package:drift/drift.dart';
import 'user_tables.dart';
import 'gym_tables.dart';

// Muscle groups (chest, back, legs, shoulders, etc.)
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get userId => integer().nullable().references(Users, #id)();
}

// Movement types (isometric, endurance, strength, stretch)
@DataClassName('ExerciseType')
class ExerciseTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get userId => integer().nullable().references(Users, #id)();
}

// Exercise definitions - UPDATED MET MYO-REPS KOLOMMEN
@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get instructions => text().nullable()();

  // BESTAANDE KOLOM
  IntColumn get defaultRestSeconds => integer().nullable()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // *** NIEUWE EXERCISE SETTINGS KOLOMMEN ***
  RealColumn get weightIncrement => real().withDefault(const Constant(2.5))();
  IntColumn get repsIncrement => integer().withDefault(const Constant(1))();
  IntColumn get timeIncrement => integer().withDefault(const Constant(15))();
  BoolColumn get autoStartTimer =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get vibrateEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(false))();

  // *** MYO-REPS SETTINGS KOLOMMEN ***
  BoolColumn get myoRepsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get myoRestSeconds => integer().withDefault(const Constant(15))();
  IntColumn get maxMyoSets => integer().withDefault(const Constant(3))();
  IntColumn get myoTargetReps => integer().withDefault(const Constant(3))();
  IntColumn get myoRirThreshold => integer().withDefault(const Constant(1))();

  // *** CLASSIFICATION & TRACKING KOLOMMEN ***
  TextColumn get defaultGraphType =>
      text().withDefault(const Constant('estimated_1rm'))();
  TextColumn get recordCalculationMethod =>
      text().withDefault(const Constant('1rm_formula'))();
  BoolColumn get isGenericExercise =>
      boolean().withDefault(const Constant(false))();
  TextColumn get equipmentNotes => text().nullable()();
  TextColumn get notes => text().nullable()();
}

// Flexible measurement types (weight, reps, time, resistance_band_color, etc.)
@DataClassName('ValueType')
class ValueTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get dataType => text().withLength(min: 1, max: 20)();
  TextColumn get unit => text().nullable().withLength(max: 20)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
}

// Non-numeric values (PURPLE, RED, EXTRA_STRONG, etc.)
@DataClassName('CategoricalValue')
class CategoricalValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get valueTypeId => integer().references(ValueTypes, #id)();
  TextColumn get value => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// What value types each exercise tracks
@DataClassName('ExerciseValueType')
class ExerciseValueTypes extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get valueTypeId => integer().references(ValueTypes, #id)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  TextColumn get defaultValue => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {exerciseId, valueTypeId};
}

// Exercise availability per gym (many-to-many)
@DataClassName('ExerciseGym')
class ExerciseGyms extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get gymId => integer().references(Gyms, #id)();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {exerciseId, gymId};
}

// Exercise muscle group assignments (many-to-many with percentages)
@DataClassName('ExerciseCategory')
class ExerciseCategories extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get primaryMusclePercentage =>
      integer().withDefault(const Constant(100))();

  @override
  Set<Column> get primaryKey => {exerciseId, categoryId};
}

// Exercise type assignments (many-to-many)
@DataClassName('ExerciseTypeLink')
class ExerciseTypeLinks extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get exerciseTypeId => integer().references(ExerciseTypes, #id)();

  @override
  Set<Column> get primaryKey => {exerciseId, exerciseTypeId};
}
