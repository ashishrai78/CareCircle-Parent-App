
import 'package:carecircle_parent1/features/authentication/screens/onBoarding/widgets/onBoarding_page.dart';
import 'package:carecircle_parent1/features/authentication/screens/onBoarding/widgets/smoothPage_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../common/icons/icon_widget.dart';
import '../../../../common/widgets/elevatedButton/elevated_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/images.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/texts.dart';
import '../../../../utils/helpers/device_helper.dart';
import '../../controllers/onBoarding/onBoarding_controllor.dart';
import '../login/login_screen.dart';
import '../signUp/signUp_Screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(USizes.defaultSpace),
        child: Column(
          children: [
            SizedBox(height: 25),
            Spacer(),
            Flexible(
              flex: 6,
              child: Stack(
                children: [
                  PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.upDateByPageScroll,
                    children: [
                      OnBoardingPage(
                        animation: UImages.onBodyAnimation1,
                        title: UTexts.onBoardingTitle1,
                        subTitle: UTexts.onBoardingSubTitle1,
                      ),
                      OnBoardingPage(
                        animation: UImages.onBodyAnimation2,
                        title: UTexts.onBoardingTitle2,
                        subTitle: UTexts.onBoardingSubTitle2,
                      ),
                      OnBoardingPage(
                        animation: UImages.onBodyAnimation3,
                        title: UTexts.onBoardingTitle3,
                        subTitle: UTexts.onBoardingSubTitle3,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Indicator
            SmoothPageIndicator1(),

            /// SizeBox
            Spacer(),

            /// For Google SignIn
            UIconWidget(),

            /// Text
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text('Or', style: Theme.of(context).textTheme.bodySmall,),
            ),

            //ElevatedButton
            UElevatedButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline_outlined, size: 20,),
                    SizedBox(width: 10,),
                    Text('Sign Up'),
                  ],
                ),
                onPressed: () {
                  Get.to(SignupScreen());
                },
              ),

            SizedBox(height: 10,),

            /// Have a Already an Account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have a CareCircle account?'),
                SizedBox(width: 4,),
                GestureDetector(
                  onTap: ()=> Get.to(LoginScreen()),
                    child: Text('Sign In', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: UColors.primary),)
                )
              ],
            ),

            SizedBox(height: 10,)

          ],
        ),
      ),
    );
  }
}


