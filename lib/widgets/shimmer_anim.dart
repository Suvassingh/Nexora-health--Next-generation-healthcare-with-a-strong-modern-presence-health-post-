import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';


class Shimmer extends StatefulWidget {
  const Shimmer();
  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _a = Tween<double>(begin: 0.35, end: 0.85).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _b(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(_a.value),
        borderRadius: BorderRadius.circular(r),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        Container(
          height: 100,
          color: AppConstants.primaryColor.withOpacity(0.1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _b(150, 20, r: 6),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _b(90, 28, r: 14),
                    const SizedBox(width: 8),
                    _b(100, 28, r: 14),
                  ],
                ),
                const SizedBox(height: 12),
                _b(120, 22, r: 11),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [_b(90, 14, r: 4), _b(90, 14, r: 4)],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _b(double.infinity, 90, r: 20),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        _b(40, 40, r: 12),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _b(60, 10, r: 4),
                            const SizedBox(height: 6),
                            _b(140, 14, r: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
