import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // quick revision : https://www.youtube.com/watch?v=1xPMbwOFa9I
  //creating a collection reference cardetails for every function in this class
  //since only one collection would be needed for this app
  CollectionReference cardetails =
      FirebaseFirestore.instance.collection('cardetails');

  //method 1 that uploads info to cloud firestore
  //this takes a map of fields to be uploaded
  //this one is used in app
  Future<void> uploadUserInfo1(userData) async {
    cardetails.add(userData);
    return;
  }

  //method 2 that uploads info to cloud firestore
  //this takes manually all of the fields to be uploaded as parameters
  //was created for testing purpose
  Future<void> uploadToFB(
      String carmodel, String AC, String cartype, String window) async {
    cardetails.add({
      'car_model': carmodel,
      'ac': AC,
      'car_type': cartype,
      'window': window
    });
    return;
  }
}
