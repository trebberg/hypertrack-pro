// ═══════════════════════════════════════════════════════════════
// WIDGET: Container Screen
// PURPOSE: Layout manager with imported components architecture
// DEPENDENCIES: Material, AppHeaderWidget, exercise components
// RELATIONSHIPS: Parent to all feature components, layout orchestration
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// TODO: Import when created
// import '../widgets/app_header_widget.dart';
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
  String _statusMessage = "Container initialized - component architecture";

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
  }

  void _handleExerciseSettingsRequest() {
    // Future: Open exercise settings modal
    print("Container: Exercise settings requested");
    _handleComponentUpdate("Settings", "Exercise configuration opened");
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IMPORTED HEADER COMPONENT
      appBar: _buildAppHeaderWidget(),

      // COMPONENT COMPOSITION BODY
      body: _buildComponentBody(),

      backgroundColor: Colors.grey.shade50,
    );
  }

  PreferredSizeWidget _buildAppHeaderWidget() {
    // TODO: Replace with actual AppHeaderWidget import
    // return AppHeaderWidget(
    //   title: widget.exerciseName,
    //   onMenuPressed: _handleNavigationRequest,
    //   onSettingsPressed: _handleExerciseSettingsRequest,
    // );

    // TEMPORARY: Manual header until AppHeaderWidget created
    return AppBar(
      // LEFT: Navigation menu
      leading: IconButton(
        icon: const Icon(LucideIcons.menu),
        onPressed: () => _showNavigationMenu(),
        tooltip: "Navigation Menu",
      ),

      // CENTER: Context title
      title: Text(
        widget.exerciseName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),

      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,

      // RIGHT: Contextual settings
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings),
          onPressed: _handleExerciseSettingsRequest,
          tooltip: "Exercise Settings",
        ),
      ],
    );
  }

  Widget _buildComponentBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // COMPONENT COMPOSITION ARCHITECTURE
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATUS INDICATOR (temporary)
          _buildStatusCard(),

          const SizedBox(height: 16),

          // TODO: Replace with actual imported components
          // ExerciseInputWidget(
          //   exerciseId: widget.exerciseId,
          //   onSetComplete: (setData) => _handleComponentUpdate("Input", "Set completed"),
          // ),

          // ExerciseHistoryWidget(
          //   exerciseId: widget.exerciseId,
          //   userId: widget.userId,
          //   onSetEdit: (setId) => _handleComponentUpdate("History", "Set $setId edited"),
          // ),

          // TEMPORARY: Component placeholders
          _buildComponentPlaceholder(
            "ExerciseInputWidget",
            "Weight/reps input form",
          ),
          const SizedBox(height: 16),
          _buildComponentPlaceholder(
            "ExerciseHistoryWidget",
            "Previous sets display",
          ),
          const SizedBox(height: 16),
          _buildComponentPlaceholder(
            "ExerciseTimerWidget",
            "Rest timer controls",
          ),
          const SizedBox(height: 16),
          _buildComponentPlaceholder(
            "ExerciseGraphWidget",
            "Performance visualization",
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.layers, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  "Component Architecture Container",
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
              "✅ AppHeaderWidget integration ready",
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
            const Text(
              "🔄 Next: Create small components (<250 lines each)",
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
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
                _handleNavigationRequest("home");
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.dumbbell),
              title: const Text("Exercises"),
              onTap: () {
                Navigator.pop(context);
                _handleNavigationRequest("exercises");
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: const Text("Gyms"),
              onTap: () {
                Navigator.pop(context);
                _handleNavigationRequest("gyms");
              },
            ),
          ],
        ),
      ),
    );
  }
}
