// ═══════════════════════════════════════════════════════════════
// MAIN APPLICATION ENTRY POINT
// PURPOSE: HyperTrack Pro app initialization with component testing
// DEPENDENCIES: Flutter Material, HyperTrackTheme, ContainerScreen
// THEMING: Complete HyperTrack Design System integration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/container_screen.dart';

void main() {
  runApp(const HyperTrackProApp());
}

class HyperTrackProApp extends StatelessWidget {
  const HyperTrackProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro - Component Testing',
      theme: HyperTrackTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ComponentTestingLauncher(),
    );
  }
}

class ComponentTestingLauncher extends StatelessWidget {
  const ComponentTestingLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyperTrackTheme.almostWhite,
      appBar: AppBar(
        title: HyperTrackTheme.headerText('HyperTrack Pro - Component Testing'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HyperTrackTheme.outlinedCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyperTrackTheme.headerText('Component Testing Environment'),
                    const SizedBox(height: 8),
                    HyperTrackTheme.bodyText(
                      'Testing the first two components:\n'
                      '• SetCountingWidget (195 lines)\n'
                      '• ExerciseInputWidget (256 lines)\n'
                      '• ExerciseInputContainer (280 lines)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            HyperTrackTheme.outlinedCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyperTrackTheme.headerText('Test Exercises'),
                    const SizedBox(height: 12),
                    _buildExerciseTestButton(
                      context,
                      'Bench Press',
                      'bench_press_001',
                      'Test weight/reps input with set counting',
                    ),
                    const SizedBox(height: 8),
                    _buildExerciseTestButton(
                      context,
                      'Squats',
                      'squats_001',
                      'Test multi-set progression with validation',
                    ),
                    const SizedBox(height: 8),
                    _buildExerciseTestButton(
                      context,
                      'Deadlifts',
                      'deadlifts_001',
                      'Test component communication and theming',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            HyperTrackTheme.outlinedCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyperTrackTheme.headerText('Next Components'),
                    const SizedBox(height: 8),
                    HyperTrackTheme.bodyText(
                      '🔄 RIRSelectionWidget (Component 3)\n'
                      '🔄 SetSubmissionWidget (Component 4)\n'
                      '🔄 ExerciseTimerWidget (Component 5)',
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HyperTrackTheme.getIconColor(
                  'exercise',
                ).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HyperTrackTheme.getIconColor(
                    'exercise',
                  ).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HyperTrackTheme.bodyText('HyperTrack Design System Active'),
                  const SizedBox(height: 4),
                  HyperTrackTheme.captionText(
                    'Monotone outlines + colorful functional icons\n'
                    'Exercise: Purple • Timer: Red • Stats: Gold',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTestButton(
    BuildContext context,
    String exerciseName,
    String exerciseId,
    String description,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContainerScreen(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: HyperTrackTheme.getIconColor('exercise'),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HyperTrackTheme.headerText(exerciseName, color: Colors.white),
            const SizedBox(height: 4),
            HyperTrackTheme.captionText(
              description,
              color: Colors.white.withOpacity(0.9),
            ),
          ],
        ),
      ),
    );
  }
}
