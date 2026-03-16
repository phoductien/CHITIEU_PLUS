import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final double s = size / 90.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF05D15),
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48 * s,
              height: 36 * s,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10 * s),
              ),
            ),
            Positioned(
              right: -1 * s,
              child: Container(
                width: 14 * s,
                height: 20 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFFF05D15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6 * s),
                    bottomLeft: Radius.circular(6 * s),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 5 * s,
                    height: 5 * s,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: ((36 * s) / 2) - (20 * s / 2) - 6 * s + (36 * s / 2), // Adjust relative positioning scaling logic securely
              child: const SizedBox.shrink(),
            ),
            // The position of the notch line inside the wallet
            Positioned(
              top: (size - 36*s)/2 + 6*s,
              left: (size - 48*s)/2 + 6*s,
              right: (size - 48*s)/2 + 14*s,
              child: Container(
                height: 3 * s,
                decoration: BoxDecoration(
                  color: const Color(0xFFF05D15).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2 * s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
