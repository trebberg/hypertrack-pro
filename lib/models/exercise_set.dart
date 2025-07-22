// ═══════════════════════════════════════════════════════════════
// MODEL: ExerciseSet
// PURPOSE: Data model for exercise set tracking and component testing
// DEPENDENCIES: None (pure Dart model)
// RELATIONSHIPS: Used by all exercise tracking widgets
// ═══════════════════════════════════════════════════════════════

class ExerciseSet {
  final String id;
  final String exerciseId;
  final int setNumber;
  final double weight;
  final int reps;
  final int rir; // Reps in Reserve (0-5)
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final String? notes;
  final int? restTimeSeconds;

  const ExerciseSet({
    required this.id,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.createdAt,
    required this.isCompleted,
    this.setNumber = 1,
    this.completedAt,
    this.notes,
    this.restTimeSeconds,
  });

  // ─────────────────────────────────────────────────────────────
  // FACTORY CONSTRUCTORS
  // ─────────────────────────────────────────────────────────────

  /// Create a planned set (not yet completed)
  factory ExerciseSet.planned({
    required String exerciseId,
    required double weight,
    required int reps,
    required int rir,
    int setNumber = 1,
    String? notes,
  }) {
    return ExerciseSet(
      id: 'planned_${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rir: rir,
      createdAt: DateTime.now(),
      completedAt: null,
      isCompleted: false,
      notes: notes,
    );
  }

  /// Create a completed set
  factory ExerciseSet.completed({
    required String exerciseId,
    required double weight,
    required int reps,
    required int rir,
    int setNumber = 1,
    String? notes,
    int? restTimeSeconds,
  }) {
    final now = DateTime.now();
    return ExerciseSet(
      id: 'completed_${now.millisecondsSinceEpoch}',
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rir: rir,
      createdAt: now,
      completedAt: now,
      isCompleted: true,
      notes: notes,
      restTimeSeconds: restTimeSeconds,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INSTANCE METHODS
  // ─────────────────────────────────────────────────────────────

  /// Mark this set as completed
  ExerciseSet markCompleted({int? restTimeSeconds}) {
    return ExerciseSet(
      id: id,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      rir: rir,
      createdAt: createdAt,
      completedAt: DateTime.now(),
      isCompleted: true,
      notes: notes,
      restTimeSeconds: restTimeSeconds,
    );
  }

  /// Create a copy with modified values
  ExerciseSet copyWith({
    String? id,
    String? exerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    int? rir,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    String? notes,
    int? restTimeSeconds,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPUTED PROPERTIES
  // ─────────────────────────────────────────────────────────────

  /// Volume calculation (weight × reps)
  double get volume => weight * reps;

  /// Duration since creation
  Duration get durationSinceCreation => DateTime.now().difference(createdAt);

  /// Duration to completion (if completed)
  Duration? get durationToCompletion {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }

  /// Formatted display text
  String get displayText => '${weight}kg × ${reps} reps @ RIR $rir';

  /// Short display for UI
  String get shortDisplay => '${weight}kg × ${reps}';

  /// RIR description
  String get rirDescription {
    switch (rir) {
      case 0:
        return 'Failure';
      case 1:
        return '1 rep left';
      case 2:
        return '2 reps left';
      case 3:
        return '3 reps left';
      case 4:
        return '4 reps left';
      case 5:
        return '5+ reps left';
      default:
        return '$rir reps left';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SERIALIZATION (for future database integration)
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rir': rir,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'restTimeSeconds': restTimeSeconds,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      setNumber: map['setNumber']?.toInt() ?? 1,
      weight: map['weight']?.toDouble() ?? 0.0,
      reps: map['reps']?.toInt() ?? 0,
      rir: map['rir']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      isCompleted: (map['isCompleted'] ?? 0) == 1,
      notes: map['notes'],
      restTimeSeconds: map['restTimeSeconds']?.toInt(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EQUALITY & DEBUGGING
  // ─────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseSet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExerciseSet(id: $id, exercise: $exerciseId, set: $setNumber, '
        'weight: ${weight}kg, reps: $reps, rir: $rir, '
        'completed: $isCompleted)';
  }
}

// ─────────────────────────────────────────────────────────────
// EXTENSION METHODS FOR COLLECTIONS
// ─────────────────────────────────────────────────────────────

extension ExerciseSetList on List<ExerciseSet> {
  /// Get total volume for all sets
  double get totalVolume => fold(0.0, (sum, set) => sum + set.volume);

  /// Get completed sets only
  List<ExerciseSet> get completed => where((set) => set.isCompleted).toList();

  /// Get planned sets only
  List<ExerciseSet> get planned => where((set) => !set.isCompleted).toList();

  /// Sort by set number
  List<ExerciseSet> get sortedBySetNumber {
    final sorted = List<ExerciseSet>.from(this);
    sorted.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return sorted;
  }
}
