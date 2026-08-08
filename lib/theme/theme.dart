
import 'package:carecircle_parent1/theme/widgets_theme/appbar_theme.dart';
import 'package:carecircle_parent1/theme/widgets_theme/checkbox_theme.dart';
import 'package:carecircle_parent1/theme/widgets_theme/elevated_button.dart';
import 'package:carecircle_parent1/theme/widgets_theme/outlined_button.dart';
import 'package:carecircle_parent1/theme/widgets_theme/text_theme.dart';
import 'package:carecircle_parent1/theme/widgets_theme/textfield_theme.dart';
import 'package:flutter/material.dart';

import '../utils/constants/colors.dart';

class UAppTheme {
  // private constructor
  UAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.light,
    primaryColor: UColors.primary,
    disabledColor: UColors.grey,
    textTheme: UTextTheme.lightTextTheme,
    scaffoldBackgroundColor: UColors.white,
    appBarTheme: UAppBarTheme.lightAppBarTheme,
    checkboxTheme: UCheckboxTheme.lightCheckboxTheme,
    elevatedButtonTheme: UElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: UOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: UTextFormFieldTheme.lightInputDecorationTheme,
  );

}
