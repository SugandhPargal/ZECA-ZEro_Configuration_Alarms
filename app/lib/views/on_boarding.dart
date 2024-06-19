import 'package:safe_driving/services/database.dart';
import 'package:safe_driving/views/record.dart';
import 'package:safe_driving/widgets/widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

class Onboard extends StatefulWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  _OnboardState createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  //https://pub.dev/packages/uuid
  //generating unique ID for each session
  var uuid = const Uuid();

  //the following help take data from radio button as
  // well as in setting their state (both initial and upon change)
  String selectedACstatus = 'ON';
  String selectedcartype = 'Automated Gear Type';
  String selectedwindow = 'Open';
  late String _genUID;

  //we can take the text from the TextField using the following
  TextEditingController carModelTextEditingController1 =
      TextEditingController();

  //now we will create the key in the following lines to validate the form
  final formKey = GlobalKey<FormState>();

  //we are creating a function so when the user clicks on the signup button,
  // he/she knows that the button is doing something (it has been clicked)
  bool isLoading1 = false;

  //now we will create an instance of AuthMethods class which
  // we created in the auth.dart so we can use it on our signup page
  DatabaseMethods databaseMethods1 = DatabaseMethods();

  //the following function helps check if the entered fields are correct(valid) or not
  saveMyData() {
    if (formKey.currentState!.validate()) {
      //setting unique id using a random rng function
      _genUID = uuid.v4(options: {'rng': UuidUtil.cryptoRNG});

      //we are creating a map to facilitate the upload of data in the database upon submit
      //also it is implemented on top of setState function
      // because after isLoading is set to true the textbox becomes inactive
      Map<String, String> userMap1 = {
        "car_model": carModelTextEditingController1.text,
        "ac": selectedACstatus,
        "car_type": selectedcartype,
        "windows": selectedwindow,
        "uid": _genUID,
      };

      //the following sets the state to loading, that is to let the user
      // know something is happening by using the condition written in body of the scaffold
      setState(() {
        isLoading1 = true;
      });

      //below function is used to upload the user data in database using the above created map
      databaseMethods1.uploadUserInfo1(userMap1);

      //the below line is used to navigate the user to the home page,
      // we are using push replacement instead of push so that the user
      // upon clicking the back button doesn't come back to the sign up page.
      //also as new route we are using the materialpageroute
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => Record(nowUID: _genUID)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Driving App')),
      body: isLoading1
          //this is a simple true or false case programming,
          // if the isLoading1 state is true the circular progress indicator is shown
          ? Container(
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              //to avoid screen overflow
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    //We are wrapping all the text fields into a column and
                    // turning them into a text form field so that we can validate the user
                    Form(
                      //now we will be providing a key for this form and then
                      // we can validate all the text fields inside this form which was created above
                      key: formKey,
                      child: Column(
                        children: [
                          Container(
                            child: const Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                'Enter your car\'s model:',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                            ),
                          ),
                          TextFormField(
                              //the following line provides a validator function
                              // that checks for a valid entry into the text field.
                              validator: (val) {
                                if (val == null ||
                                    val.length < 4 ||
                                    val.isEmpty) {
                                  return "Please provide a valid model";
                                }
                                return null;
                              },
                              //the following line is used to extract text
                              controller: carModelTextEditingController1,
                              decoration: textFieldInputDecoration('Car Model'),
                              style: simpleTextStyle1()),
                          const SizedBox(
                            height: 15,
                          ),
                          //tutorial for radio buttons :
                          // https://flutter-examples.com/create-radio-button-in-flutter/
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status of Car\'s airconditioner (AC):',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'ON',
                                      groupValue: selectedACstatus,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedACstatus = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'AC is on',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'OFF',
                                      groupValue: selectedACstatus,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedACstatus = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'AC is off',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                ],
                              )),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'What is your car type:',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'Automated Gear Type',
                                      groupValue: selectedcartype,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedcartype = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'Automated Gear Type',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'Normal Gear Type',
                                      groupValue: selectedcartype,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedcartype = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'Normal Gear Type',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                ],
                              )),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Are the car windows open or close?',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'Open',
                                      groupValue: selectedwindow,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedwindow = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'Windows are open',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                  ListTile(
                                    leading: Radio(
                                      value: 'Closed',
                                      groupValue: selectedwindow,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedwindow = val as String;
                                        });
                                      },
                                    ),
                                    title: const Text(
                                      'Windows are closed',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                    //The following widget ,that is the gesture detector
                    // is wrapping the container widget to provide an on tapped function
                    GestureDetector(
                      //the gesture detector has an on tap property which takes a function
                      onTap: () {
                        saveMyData();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff007EF4),
                              Color(0xff2A75BC),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Submit',
                          style: mediumTextStyle1(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
