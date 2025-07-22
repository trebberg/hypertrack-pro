import 'package:flutter/material.dart';
import 'screens/container_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HyperTrackApp());
}

class HyperTrackApp extends StatelessWidget {
  const HyperTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperTrack Pro',
      theme: HyperTrackTheme.theme, // 🎨 NEW: Custom theme
      home: const DemoLandingScreen(),
    );
  }
}

class DemoLandingScreen extends StatelessWidget {
  const DemoLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HyperTrack Pro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Themed icon with color
              HyperTrackTheme.coloredIcon(
                Icons.fitness_center,
                'exercises',
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                'HyperTrack Pro',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Monotone Design + Color Icons',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Themed container button
              HyperTrackTheme.themedContainer(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContainerScreen(
                          userId: 1,
                          workoutId: 1,
                          exerciseId: 1,
                          exerciseName: "Bench Press",
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HyperTrackTheme.coloredIcon(
                          Icons.architecture,
                          'exercises',
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('🏗️ Foundation + Theme Demo'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Color preview row
              HyperTrackTheme.outlinedCard(
                child: Column(
                  children: [
                    const Text('Icon Colors Preview:'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        HyperTrackTheme.coloredIcon(
                          Icons.home,
                          'home',
                          size: 24,
                        ),
                        HyperTrackTheme.coloredIcon(
                          Icons.fitness_center,
                          'exercises',
                          size: 24,
                        ),
                        HyperTrackTheme.coloredIcon(
                          Icons.location_on,
                          'gyms',
                          size: 24,
                        ),
                        HyperTrackTheme.coloredIcon(
                          Icons.bar_chart,
                          'stats',
                          size: 24,
                        ),
                        HyperTrackTheme.coloredIcon(
                          Icons.timer,
                          'timer',
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
