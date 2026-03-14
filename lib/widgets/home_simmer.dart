import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
class HomeShimmer extends StatefulWidget {
  const HomeShimmer();

  @override
  State<HomeShimmer> createState() => HomeShimmerState();
}

class HomeShimmerState extends State<HomeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double radius = 8}) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero shimmer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            color: AppConstants.primaryColor.withOpacity(0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(80, 12),
                        const SizedBox(height: 8),
                        _box(160, 24),
                      ],
                    ),
                    const Spacer(),
                    _box(52, 52, radius: 26),
                  ],
                ),
                const SizedBox(height: 14),
                _box(double.infinity, 44, radius: 12),
                const SizedBox(height: 10),
                _box(140, 12),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 72, radius: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: _box(double.infinity, 72, radius: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 72, radius: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: _box(double.infinity, 72, radius: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Appointment cards shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _box(double.infinity, 80, radius: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
