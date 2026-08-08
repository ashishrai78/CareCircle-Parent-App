
import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';



class UOutlinedButtonTheme {
  UOutlinedButtonTheme._();


  static final lightOutlinedButtonTheme  = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: UColors.dark,
      side: const BorderSide(color: UColors.borderPrimary),
      textStyle: const TextStyle(fontSize: 16, color: UColors.black, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(vertical: USizes.buttonHeight, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(USizes.buttonRadius)),
    ),
  );

}
