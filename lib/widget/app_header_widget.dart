// ═══════════════════════════════════════════════════════════════
// WIDGET: AppHeaderWidget - Simplified
// PURPOSE: Simple header for testing components
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;

  const AppHeaderWidget({
    Key? key,
    required this.title,
    required this.onMenuPressed,
    required this.onSettingsPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(LucideIcons.moreVertical),
        onPressed: () {
          onMenuPressed();
          // Simple menu
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Menu'),
              content: const Text('Navigation menu'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings),
          onPressed: () {
            onSettingsPressed();
            // Simple settings
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Settings'),
                content: const Text('Exercise settings'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
