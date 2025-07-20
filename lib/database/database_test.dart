import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart'; // MISSING IMPORT for Value()
import 'database.dart';

class DatabaseTest {
  static Future<void> testDatabaseConnectivity() async {
    try {
      final database = AppDatabase();

      print("🔄 Testing simple database...");

      // Test basic connectivity
      final result = await database.customSelect('SELECT 1 as test').get();
      print("✅ Database connection successful: ${result.first.data}");

      // Insert test user with correct syntax
      final userId = await database
          .into(database.users)
          .insert(UsersCompanion.insert(name: "Test User"));
      print("✅ Created user with ID: $userId");

      // Insert test workout with correct Value() syntax for nullable fields
      final workoutId = await database
          .into(database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              userId: userId,
              exerciseName: "Bench Press",
              gymId: const Value(null), // nullable field - no gym for now
              weight: const Value(80.0), // nullable field needs Value()
              reps: const Value(8), // nullable field needs Value()
              notes: const Value("Good set"), // nullable field needs Value()
            ),
          );
      print("✅ Created workout with ID: $workoutId");

      // Test simple query
      final lastWorkout = await database.getLastWorkout(userId);
      if (lastWorkout != null) {
        print(
          "✅ Last workout: ${lastWorkout.exerciseName} - ${lastWorkout.weight}kg × ${lastWorkout.reps} reps",
        );
      }

      print("✅ All simple database tests passed!");

      await database.close();
    } catch (e) {
      print("❌ Database test failed: $e");
      if (kDebugMode) {
        print("Stack trace: ${StackTrace.current}");
      }
    }
  }
}
