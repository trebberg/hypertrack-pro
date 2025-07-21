import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RirAssessmentModal extends StatefulWidget {
  final int initialRir;
  final Function(int rir) onRirSelected;

  const RirAssessmentModal({
    super.key,
    this.initialRir = 2,
    required this.onRirSelected,
  });

  @override
  State<RirAssessmentModal> createState() => _RirAssessmentModalState();
}

class _RirAssessmentModalState extends State<RirAssessmentModal>
    with SingleTickerProviderStateMixin {
  late int _selectedRir;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRir = widget.initialRir;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getRirColor(int rir) {
    if (rir <= -1) return Colors.red.shade600;
    if (rir == 0) return Colors.orange.shade600;
    if (rir == 1) return Colors.yellow.shade700;
    if (rir <= 3) return Colors.blue.shade600;
    return Colors.green.shade600;
  }

  String _getRirDescription(int rir) {
    switch (rir) {
      case -2:
        return "Failed rep (couldn't complete)";
      case -1:
        return "Failure (barely completed last rep)";
      case 0:
        return "Nothing left (complete failure)";
      case 1:
        return "Maybe 1 more rep";
      case 2:
        return "Could do 2 more reps";
      case 3:
        return "Could do 3 more reps";
      case 4:
        return "Could do 4 more reps";
      case 5:
        return "Could do 5+ more reps";
      default:
        return "Rate your effort";
    }
  }

  void _confirmRir() {
    _animationController.reverse().then((_) {
      widget.onRirSelected(_selectedRir);
      Navigator.of(context).pop(_selectedRir);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.gauge,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "How was that set?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Rate your effort (RIR)",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // RIR Scale
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(8, (index) {
                  final rir = index - 2; // -2 to +5
                  final isSelected = _selectedRir == rir;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRir = rir),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getRirColor(rir)
                            : Colors.transparent,
                        border: Border.all(
                          color: _getRirColor(rir),
                          width: isSelected ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          rir >= 0 ? '$rir' : '${rir}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : _getRirColor(rir),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getRirColor(_selectedRir).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRirColor(_selectedRir).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getRirDescription(_selectedRir),
                  style: TextStyle(
                    color: _getRirColor(_selectedRir),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmRir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getRirColor(_selectedRir),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Confirm RIR"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
