import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';

class GuidedTour extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinish;
  final Function(int)? onStepChange;

  const GuidedTour({
    super.key,
    required this.steps,
    required this.onFinish,
    this.onStepChange,
  });

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.onStepChange != null && widget.steps.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStepChange!(_currentStep);
      });
    }
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      widget.onStepChange?.call(_currentStep);
    } else {
      widget.onFinish();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      widget.onStepChange?.call(_currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) return const SizedBox.shrink();
    final step = widget.steps[_currentStep];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Block taps
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Tour card anchored to bottom
                FadeInUp(
                  key: ValueKey(_currentStep),
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF635BFF).withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        if (step.icon != null)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF635BFF).withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(step.icon, size: 24, color: Colors.white),
                          ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1F36),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : const Color(0xFF697386),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Progress dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.steps.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentStep ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _currentStep
                                    ? const Color(0xFF635BFF)
                                    : (isDark
                                        ? Colors.white24
                                        : const Color(0xFF635BFF).withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Navigation row
                        Row(
                          children: [
                            // Back button
                            if (_currentStep > 0)
                              IconButton(
                                onPressed: _prev,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: isDark ? Colors.white54 : const Color(0xFF8898AA),
                                ),
                              )
                            else
                              const SizedBox(width: 40),
                            const Spacer(),
                            // Step counter
                            Text(
                              '${_currentStep + 1} / ${widget.steps.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : const Color(0xFF8898AA),
                              ),
                            ),
                            const Spacer(),
                            // Skip / Next
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: widget.onFinish,
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : const Color(0xFF8898AA),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _next,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF635BFF), Color(0xFF7C3AED)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF635BFF)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _currentStep == widget.steps.length - 1
                                          ? 'Finish'
                                          : 'Next',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TourStep {
  final String title;
  final String description;
  final IconData? icon;
  final int? targetIndex;

  TourStep({
    required this.title,
    required this.description,
    this.icon,
    this.targetIndex,
  });
}
