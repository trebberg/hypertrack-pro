import 'package:drift/drift.dart';
import 'user_tables.dart';

@DataClassName('Gym')
class Gyms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isGeneric => boolean().withDefault(
    const Constant(false),
  )(); // For dumbbells, barbells, bodyweight
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
