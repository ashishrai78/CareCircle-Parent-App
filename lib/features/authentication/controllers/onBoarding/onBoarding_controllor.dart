
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../screens/login/login_screen.dart';

class OnBoardingController extends GetxController{
static OnBoardingController get instance => Get.find();

  //variables
final storage = GetStorage();
final pageController = PageController();
RxInt currentIndex = 0.obs;

  // Update By PageScroll
void upDateByPageScroll(index){
  currentIndex.value = index;
}

  // Update By SmoothPageIndicator
void upDateBySmoothPageIndicator(index){
  currentIndex.value = index;
  pageController.jumpToPage(index);
}

  // Update By Button
  void upDateByButton(context){
  if(currentIndex.value == 2){
    storage.write('isFirstTime', false);
    Get.offAll(() => LoginScreen());
    return;
  }
  currentIndex.value++;
  pageController.jumpToPage(currentIndex.value);
 }

  // Update By SkipButton
void upDateBySkipButton(){
  currentIndex.value = 2;
  pageController.jumpToPage(currentIndex.value);
}

}