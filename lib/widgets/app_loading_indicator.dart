import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const AppLoadingIndicator({
    super.key,
    this.size = 40,
    this.color = const Color(0xFFF05D15),
  });

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.threeArchedCircle(
      color: color,
      size: size,
    );
  }
}
