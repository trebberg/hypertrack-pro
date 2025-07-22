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

    return IconButton(
      icon: const Icon(LucideIcons.menu),
      onPressed: onMenuPressed,
      tooltip: "Navigation Menu",
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
      // Settings button
      IconButton(
        icon: const Icon(LucideIcons.settings),
        onPressed: onSettingsPressed,
        tooltip: "Exercise Settings",
      ),

      // More options menu
      PopupMenuButton<String>(
        icon: const Icon(LucideIcons.moreVertical),
        tooltip: "More Options",
        onSelected: _handleMenuSelection,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(LucideIcons.user, size: 16),
                SizedBox(width: 8),
                Text('Profile'),
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
          const PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(LucideIcons.download, size: 16),
                SizedBox(width: 8),
                Text('Export Data'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16),
                SizedBox(width: 8),
                Text('About'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(width: 4), // Small right padding
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────

  void _handleMenuSelection(String value) {
    // Future: Handle menu selections
    print("AppHeaderWidget: Menu selection - $value");

    switch (value) {
      case 'profile':
        // TODO: Navigate to profile screen
        break;
      case 'stats':
        // TODO: Open statistics view
        break;
      case 'export':
        // TODO: Export data functionality
        break;
      case 'about':
        // TODO: Show about dialog
        break;
    }
  }
}
