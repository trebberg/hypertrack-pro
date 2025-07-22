// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Top-level screen wrapper for component architecture
// DEPENDENCIES: Material, exercise_logging_screen.dart
// RELATIONSHIPS: Parent to all feature components, navigation hub
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'exercise_logging_screen.dart';

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
  String _statusMessage = "";

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
      _statusMessage = "Container initialized for ${widget.exerciseName}";
    });
  }

  // ─────────────────────────────────────────────────────────────
  // COMPONENT COMMUNICATION HUB
  // ─────────────────────────────────────────────────────────────

  void _handleChildStateUpdate(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _handleWorkoutUpdate() {
    // Future: Handle workout-level state changes
    print("Container: Workout updated");
  }

  void _handleNavigationRequest(String destination) {
    // Future: Handle navigation between components
    print("Container: Navigation to $destination requested");
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      backgroundColor: Colors.grey.shade50,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exerciseName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_statusMessage.isNotEmpty)
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.info),
          onPressed: _showContainerInfo,
          tooltip: "Container Info",
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // PHASE 1.5.1: Render existing exercise_logging_screen as child
    // FUTURE: Replace with decomposed components
    return ExerciseLoggingScreen(
      userId: widget.userId,
      workoutId: widget.workoutId,
      exerciseId: widget.exerciseId,
      exerciseName: widget.exerciseName,
    );
  }

  void _showContainerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Container Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Exercise: ${widget.exerciseName}"),
            Text("Exercise ID: ${widget.exerciseId}"),
            Text("Workout ID: ${widget.workoutId}"),
            Text("User ID: ${widget.userId}"),
            const SizedBox(height: 16),
            const Text(
              "Phase 1.5.1: Foundation container wrapping monolithic screen",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
