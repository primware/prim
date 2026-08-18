import 'package:flutter/material.dart';

class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value
              ? primary.withOpacity(0.3)
              : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          border: Border.all(
            color: value
                ? primary.withOpacity(0.6)
                : (isDark ? Colors.white30 : Colors.black12),
            width: 1.5,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: primary.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: -2,
              )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: value ? 26 : 2,
              right: value ? 2 : 26,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? primary : (isDark ? Colors.white70 : Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: value
                        ? Icon(
                            Icons.check,
                            key: const ValueKey('icon_check'),
                            size: 14,
                            color: isDark ? Colors.black87 : Colors.white,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
