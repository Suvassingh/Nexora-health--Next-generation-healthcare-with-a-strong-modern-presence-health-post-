import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';

class ImageButton extends StatelessWidget {
  final String text;
  final String imagePath;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ImageButton({
    super.key,
    required this.text,
    required this.imagePath,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.whiteColor,
          disabledBackgroundColor: AppConstants.whiteColor.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(imagePath, height: 22, width: 22),
                    const SizedBox(width: 10),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
