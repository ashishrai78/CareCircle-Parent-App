
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../utils/constants/sizes.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key, required this.animation, required this.title, required this.subTitle
  });
  final String animation;
  final String title;
  final String subTitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(animation, width: 250, height: 250),
        Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(subTitle, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}