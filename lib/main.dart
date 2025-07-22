import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/container_screen.dart'; // ✅ MISSING IMPORT FIXED!

void main() {
  runApp(const HyperTrackProApp());
}

class HyperTrackProApp extends StatelessWidget {
  const HyperTrackProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro',
      theme: HyperTrackTheme.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperTrack Pro'),
        backgroundColor: HyperTrackTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: HyperTrackTheme.almostWhite,
      body: SingleChildScrollView(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phase 1.5 Status', style: HyperTrackTheme.headerText),
                  const SizedBox(height: 8),
                  Text(
                    '✅ Foundation Complete\n'
                    '✅ Container Architecture (189 lines)\n'
                    '✅ AppHeaderWidget (150 lines)\n'
                    '✅ HyperTrack Design System\n'
                    '🔄 Ready for exercise components',
                    style: HyperTrackTheme.bodyText,
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
                  Text('Test Exercises', style: HyperTrackTheme.headerText),
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
                  Text('Next Components', style: HyperTrackTheme.headerText),
                  const SizedBox(height: 8),
                  Text(
                    'Phase 1.5.2: Core Exercise Components\n'
                    '• ExerciseInputWidget (weight/reps)\n'
                    '• ExerciseHistoryWidget (smart history)\n'
                    '• ExerciseTimerWidget (rest timer)',
                    style: HyperTrackTheme.bodyText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToExercise(BuildContext context, String exerciseName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContainerScreen(
          userId: 1,
          workoutId: 1,
          exerciseId: 1,
          exerciseName: exerciseName,
        ),
      ),
    );
  }
}
