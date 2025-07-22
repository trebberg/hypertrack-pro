// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Layout manager with imported components architecture
// DEPENDENCIES: Material, AppHeaderWidget, exercise components
// RELATIONSHIPS: Parent to all feature components, layout orchestration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/app_header_widget.dart';
// TODO: Import when created
// import '../widgets/exercise_input_widget.dart';
// import '../widgets/exercise_history_widget.dart';

class ContainerScreen extends StatefulWidget {
  final int userId;
  final int workoutId;
  final int exerciseId;
  final String exerciseName;

  const ContainerScreen({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends State<ContainerScreen> {
  // ─────────────────────────────────────────────────────────────
  // CONTAINER STATE MANAGEMENT
  // ─────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String _statusMessage = "AppHeaderWidget integration successful";

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeContainer();
  }

  void _initializeContainer() {
    setState(() {
      _statusMessage = "Layout manager ready for ${widget.exerciseName}";
    });
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENT COMMUNICATION HUB
  // ─────────────────────────────────────────────────────────────

  void _handleComponentUpdate(String component, String message) {
    setState(() {
      _statusMessage = "$component: $message";
    });
  }

  void _handleNavigationRequest(String destination) {
    // Future: Handle navigation between modules
    print("Container: Navigation to $destination requested");
    _handleComponentUpdate("Navigation", "Request to $destination");
    _showNavigationMenu();
  }

  void _handleExerciseSettingsRequest() {
    // Future: Open exercise settings modal
    print("Container: Exercise settings requested");
    _handleComponentUpdate("Settings", "Exercise configuration opened");
    _showExerciseSettings();
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTED HEADER COMPONENT
      appBar: AppHeaderWidget(
        title: widget.exerciseName,
        onMenuPressed: () => _handleNavigationRequest("menu"),
        onSettingsPressed: _handleExerciseSettingsRequest,
      ),

      // COMPONENT COMPOSITION BODY
      body: _buildComponentBody(),

      backgroundColor: Colors.grey.shade50,
    );
  }

  Widget _buildComponentBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container status display
          _buildContainerStatus(),
          const SizedBox(height: 24),

          // Component placeholders (to be replaced with actual components)
          _buildComponentPlaceholder(
            "ExerciseInputWidget",
            "Weight/reps/RIR input with validation (~200 lines)",
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseHistoryWidget",
            "Previous sets display with smart history (~150 lines)",
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseTimerWidget",
            "Rest timer with persistence (~100 lines)",
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseGraphWidget",
            "Performance visualization (~200 lines)",
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseStatsWidget",
            "Session statistics and records (~150 lines)",
          ),
        ],
      ),
    );
  }

  Widget _buildContainerStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layers, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                "Component Architecture - Foundation Complete",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Status: $_statusMessage",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          const Text(
            "✅ Layout manager with component composition",
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
          const Text(
            "✅ AppHeaderWidget successfully integrated",
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
          const Text(
            "✅ Component communication hub established",
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
          const Text(
            "🔄 Ready for exercise component creation",
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentPlaceholder(String componentName, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.package, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                componentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            "// TODO: Import and integrate actual component",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT HANDLERS (MODAL DIALOGS)
  // ─────────────────────────────────────────────────────────────

  void _showNavigationMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Navigation Menu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                _handleComponentUpdate("Navigation", "Navigate to Home");
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.dumbbell),
              title: const Text("Exercises"),
              onTap: () {
                Navigator.pop(context);
                _handleComponentUpdate("Navigation", "Navigate to Exercises");
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: const Text("Gyms"),
              onTap: () {
                Navigator.pop(context);
                _handleComponentUpdate("Navigation", "Navigate to Gyms");
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.barChart3),
              title: const Text("Statistics"),
              onTap: () {
                Navigator.pop(context);
                _handleComponentUpdate("Navigation", "Navigate to Statistics");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.settings),
            SizedBox(width: 8),
            Text("Exercise Settings"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Exercise: ${widget.exerciseName}"),
            const SizedBox(height: 16),
            const Text("Settings options:"),
            const SizedBox(height: 8),
            const Text("• Exercise availability per gym"),
            const Text("• Rest timer preferences"),
            const Text("• Weight increment settings"),
            const Text("• Performance tracking options"),
            const SizedBox(height: 16),
            const Text(
              "TODO: Implement actual settings widget",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleComponentUpdate("Settings", "Settings saved");
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
