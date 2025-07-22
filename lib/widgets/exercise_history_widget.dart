// ═══════════════════════════════════════════════════════════════
// WIDGET: ExerciseHistoryWidget
// PURPOSE: Display exercise history (BACK TO ORIGINAL SIGNATURE FOR NOW)
// DEPENDENCIES: Material, AppDatabase, drift, HyperTrackTheme
// RELATIONSHIPS: Child of ContainerScreen, displays history data
// THEMING: Basic styling for now, HyperTrack theme can be added later
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../theme/app_theme.dart';
import '../database/database.dart';

class ExerciseHistoryWidget extends StatefulWidget {
  // CALLBACK APPROACH (better than GlobalKey)
  final int userId;
  final int exerciseId;
  final String exerciseName;
  final Function(String message) onStatusUpdate;
  final Function(String error) onError;
  final Function(Future<void> Function())? onRegisterRefresh;

  const ExerciseHistoryWidget({
    super.key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.onStatusUpdate,
    required this.onError,
    this.onRegisterRefresh,
  });

  @override
  State<ExerciseHistoryWidget> createState() => _ExerciseHistoryWidgetState();
}

class _ExerciseHistoryWidgetState extends State<ExerciseHistoryWidget> {
  // ─────────────────────────────────────────────────────────────
  // STATE (ORIGINAL PATTERN FOR NOW)
  // ─────────────────────────────────────────────────────────────

  final AppDatabase _database = AppDatabase();

  var _isLoading = true;
  String _lastPerformance = "";
  List<Map<String, dynamic>> _recentSets = [];

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Register refresh callback with Container (BETTER APPROACH)
    if (widget.onRegisterRefresh != null) {
      widget.onRegisterRefresh!(refreshHistory);
    }

    _loadHistoryData();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // DATABASE OPERATIONS (ORIGINAL PATTERN)
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadHistoryData() async {
    try {
      widget.onStatusUpdate("Loading exercise history...");

      // Load last performance for smart suggestions (ORIGINAL LOGIC)
      final lastPerformance = await _database.getLastPerformanceForExercise(
        widget.userId,
        widget.exerciseId,
      );

      String lastPerfText = "";
      if (lastPerformance != null && lastPerformance.isNotEmpty) {
        // Extract weight and reps from SetValue objects (ORIGINAL LOGIC)
        double? weight;
        int? reps;

        for (final value in lastPerformance) {
          if (value.numericValue != null) {
            if (weight == null) {
              weight = value.numericValue!;
            } else {
              reps = value.numericValue!.toInt();
            }
          }
        }

        if (weight != null && reps != null) {
          lastPerfText = "Last time: ${weight}kg × $reps reps";
        }
      }

      // Load recent sets using existing database method
      await _loadRecentSets();

      setState(() {
        _lastPerformance = lastPerfText;
        _isLoading = false;
      });

      final message = lastPerfText.isNotEmpty
          ? "History loaded: $lastPerfText"
          : "No previous history found";
      widget.onStatusUpdate(message);
    } catch (e) {
      widget.onError('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentSets() async {
    try {
      // Use existing database method that we know works
      final rawSets = await _database.getAllSetsForExerciseRaw(
        widget.userId,
        widget.exerciseId,
        widget.exerciseId, // Using exerciseId as workoutId for now
      );

      // Convert to display format
      final List<Map<String, dynamic>> processedSets = [];
      for (final rawSet in rawSets.take(10)) {
        // Show last 10 sets
        processedSets.add({
          'setNumber': rawSet['setNumber'] ?? 1,
          'weight': rawSet['weight'] ?? 0.0,
          'reps': rawSet['reps'] ?? 0,
          'rir': rawSet['rir'] ?? 0,
          'completedAt': rawSet['completedAt'],
          'workoutName': rawSet['workoutName'] ?? 'Workout',
        });
      }

      setState(() {
        _recentSets = processedSets;
      });
    } catch (e) {
      print('Error loading recent sets: $e');
      // Continue with empty recent sets - not critical
    }
  }

  // ADD REFRESH METHOD (for Container to call when sets are completed)
  Future<void> refreshHistory() async {
    await _loadHistoryData();
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD METHODS
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(LucideIcons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Exercise History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            // History count badge
            if (_recentSets.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_recentSets.length} sets",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoading) ...[
          // Loading State
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else ...[
          // Smart History Display
          _buildSmartHistoryCard(),
          const SizedBox(height: 16),

          // Recent Sets Display
          _buildRecentSetsSection(),
        ],
      ],
    );
  }

  Widget _buildSmartHistoryCard() {
    if (_lastPerformance.isEmpty) {
      // First time message
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade50,
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.info, size: 16, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No previous history - This will be your first set!',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    // Smart history display
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Smart History',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lastPerformance,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready for your next set!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSetsSection() {
    if (_recentSets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(LucideIcons.dumbbell, size: 24, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No recent sets to display',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.list, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('Recent Sets', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),

        // Recent sets list
        ..._recentSets.take(5).map((setData) => _buildRecentSetCard(setData)),
      ],
    );
  }

  Widget _buildRecentSetCard(Map<String, dynamic> setData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          // Set indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${setData['setNumber']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Set details
          Expanded(
            child: Text(
              '${setData['weight']}kg × ${setData['reps']} reps @ RIR ${setData['rir']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Time indicator
          Text(
            _formatTimeAgo(setData['completedAt']),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────

  String _formatTimeAgo(dynamic completedAt) {
    if (completedAt == null) return 'Recent';

    try {
      DateTime date;
      if (completedAt is String) {
        date = DateTime.parse(completedAt);
      } else if (completedAt is DateTime) {
        date = completedAt;
      } else {
        return 'Recent';
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else {
        return 'Recent';
      }
    } catch (e) {
      return 'Recent';
    }
  }
}
