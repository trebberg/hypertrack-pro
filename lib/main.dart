import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/container_screen.dart';

void main() {
  runApp(const HyperTrackProApp());
}

class HyperTrackProApp extends StatelessWidget {
  const HyperTrackProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro',
      theme: HyperTrackTheme.theme, // ✅ FIX: theme instead of lightTheme
      home: const HyperTrackHomePage(),
    );
  }
}

class HyperTrackHomePage extends StatelessWidget {
  const HyperTrackHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HyperTrack Pro - Component Testing',
          style: HyperTrackTheme.headerText,
        ), // ✅ FIX: Text widget with style
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Component Testing Environment', // ✅ FIX: Text widget with style
                    style: HyperTrackTheme.headerText,
                  ),
                  Text(
                    'Foundation architecture complete:\n'
                    '✅ Container Screen (189 lines)\n'
                    '✅ AppHeaderWidget (150 lines)\n'
                    '✅ HyperTrack Design System\n'
                    '🔄 Ready for exercise components',
                    style: HyperTrackTheme
                        .bodyText, // ✅ FIX: Text widget with style
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test exercises section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Exercises',
                    style: HyperTrackTheme.headerText,
                  ), // ✅ FIX: Text widget with style
                  const SizedBox(height: 16),
                  ...['Bench Press', 'Squat', 'Deadlift', 'Overhead Press'].map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _navigateToExercise(context, exercise),
                          child: Text(exercise),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Next components section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Components',
                    style: HyperTrackTheme.headerText,
                  ), // ✅ FIX: Text widget with style
                  Text(
                    'Phase 1.5.2: Core Exercise Components\n'
                    '• ExerciseInputWidget (weight/reps)\n'
                    '• ExerciseHistoryWidget (smart history)\n'
                    '• ExerciseTimerWidget (rest timer)',
                    style: HyperTrackTheme
                        .bodyText, // ✅ FIX: Text widget with style
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Status footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HyperTrack Design System Active',
                    style: HyperTrackTheme.bodyText,
                  ), // ✅ FIX: Text widget with style
                  Text(
                    'Container architecture ready • AppHeader integrated', // ✅ FIX: Text widget with style
                    style: HyperTrackTheme.captionText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _navigateToExercise(BuildContext context, String exerciseName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContainerScreen(
          // ✅ FIX: Added required parameters
          userId: 1,
          workoutId: 1,
          exerciseId: 1,
          exerciseName: exerciseName,
        ),
      ),
    );
  }
}

class ExerciseButton extends StatelessWidget {
  final String exerciseName;

  const ExerciseButton({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ContainerScreen(
                // ✅ FIX: Added required parameters
                userId: 1,
                workoutId: 1,
                exerciseId: 1,
                exerciseName: exerciseName,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Row(
          children: [
            Text(
              exerciseName,
              style: HyperTrackTheme.headerText.copyWith(color: Colors.white),
            ), // ✅ FIX: Text widget with style
            const Spacer(),
            Text(
              'Test Component →', // ✅ FIX: Text widget with style
              style: HyperTrackTheme.captionText.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
