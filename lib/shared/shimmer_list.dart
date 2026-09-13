import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerList extends StatelessWidget {
  final int? count;
  final double? height, separation;

  const ShimmerList({
    super.key,
    this.count,
    this.height,
    this.separation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade800 : Colors.grey[300]!;
    final Color highlightColor = isDark ? Colors.grey.shade700 : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(count ?? 5, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: separation ?? 8),
            child: Container(
              width: double.infinity,
              height: height ?? 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }
}
