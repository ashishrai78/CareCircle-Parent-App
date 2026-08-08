
import 'package:flutter/material.dart';
import '../../../../../utils/helpers/device_helper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../controllers/onBoarding/onBoarding_controllor.dart';

class SmoothPageIndicator1 extends StatelessWidget {
  const SmoothPageIndicator1({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;
    return SmoothPageIndicator(
      controller: controller.pageController,
      onDotClicked: controller.upDateBySmoothPageIndicator,
      count: 3,
      effect: WormEffect(dotHeight: 5, dotWidth: 5)
    );
  }
}