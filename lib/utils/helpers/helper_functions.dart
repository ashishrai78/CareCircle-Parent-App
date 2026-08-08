import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class UHelperFunctions{
  UHelperFunctions._();

  // Get greetingMassage
  static String getGreetingMassage(){
    final hour = DateTime.now().hour;

    if(hour >= 5 && hour < 12){
      return 'Good Morning';
    }else if(hour >= 12 && hour < 16){
      return 'Good Afternoon';
    }else if(hour >= 16 && hour < 19){
      return 'Good Evening';
    }else{
      return 'Good Night';
    }
  }


  /// Function to convert asset to file
  static Future<File> assetToFile(String assetPath) async {
    // Load asset bytes
    final byteData = await rootBundle.load(assetPath);

    // Get temp directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split('/').last}');

    // Write bytes to temp file
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  static String getFormattedDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

}