import 'package:shared_preferences/shared_preferences.dart';

//following helps in managing the onboarding screen status
class HelperFunctions {
  static String sharedPreferenceUserLoggedInKey = "ISLOGGEDIN";

  //first we will save data to shared preference

  static Future<bool> saveUserLoggedInSharedPreference(
      bool isUserLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(sharedPreferenceUserLoggedInKey, isUserLoggedIn);
  }

//getting data from shared preferences are facilitated using the following functions

  static Future<bool> getUserLoggedInSharedPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sharedPreferenceUserLoggedInKey) ?? false;
  }

  static removeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("ISLOGGEDIN");
  }
}
