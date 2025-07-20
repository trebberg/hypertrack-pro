import 'package:drift/drift.dart';
import 'user_tables.dart';
import 'gym_tables.dart';

// Muscle groups (chest, back, legs, shoulders, etc.)
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(true))(); // System vs user-created
  IntColumn get userId =>
      integer().nullable().references(Users, #id)(); // null for system defaults
}

// Movement types (isometric, endurance, strength, stretch)
@DataClassName('ExerciseType')
class ExerciseTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get userId => integer().nullable().references(Users, #id)();
}

// Exercise definitions
@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get instructions => text().nullable()();
  IntColumn get defaultRestSeconds => integer().nullable()();
  IntColumn get userId =>
      integer().nullable().references(Users, #id)(); // null for system defaults
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Flexible measurement types (weight, reps, time, resistance_band_color, etc.)
@DataClassName('ValueType')
class ValueTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(
    min: 1,
    max: 50,
  )(); // weight, reps, time, resistance_band_color
  TextColumn get dataType =>
      text().withLength(min: 1, max: 20)(); // numeric, categorical, text
  TextColumn get unit =>
      text().nullable().withLength(max: 20)(); // kg, lbs, seconds, minutes
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
}

// Non-numeric values (PURPLE, RED, EXTRA_STRONG, etc.)
@DataClassName('CategoricalValue')
class CategoricalValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get valueTypeId => integer().references(ValueTypes, #id)();
  TextColumn get value =>
      text().withLength(min: 1, max: 50)(); // PURPLE, RED, EXTRA_STRONG
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
      integer().withDefault(const Constant(100))(); // For volume calculations

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
