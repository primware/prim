import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [_DashboardSkeletonCard(showTotal: true), SizedBox(height: 24), _DashboardSkeletonCard(showTotal: false)],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeletonCard extends StatelessWidget {
  final bool showTotal;
  const _DashboardSkeletonCard({required this.showTotal});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800.withOpacity(0.45) : Colors.grey.shade300.withOpacity(0.6);
    final highlightColor = isDark ? Colors.grey.shade700.withOpacity(0.35) : Colors.grey.shade100.withOpacity(0.8);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      width: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            if (showTotal) ...[
              const SizedBox(height: 12),
              Container(
                width: 160,
                height: 18,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      5,
                      (_) => Container(
                        width: 32,
                        height: 10,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _SkeletonBar(heightFactor: 0.45),
                              _SkeletonBar(heightFactor: 0.72),
                              _SkeletonBar(heightFactor: 0.58),
                              _SkeletonBar(heightFactor: 0.82),
                              _SkeletonBar(heightFactor: 0.36),
                              _SkeletonBar(heightFactor: 0.64),
                              _SkeletonBar(heightFactor: 0.50),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(
                            7,
                            (_) => Container(
                              width: 28,
                              height: 10,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double heightFactor;
  const _SkeletonBar({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: Container(
          width: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}
