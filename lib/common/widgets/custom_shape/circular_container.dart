import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';


/// ⭕ UCircularContainer — circular shaped container
///
/// For battery %, status indicators, etc.
class UCircularContainer extends StatelessWidget {
  const UCircularContainer({
    super.key,
    this.child,
    this.width = 80,
    this.height = 80,
    this.color = UColors.white,
    this.borderColor = UColors.borderPrimary,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
  });

  final Widget? child;
  final double width;
  final double height;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
  }
}
