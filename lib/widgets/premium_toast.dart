import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class PremiumToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Define style based on state
    Color baseColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        baseColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        baseColor = Colors.redAccent.shade700;
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        baseColor = Colors.orange.shade600;
        iconData = Icons.warning_rounded;
        break;
      case ToastType.info:
        baseColor = Colors.blue.shade600;
        iconData = Icons.info_rounded;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => _PremiumToastWidget(
        title: title,
        message: message,
        baseColor: baseColor,
        iconData: iconData,
        duration: duration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _PremiumToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final Color baseColor;
  final IconData iconData;
  final Duration duration;
  final VoidCallback onDismiss;

  const _PremiumToastWidget({
    required this.title,
    required this.message,
    required this.baseColor,
    required this.iconData,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_PremiumToastWidget> createState() => _PremiumToastWidgetState();
}

class _PremiumToastWidgetState extends State<_PremiumToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(opacity: _fadeAnimation.value, child: child),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // Tap to dismiss early
              _controller.reverse().then((_) => widget.onDismiss());
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.baseColor.withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.baseColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.iconData,
                          color: widget.baseColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
