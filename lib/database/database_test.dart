import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift; // MISSING IMPORT for Value()
import 'database.dart';

class DatabaseTest {
  static Future<void> testDatabaseConnectivity() async {
    try {
      final database = AppDatabase();

      print("🔄 Testing full Phase 1 database...");

      // Test basic connectivity
      final result = await database.customSelect('SELECT 1 as test').get();
      print("✅ Database connection successful: ${result.first.data}");

      // Test 1: Create user
      final userId = await database
          .into(database.users)
          .insert(UsersCompanion.insert(name: "Test User"));
      print("✅ Created user with ID: $userId");

      // Test 2: Create gym
      final gymId = await database
          .into(database.gyms)
          .insert(
            GymsCompanion.insert(
              userId: userId,
              name: "Test Gym",
              isFavorite: const drift.Value(true),
            ),
          );
      print("✅ Created gym with ID: $gymId");

      // Test 3: Create category
      final categoryId = await database
          .into(database.categories)
          .insert(CategoriesCompanion.insert(name: "Chest"));
      print("✅ Created category with ID: $categoryId");

      // Test 4: Create value types
      final weightTypeId = await database
          .into(database.valueTypes)
          .insert(
            ValueTypesCompanion.insert(
              name: "weight",
              dataType: "numeric",
              unit: const drift.Value("kg"),
            ),
          );

      final repsTypeId = await database
          .into(database.valueTypes)
          .insert(
            ValueTypesCompanion.insert(
              name: "reps",
              dataType: "numeric",
              unit: const drift.Value("count"),
            ),
          );
      print("✅ Created value types: weight($weightTypeId), reps($repsTypeId)");

      // Test 5: Create exercise
      final exerciseId = await database
          .into(database.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: "Bench Press",
              instructions: const drift.Value("Lie on bench, press weight up"),
              defaultRestSeconds: const drift.Value(90),
            ),
          );
      print("✅ Created exercise with ID: $exerciseId");

      // Test 6: Link exercise to value types
      await database
          .into(database.exerciseValueTypes)
          .insert(
            ExerciseValueTypesCompanion.insert(
              exerciseId: exerciseId,
              valueTypeId: weightTypeId,
              isRequired: const drift.Value(true),
              sortOrder: const drift.Value(1),
            ),
          );

      await database
          .into(database.exerciseValueTypes)
          .insert(
            ExerciseValueTypesCompanion.insert(
              exerciseId: exerciseId,
              valueTypeId: repsTypeId,
              isRequired: const drift.Value(true),
              sortOrder: const drift.Value(2),
            ),
          );
      print("✅ Linked exercise to value types");

      // Test 7: Link exercise to gym
      await database
          .into(database.exerciseGyms)
          .insert(
            ExerciseGymsCompanion.insert(
              exerciseId: exerciseId,
              gymId: gymId,
              isAvailable: const drift.Value(true),
            ),
          );
      print("✅ Linked exercise to gym");

      // Test 8: Create workout with flexible measurement system
      final workoutId = await database
          .into(database.workouts)
          .insert(
            WorkoutsCompanion.insert(
              userId: userId,
              gymId: drift.Value(gymId),
              name: const drift.Value("Test Workout"),
            ),
          );

      final workoutExerciseId = await database
          .into(database.workoutExercises)
          .insert(
            WorkoutExerciseCompanion.insert(
              workoutId: workoutId,
              exerciseId: exerciseId,
              sortOrder: const drift.Value(1),
            ),
          );

      final setId = await database
          .into(database.sets)
          .insert(
            SetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: 1,
              repsInReserve: const drift.Value(2),
            ),
          );

      // Add weight value
      await database
          .into(database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: weightTypeId,
              numericValue: const drift.Value(80.0),
            ),
          );

      // Add reps value
      await database
          .into(database.setValues)
          .insert(
            SetValuesCompanion.insert(
              setId: setId,
              valueTypeId: repsTypeId,
              numericValue: const drift.Value(8.0),
            ),
          );

      print("✅ Created complete workout with flexible values");

      // Test 9: Smart history query
      final lastPerformance = await database.getLastPerformanceForExercise(
        userId,
        exerciseId,
      );
      print("✅ Smart history retrieved ${lastPerformance.length} values");

      // Test 10: Gym exercises query
      final gymExercises = await database.getExercisesForGym(gymId);
      print("✅ Found ${gymExercises.length} exercises available at gym");

      // Test 11: Exercise value types query
      final exerciseValueTypes = await database.getValueTypesForExercise(
        exerciseId,
      );
      print("✅ Found ${exerciseValueTypes.length} value types for exercise");

      print("🎉 ALL PHASE 1 DATABASE TESTS PASSED!");
      print("📊 Database supports:");
      print("   - Flexible measurement system (numeric values)");
      print("   - Smart history queries");
      print("   - Gym-exercise relationships");
      print("   - Complex workout structure");
      print("   - Ready for UI development!");

      await database.close();
    } catch (e) {
      print("❌ Database test failed: $e");
      if (kDebugMode) {
        print("Stack trace: ${StackTrace.current}");
      }
    }
  }
}
