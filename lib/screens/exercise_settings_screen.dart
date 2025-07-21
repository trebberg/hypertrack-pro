import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/database.dart';

class ExerciseSettingsScreen extends StatefulWidget {
  final int exerciseId;
  final String? exerciseName;

  const ExerciseSettingsScreen({
    super.key,
    required this.exerciseId,
    this.exerciseName,
  });

  @override
  State<ExerciseSettingsScreen> createState() => _ExerciseSettingsScreenState();
}

class _ExerciseSettingsScreenState extends State<ExerciseSettingsScreen> {
  final AppDatabase _database = AppDatabase();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _equipmentNotesController =
      TextEditingController();

  // Form State Variables
  double _weightIncrement = 2.5;
  int _repsIncrement = 1;
  int _timeIncrement = 15;
  int _defaultRestSeconds = 180;
  bool _autoStartTimer = false;
  bool _vibrateEnabled = true;
  bool _soundEnabled = false;
  bool _isGenericExercise = false;
  String _defaultGraphType = 'estimated_1rm';
  String _recordCalculationMethod = '1rm_formula';

  bool _myoRepsEnabled = true;
  int _myoRestSeconds = 15;
  int _maxMyoSets = 3;
  int _myoTargetReps = 3;
  int _myoRirThreshold = 1;
  bool _myoRepsExpanded = false;

  // Available options
  final List<double> _weightIncrementOptions = [0.5, 1.0, 1.25, 2.5, 5.0, 10.0];
  final List<int> _repsIncrementOptions = [1, 2, 5];
  final List<int> _timeIncrementOptions = [5, 10, 15, 30];
  final List<int> _restTimeOptions = [60, 90, 120, 180, 240, 300];
  final List<String> _graphTypeOptions = [
    'estimated_1rm',
    'max_weight',
    'max_reps',
    'max_volume',
  ];
  final List<String> _recordFormulaOptions = [
    '1rm_formula',
    'max_reps',
    'max_volume',
    'time_based',
  ];

