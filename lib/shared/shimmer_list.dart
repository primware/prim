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
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
