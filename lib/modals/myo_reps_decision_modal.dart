import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/modals/rir_assessment_modal.dart';
import '../widgets/modals/myo_reps_decision_modal.dart';

class MyoRepsDecisionModal extends StatefulWidget {
  final int currentRir;
  final int targetReps;
  final int myoRestSeconds;
  final int maxMyoSets;
  final Function() onAccept;
  final Function() onDecline;

  const MyoRepsDecisionModal({
    super.key,
    required this.currentRir,
    required this.targetReps,
    this.myoRestSeconds = 15,
    this.maxMyoSets = 3,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<MyoRepsDecisionModal> createState() => _MyoRepsDecisionModalState();
}

class _MyoRepsDecisionModalState extends State<MyoRepsDecisionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPulsing = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Start pulsing animation for urgency
    _startPulsingAnimation();
  }

  void _startPulsingAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isPulsing) {
        _animationController.repeat(reverse: true);
      }
    });
  }

  void _stopPulsing() {
    setState(() => _isPulsing = false);
    _animationController.stop();
    _animationController.animateTo(1.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getMyoRepsExplanation() {
    if (widget.currentRir <= 0) {
      return "You hit failure! Perfect for myo-reps to squeeze out more volume.";
    } else if (widget.currentRir == 1) {
      return "Close to failure - ideal for myo-reps technique.";
    }
    return "Good intensity for myo-reps training.";
  }

  void _acceptMyoReps() {
    _stopPulsing();
    _animationController.reverse().then((_) {
      widget.onAccept();
      Navigator.of(context).pop(true);
    });
  }

  void _declineMyoReps() {
    _stopPulsing();
    _animationController.reverse().then((_) {
      widget.onDecline();
      Navigator.of(context).pop(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade50, Colors.red.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Fire Icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isPulsing
                          ? 0.8 + (_animationController.value * 0.4)
                          : 1.0,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade300,
                              blurRadius: _isPulsing
                                  ? 10 + (_animationController.value * 10)
                                  : 5,
                              spreadRadius: _isPulsing
                                  ? _animationController.value * 3
                                  : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.flame,
                          color: Colors.orange.shade600,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  "Continue with Myo-Reps?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Explanation
                Text(
                  _getMyoRepsExplanation(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Myo-Reps Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            color: Colors.orange.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Myo-Reps Protocol:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.timer,
                            "${widget.myoRestSeconds}s rest",
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.repeat,
                            "${widget.maxMyoSets} max sets",
                            Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.fitness_center,
                            "${widget.targetReps} target reps",
                            Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.trending_up,
                            "To failure",
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.x),
                        label: const Text("Just Rest"),
                        onPressed: _declineMyoReps,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.flame),
                        label: const Text("LET'S MYO!"),
                        onPressed: _acceptMyoReps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Quick tip
                Text(
                  "Tip: Stop if you can't hit target reps",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
