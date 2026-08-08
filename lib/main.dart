
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'firebase_options.dart';
import 'my_app.dart'; // We need to generate this, but for now it might fail if file missing. We will stub it or comment.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Flutter Native SplashScreen
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // GetStorage initialize
  GetStorage.init();


  // Firebase initialize
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,).then((value) {
    Get.put(AuthenticationRepository());
  },);



  runApp(MyApp());
}
