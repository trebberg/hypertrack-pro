// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Layout manager with imported components architecture
// DEPENDENCIES: Material, AppHeaderWidget, HyperTrackTheme, exercise components
// RELATIONSHIPS: Parent to all feature components, layout orchestration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/app_header_widget.dart';
import '../widgets/exercise_input_widget.dart';
import '../theme/app_theme.dart';
import '../models/exercise_set.dart';
// TODO: Import when created
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
  String _statusMessage = "ExerciseInputWidget loaded - Real component active";

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
      _statusMessage = "ExerciseInputWidget loaded for ${widget.exerciseName}";
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

  void _handleNavigationRequest() {
    // Navigation now handled by AppHeaderWidget PopupMenu
    print("Container: Navigation menu requested");
    _handleComponentUpdate("Navigation", "Menu accessed via three-dots");
  }

  void _handleExerciseSettingsRequest() {
    // Future: Open exercise settings modal
    print("Container: Exercise settings requested");
    _handleComponentUpdate("Settings", "Exercise configuration opened");
    _showExerciseSettings();
  }

  // ─────────────────────────────────────────────────────────────
  // EXERCISE INPUT WIDGET CALLBACKS
  // ─────────────────────────────────────────────────────────────

  void _handleSetCompleted(ExerciseSet setData) {
    _handleComponentUpdate(
      "ExerciseInput",
      "Set ${setData.setNumber} completed: ${setData.weight}kg × ${setData.reps} reps",
    );
    print("Container: Set completed - ${setData.displayText}");
  }

  void _handleInputError(String error) {
    _handleComponentUpdate("ExerciseInput", "Error: $error");
    print("Container: Input error - $error");

    // Show snackbar for user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $error"),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
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
        onMenuPressed: _handleNavigationRequest,
        onSettingsPressed: _handleExerciseSettingsRequest,
      ),

      // COMPONENT COMPOSITION BODY
      body: _buildComponentBody(),

      backgroundColor: HyperTrackTheme.almostWhite, // 🎨 NEW: Themed background
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

          // 🎯 REAL EXERCISE INPUT WIDGET - ACTIVE COMPONENT
          ExerciseInputWidget(
            userId: widget.userId,
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            exerciseName: widget.exerciseName,
            onStatusUpdate: (message) =>
                _handleComponentUpdate("ExerciseInput", message),
            onSetCompleted: _handleSetCompleted,
            onError: _handleInputError,
          ),
          const SizedBox(height: 16),

          // Remaining component placeholders
          _buildComponentPlaceholder(
            "ExerciseHistoryWidget",
            "Previous sets display with smart history (~150 lines)",
            LucideIcons.history,
            'history',
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseTimerWidget",
            "Rest timer with persistence (~100 lines)",
            LucideIcons.timer,
            'timer',
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseGraphWidget",
            "Performance visualization (~200 lines)",
            LucideIcons.trendingUp,
            'trend',
          ),
          const SizedBox(height: 16),

          _buildComponentPlaceholder(
            "ExerciseStatsWidget",
            "Session statistics and records (~150 lines)",
            LucideIcons.barChart3,
            'stats',
          ),
        ],
      ),
    );
  }

  Widget _buildContainerStatus() {
    return HyperTrackTheme.themedContainer(
      // 🎨 NEW: Themed container with outline
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.layers,
                'exercises',
                size: 24,
              ), // 🎨 NEW: Colored icon
              const SizedBox(width: 12),
              const Text(
                "Component Architecture - ExerciseInputWidget ACTIVE",
                style: HyperTrackTheme.headerText, // 🎨 NEW: Themed typography
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Status: $_statusMessage",
            style: HyperTrackTheme.bodyText, // 🎨 NEW: Themed body text
          ),
          const SizedBox(height: 12),

          // Status indicators with colored icons
          Row(
            children: [
              HyperTrackTheme.coloredIcon(LucideIcons.check, 'add', size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "ExerciseInputWidget: Weight/reps/RIR input with database",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(LucideIcons.check, 'add', size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "Smart History: Last performance display working",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(LucideIcons.check, 'add', size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "HyperTrack Design System: Purple exercise theming",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.dumbbell,
                'exercises',
                size: 14,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "First real exercise component successfully integrated",
                  style: HyperTrackTheme.captionText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentPlaceholder(
    String componentName,
    String description,
    IconData icon,
    String iconType,
  ) {
    return HyperTrackTheme.outlinedCard(
      // 🎨 NEW: Themed card with outline
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                icon,
                iconType,
                size: 20,
              ), // 🎨 NEW: Colored functional icon
              const SizedBox(width: 12),
              Text(
                componentName,
                style: HyperTrackTheme.headerText, // 🎨 NEW: Themed typography
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: HyperTrackTheme.bodyText, // 🎨 NEW: Themed body text
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HyperTrackTheme.coloredIcon(
                LucideIcons.code,
                'settings',
                size: 12,
              ),
              const SizedBox(width: 6),
              const Text(
                "TODO: Import and integrate actual component",
                style: HyperTrackTheme.captionText, // 🎨 NEW: Themed caption
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT HANDLERS (MODAL DIALOGS)
  // ─────────────────────────────────────────────────────────────

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
