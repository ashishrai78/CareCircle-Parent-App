
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../utils/constants/keys.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptons.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../authentication/authentication_repository.dart';

class UserRepository extends GetxController{
  static UserRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;

  // Function for store User details
  Future<void> saveUserRecord(AppUserModel user) async{
    try{
      await _db.collection(UKeys.userCollection).doc(user.uid).set(user.toJson());


    } on FirebaseAuthException catch(e){
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch(e){
      throw UFirebaseException(e.code).message;
    } on FormatException {
      throw UFormatException().message;
    } on PlatformException catch(e){
      throw UPlatformException(e.code).message;
    }catch(e){
      throw 'Something went wrong, try again later';
    }
  }


  // Function for fetch User details
  Future<AppUserModel> fetchUserDetails() async{
    try{
      final documentSnapshot = await _db.collection(UKeys.userCollection).doc(AuthenticationRepository.instance.currentUser?.uid).get();
      if(documentSnapshot.exists){
        AppUserModel user = AppUserModel.fromSnapshot(documentSnapshot);
        return user;
      }
      return AppUserModel.empty();

    } on FirebaseAuthException catch(e){
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch(e){
      throw UFirebaseException(e.code).message;
    } on FormatException catch(e){
      throw UFormatException().message;
    } on PlatformException catch(e){
      throw UPlatformException(e.code).message;
    }catch(e){
      throw 'Something went wrong, try again later';
    }
  }

  // Function for SingleField User details
  Future<void> updateSingleField(Map<String, dynamic> map) async{
    try{
      await _db.collection(UKeys.userCollection).doc(AuthenticationRepository.instance.currentUser!.uid).update(map);

    } on FirebaseAuthException catch(e){
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch(e){
      throw UFirebaseException(e.code).message;
    } on FormatException catch(e){
      throw UFormatException().message;
    } on PlatformException catch(e){
      throw UPlatformException(e.code).message;
    }catch(e){
      throw 'Something went wrong, try again later';
    }
  }



  // Function to FindChildByCode
  Future<DocumentSnapshot?> findChildByCode(String code) async {
    final result = await _db.collection('Users').where('childCode', isEqualTo: code).limit(1).get();
    if (result.docs.isEmpty) return null;
    return result.docs.first;
  }



}