  // Section expansion state
  bool _basicInfoExpanded = true;
  bool _incrementsExpanded = false;
  bool _timersExpanded = false;
  bool _classificationExpanded = false;
  bool _gymAvailabilityExpanded = false;
  bool _trackingExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadExerciseSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _equipmentNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseSettings() async {
    try {
      // TODO: Load actual exercise data from database
      // For now, set defaults based on exerciseId
      _nameController.text =
          widget.exerciseName ?? 'Exercise ${widget.exerciseId}';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Save to database
      // For now, just simulate save delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate changes saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isExpanded,
    required VoidCallback onToggle,
    String? previewText,
    bool hasChanges = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(4))
                    : BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isExpanded
                        ? Colors.blue.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
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
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (!isExpanded && previewText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            previewText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasChanges)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Exercise Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Exercise name is required';
            }
            return null;
          },
          onChanged: (_) => _markAsChanged(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Instructions (Optional)',
            hintText: 'Enter exercise setup or form cues...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _markAsChanged(),
        ),
      ],
    );
  }

  Widget _buildIncrementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField<double>(
          label: 'Weight Increment (kg)',
          value: _weightIncrement,
          options: _weightIncrementOptions,
          onChanged: (value) {
            setState(() {
              _weightIncrement = value;
            });
            _markAsChanged();
          },
          displayText: (value) => '${value}kg',
        ),
        const SizedBox(height: 16),
        _buildDropdownField<int>(
          label: 'Reps Increment',
          value: _repsIncrement,
          options: _repsIncrementOptions,
          onChanged: (value) {
            setState(() {
              _repsIncrement = value;
            });
            _markAsChanged();
          },
          displayText: (value) => '$value rep${value == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 16),
        _buildDropdownField<int>(
          label: 'Time Increment (seconds)',
          value: _timeIncrement,
          options: _timeIncrementOptions,
          onChanged: (value) {
            setState(() {
              _timeIncrement = value;
            });
            _markAsChanged();
          },
          displayText: (value) => '${value}s',
        ),
      ],
    );
  }

  Widget _buildTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField<int>(
          label: 'Default Rest Time',
          value: _defaultRestSeconds,
          options: _restTimeOptions,
          onChanged: (value) {
            setState(() {
              _defaultRestSeconds = value;
            });
            _markAsChanged();
          },
          displayText: (value) {
            final minutes = value ~/ 60;
            final seconds = value % 60;
            if (minutes > 0 && seconds > 0) {
              return '${minutes}m ${seconds}s';
            } else if (minutes > 0) {
              return '${minutes}m';
            } else {
              return '${seconds}s';
            }
          },
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          title: 'Auto Start Timer',
          subtitle: 'Automatically start rest timer after saving set',
          value: _autoStartTimer,
          onChanged: (value) {
            setState(() {
              _autoStartTimer = value;
            });
            _markAsChanged();
          },
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: 'Vibrate on Complete',
          subtitle: 'Vibrate device when timer completes',
          value: _vibrateEnabled,
          onChanged: (value) {
            setState(() {
              _vibrateEnabled = value;
            });
            _markAsChanged();
          },
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: 'Sound on Complete',
          subtitle: 'Play sound when timer completes',
          value: _soundEnabled,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
            });
            _markAsChanged();
          },
        ),
      ],
    );
  }

  Widget _buildTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField<String>(
          label: 'Default Graph Type',
          value: _defaultGraphType,
          options: _graphTypeOptions,
          onChanged: (value) {
            setState(() {
              _defaultGraphType = value;
            });
            _markAsChanged();
          },
          displayText: (value) => _formatGraphType(value),
        ),
        const SizedBox(height: 16),
        _buildDropdownField<String>(
          label: 'Record Calculation',
          value: _recordCalculationMethod,
          options: _recordFormulaOptions,
          onChanged: (value) {
            setState(() {
              _recordCalculationMethod = value;
            });
            _markAsChanged();
          },
          displayText: (value) => _formatRecordFormula(value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Additional notes about this exercise...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _markAsChanged(),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> options,
    required ValueChanged<T> onChanged,
    required String Function(T) displayText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((T option) {
        return DropdownMenuItem<T>(
          value: option,
          child: Text(displayText(option)),
        );
      }).toList(),
      onChanged: (T? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatGraphType(String type) {
    switch (type) {
      case 'estimated_1rm':
        return 'Estimated 1RM';
      case 'max_weight':
        return 'Max Weight';
      case 'max_reps':
        return 'Max Reps';
      case 'max_volume':
        return 'Max Volume';
      default:
        return type;
    }
  }

  String _formatRecordFormula(String formula) {
    switch (formula) {
      case '1rm_formula':
        return '1RM Formula';
      case 'max_reps':
        return 'Max Reps';
      case 'max_volume':
        return 'Max Volume';
      case 'time_based':
        return 'Time Based';
      default:
        return formula;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.settings, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Exercise Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_hasChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Modified',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        const SizedBox(height: 8),

                        // Basic Info Section
                        _buildCollapsibleSection(
                          title: 'Basic Information',
                          icon: LucideIcons.fileText,
                          isExpanded: _basicInfoExpanded,
                          onToggle: () => setState(() {
                            _basicInfoExpanded = !_basicInfoExpanded;
                          }),
                          child: _buildBasicInfoSection(),
                        ),

                        // Increments Section
                        _buildCollapsibleSection(
                          title: 'Increments',
                          icon: LucideIcons.plus,
                          isExpanded: _incrementsExpanded,
                          onToggle: () => setState(() {
                            _incrementsExpanded = !_incrementsExpanded;
                          }),
                          previewText:
                              'Weight: ${_weightIncrement}kg, Reps: $_repsIncrement',
                          child: _buildIncrementsSection(),
                        ),

                        // Timer Section
                        _buildCollapsibleSection(
                          title: 'Timer Settings',
                          icon: LucideIcons.timer,
                          isExpanded: _timersExpanded,
                          onToggle: () => setState(() {
                            _timersExpanded = !_timersExpanded;
                          }),
                          previewText:
                              '${_defaultRestSeconds}s${_autoStartTimer ? ', Auto-start' : ''}',
                          child: _buildTimerSection(),
                        ),

                        // Tracking Section
                        _buildCollapsibleSection(
                          title: 'Tracking & Records',
                          icon: LucideIcons.barChart3,
                          isExpanded: _trackingExpanded,
                          onToggle: () => setState(() {
                            _trackingExpanded = !_trackingExpanded;
                          }),
                          previewText: _formatGraphType(_defaultGraphType),
                          child: _buildTrackingSection(),
                        ),

                        const SizedBox(height: 80), // Space for fixed footer
                      ],
                    ),
                  ),
          ),

          // Fixed Footer with Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
