// ═══════════════════════════════════════════════════════════════
// WIDGET: AppHeaderWidget
// PURPOSE: Uniform navigation header for all screens with contextual functionality
// DEPENDENCIES: Material, LucideIcons
// RELATIONSHIPS: Child of Container (via appBar), receives props and sends callbacks
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  // ─────────────────────────────────────────────────────────────
  // CONSTRUCTOR & PROPERTIES
  // ─────────────────────────────────────────────────────────────

  final String title;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeaderWidget({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.onSettingsPressed,
    this.showBackButton = false,
    this.onBackPressed,
  });

  // ─────────────────────────────────────────────────────────────
  // PREFERRED SIZE IMPLEMENTATION
  // ─────────────────────────────────────────────────────────────

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // LEFT: Navigation control
      leading: _buildLeadingWidget(),

      // CENTER: Context-aware title
      title: _buildTitleWidget(),

      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shadowColor: Colors.grey.shade200,

      // RIGHT: Contextual actions
      actions: _buildActionWidgets(),
    );
  }

  Widget _buildLeadingWidget() {
    if (showBackButton) {
      return IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: onBackPressed ?? () {},
        tooltip: "Back",
      );
    }

    // Navigation as elegant three vertical dots menu (top-anchored)
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical),
      tooltip: "Navigation Menu",
      onSelected: _handleNavigationSelection,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'home',
          child: Row(
            children: [
              Icon(LucideIcons.home, size: 16),
              SizedBox(width: 8),
              Text('Home'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'exercises',
          child: Row(
            children: [
              Icon(LucideIcons.dumbbell, size: 16),
              SizedBox(width: 8),
              Text('Exercises'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'gyms',
          child: Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16),
              SizedBox(width: 8),
              Text('Gyms'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'stats',
          child: Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16),
              SizedBox(width: 8),
              Text('Statistics'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleWidget() {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _buildActionWidgets() {
    return [
      // Settings button (exercise-specific)
      IconButton(
        icon: const Icon(LucideIcons.settings),
        onPressed: onSettingsPressed,
        tooltip: "Exercise Settings",
      ),
      const SizedBox(width: 4), // Small right padding
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────

  void _handleNavigationSelection(String value) {
    // Trigger the navigation callback with the selected destination
    onMenuPressed(); // Keep existing callback for compatibility
    print("AppHeaderWidget: Navigation - $value");

    // Future: Could pass specific value to parent via enhanced callback
    switch (value) {
      case 'home':
        // TODO: Navigate to home
        break;
      case 'exercises':
        // TODO: Navigate to exercises
        break;
      case 'gyms':
        // TODO: Navigate to gyms
        break;
      case 'stats':
        // TODO: Navigate to statistics
        break;
    }
  }
}
