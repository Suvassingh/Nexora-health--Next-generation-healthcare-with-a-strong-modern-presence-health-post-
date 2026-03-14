
import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
class Circle extends StatelessWidget {
  final double size;
  final Color color;
  const Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class AvatarFill extends StatelessWidget {
  final String initials;
  const AvatarFill({required this.initials});
  @override
  Widget build(BuildContext context) => Container(
    color: AppConstants.primaryColor,
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}
