import 'package:flutter/material.dart';

/// An animated progress bar that fills from left to right on load.
/// 
/// Creates a smooth "load" animation effect when the screen is displayed.
/// Uses [RepaintBoundary] for performance isolation.
class AnimatedBudgetProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0+
  final Color color;
  final Color? overBudgetColor;
  final double height;
  final BorderRadius borderRadius;
  final Duration animationDuration;

  const AnimatedBudgetProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.overBudgetColor,
    this.height = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedBudgetProgressBar> createState() => _AnimatedBudgetProgressBarState();
}

class _AnimatedBudgetProgressBarState extends State<AnimatedBudgetProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _initializeAnimation();
    
    // Start the fill animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  void _initializeAnimation() {
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedBudgetProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _initializeAnimation();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle Hot Reload case where _animation might be null
    if (_animation == null) {
      _initializeAnimation();
    }
    
    final isOverBudget = widget.progress > 1.0;
    final baseColor = isOverBudget ? (widget.overBudgetColor ?? Colors.red) : widget.color;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: widget.borderRadius,
          ),
          child: AnimatedBuilder(
            animation: _animation!,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _animation!.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        baseColor,
                        baseColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
