import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? previewText;
  final bool hasChanges;
  final Color? accentColor;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    this.previewText,
    this.hasChanges = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? Colors.blue.shade600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: Radius.circular(isExpanded ? 0 : 8),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded
                    ? effectiveAccentColor.withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: Radius.circular(isExpanded ? 0 : 8),
                ),
              ),
              child: Row(
                children: [
                  // Section Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isExpanded
                          ? effectiveAccentColor
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isExpanded
                                ? effectiveAccentColor
                                : Colors.grey.shade700,
                          ),
                        ),

                        // Preview text when collapsed
                        if (!isExpanded && previewText != null) ...[
                          const SizedBox(height: 2),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isExpanded ? 0.0 : 1.0,
                            child: Text(
                              previewText!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Changed indicator dot
                  if (hasChanges)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Expand/Collapse arrow
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0.0, // 0.5 turns = 180 degrees
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content - animated expand/collapse
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized version for settings forms
class SettingsCollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String? previewText;
  final bool hasChanges;

  const SettingsCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    this.previewText,
    this.hasChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      title: title,
      icon: icon,
      child: child,
      isExpanded: isExpanded,
      onToggle: onToggle,
      previewText: previewText,
      hasChanges: hasChanges,
      accentColor: Colors.blue.shade600,
    );
  }
}

// Usage example in settings screens:
/*
SettingsCollapsibleSection(
  title: 'Timer Settings',
  icon: LucideIcons.timer,
  isExpanded: _timersExpanded,
  onToggle: () => setState(() {
    _timersExpanded = !_timersExpanded;
  }),
  previewText: '180s, Auto-start, Vibrate',
  hasChanges: _timerSettingsChanged,
  child: Column(
    children: [
      // Timer settings widgets here
    ],
  ),
)
*/
