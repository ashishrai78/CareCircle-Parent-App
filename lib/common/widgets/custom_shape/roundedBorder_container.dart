import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// 🔲 URoundedContainer — reusable rounded container
///
/// Production-ready wrapper with consistent styling.
class URoundedContainer extends StatelessWidget {
  const URoundedContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.color = UColors.white,
    this.borderColor = UColors.borderPrimary,
    this.border = false,
    this.borderRadius,
    this.showShadow = false,
    this.onTap,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color borderColor;
  final bool border;
  final double? borderRadius;
  final bool showShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          borderRadius ?? USizes.cardRadiusLg,
        ),
        border: border
            ? Border.all(color: borderColor, width: 1.0)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: UColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: onTap != null
          ? Material(
              color: UColors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(
                  borderRadius ?? USizes.cardRadiusLg,
                ),
                child: child,
              ),
            )
          : child,
    );
  }
}
