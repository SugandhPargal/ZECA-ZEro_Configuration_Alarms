import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:proximity_sensor/proximity_sensor.dart';
import "package:sensors_plus/sensors_plus.dart";
import 'package:csv/csv.dart';
import 'package:location/location.dart';
import 'package:is_lock_screen/is_lock_screen.dart';
import 'package:http/http.dart' as http;

import 'package:motion_sensors/motion_sensors.dart'
    as orienting; //because it has same methods like sensor_plus package

class Record extends StatefulWidget {
  final String nowUID;
  const Record({Key? key, required this.nowUID}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  /* The following declares variables whole values will be initialised later (hence late modifier used)
   https://www.fluttercampus.com/guide/241/lateinitializatioerror-field-has-not-been-initialized-error/
   - late keyword and initialisation error */

  //bool flagforstream = false;

  //the following sets variables for audio recording
  final _myRecorder = FlutterSoundRecorder();
  late String filePath;
  String MAIN_URL = "http://192.168.21.159:8000";
  int MAIN_Timer = 30;
  //to check if recording is on or off
  bool _isRecoding = false;

  //timestampname helps in setting the audio and csv file name while saving
  late String timestampname;
  //the following data structure rows help save the sensor data
  // in record() function in 2D list that can be converted to csv later
  late List<List<dynamic>> rows;
  List temp_rows = [];
  //the following helps in recording the sensor data periodically
  late Timer _timer;

  //following 7 lines deal with variables storing the sensor data from sensors as 1D list
  //https://www.woolha.com/tutorials/dart-inserting-elements-into-list-examples - tutorial on list
  //https://pub.dev/packages/sensors_plus/example - using sensor plus package
  late List<double> _accelerometerValues;
  late List<double> _gyroscopeValues;
  late List<double> _magnetometerValues;
  late List<double> _gpsValues;
  late List<double> _proximityValue;
  late List<double> _absoluteOrientationValue;

  Location location = Location();
  late LocationData _locationData;

  // Initial Selected Value of Drop Down Button
  String _value = 'DS';
  //The ID used to save filename of audio and sensor file
  /*This helps in case one changes the dropdown option during ongoing recording
     Although the dropdown list is deactivated when recording is on
     So, this is second security check*/
  String seatID = 'DS';
  late String sessionID;

  //the following overall list saves all three sensor data in one 1D list
  late List<String> _rowHeader = [];
  late List<double> _overAll = [];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  //final _recSubs = <StreamSubscription<dynamic>>[];

  //stopwatch timer
  int seconds = 0, minutes = 0, hours = 0;
  String digitSeconds = "00", digitMinutes = "00", digitHours = "00";
  Timer? timer;
  bool started = false;

  getMainUrl() async {
    http.Response response = await http.get(Uri.parse("https://api.npoint.io/6181af778d9501128810"));
    var data = json.decode(response.body);
    String url = data["url"];
    int t = data["time"];
    MAIN_URL = url ;
    MAIN_Timer = t ;
    print("MAIN_URL = "+MAIN_URL);
    print("MAIN_Timer = "+MAIN_Timer.toString());

  }
  
  void timerStop() {
    timer!.cancel();
    setState(() {
      started = false;
    });
  }

  void timerReset() {
    timer!.cancel();
    setState(() {
      seconds = 0;
      minutes = 0;
      hours = 0;
      digitSeconds = "00";
      digitMinutes = "00";
      digitHours = "00";
      started = false;
    });
  }

  void timerStart() {
    started = true;
    setState(() {
      seconds = 0;
      minutes = 0;
      hours = 0;
      digitSeconds = "00";
      digitMinutes = "00";
      digitHours = "00";
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int localSeconds = seconds + 1;
      int localMinutes = minutes;
      int localHours = hours;

      if (localSeconds > 59) {
        if (localMinutes > 59) {
          localHours++;
          localMinutes = 0;
        } else {
          localMinutes++;
          localSeconds = 0;
        }
      }
      setState(() {
        seconds = localSeconds;
        minutes = localMinutes;
        hours = localHours;
        digitSeconds = (seconds >= 10) ? "$seconds" : "0$seconds";
        digitMinutes = (minutes >= 10) ? "$minutes" : "0$minutes";
        digitHours = (hours >= 10) ? "$hours" : "0$hours";
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    startIt();
    // getMainUrl() ;
    _streamSubscriptions.add(
      orienting.motionSensors.absoluteOrientation.listen(
        (orienting.AbsoluteOrientationEvent event) {
          setState(() {
            _absoluteOrientationValue = <double>[
              event.yaw,
              event.pitch,
              event.roll
            ];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      ProximitySensor.events.listen(
        (event) {
          setState(() {
            _proximityValue = <double>[event.toDouble()];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );

    super.initState();
  }

  //the following function sets things for audio recording
  void startIt() async {
    filePath = '/sdcard/Download/audio/temp.wav';
    await _myRecorder.openAudioSession(
        focus: AudioFocus.requestFocusAndStopOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: AudioDevice.speaker);
    await _myRecorder.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();

    //the following is used after loading permission handler in pubspec.yaml
    //https://youtu.be/AoMVol8ZpaA - basic knowledge
    //https://developer.android.com/reference/android/Manifest.permission - for AndroidManifest.xml
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    await Permission.locationWhenInUse.request();
  }
  final player = AudioPlayer();                   // Create a player

  Future<void> sendAlert_short(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: const Text("Don't use your phone"),
          actions: <Widget>[
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> sendAlert_long(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: const Text("Please stop using your phone while driving, it may cause accident"),
          actions: <Widget>[
            TextButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> sendAlert_audio(BuildContext context) async {
    final duration = await player.setAsset(        // Load a URL
        'assets/alert_aud.mp3');
    // await player.play() ;
    player.play();
    // return showDialog<void>(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text('alert'),
    //       content: const Text('audio alert'),
    //       actions: <Widget>[
    //         TextButton(
    //           child: Text('Okay'),
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  bool isChecked_short = true;
  bool isChecked_long = false;
  bool isChecked_audio = false;
  @override
  Widget build(BuildContext context) {
    //the following deals with UI
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 400.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff6CA7FF),
                  Color(0xff9920AD),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom:
                    Radius.elliptical(MediaQuery.of(context).size.width, 100.0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  offset: Offset(
                    10.0,
                    10.0,
                  ),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                "$digitHours:$digitMinutes:$digitSeconds",
                style: const TextStyle(fontSize: 70),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildElevatedButton(
                icon: Icons.play_arrow_rounded,
                iconColor: Colors.red,
                f: (){
                  record(context);
                },
              ),
              const SizedBox(
                width: 40,
              ),
              buildElevatedButton(
                icon: Icons.stop,
                iconColor: Colors.black,
                f: stopRecord,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: started ? null : timerReset,
            child: Container(
              alignment: Alignment.center,
              width: 150, //MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 5),
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    offset: Offset(
                      3.0,
                      3.0,
                    ),
                    blurRadius: 10.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: const Text('Reset Timer',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          //https://codesinsider.com/flutter-dropdown-button-example/ - tutorial on dropdown button
          Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0), //.all(20.0),
              //color: Colors.blueAccent,
              child: DropdownButton(
                value: _value, //initial value
                icon: const Icon(Icons.arrow_drop_down_circle),
                iconEnabledColor: Colors.green,
                iconDisabledColor: Colors.red,
                items: const [
                  DropdownMenuItem(
                    child: Text("Driver Seat"),
                    value: 'DS',
                  ),
                  DropdownMenuItem(
                    child: Text("Passenger Front"),
                    value: 'PF',
                  ),
                  DropdownMenuItem(
                    child: Text("DashBoard"),
                    value: 'DB',
                  ),
                  DropdownMenuItem(
                    child: Text("Back Left"),
                    value: 'BL',
                  ),
                  DropdownMenuItem(
                    child: Text("Back Right"),
                    value: 'BR',
                  )
                ],
                onChanged: _isRecoding
                    ? null //disabling when recording is on
                    : (String? value) {
                        setState(() {
                          _value = value!;
                        });
                      },
                elevation: 15,
                style: const TextStyle(color: Colors.black87, fontSize: 20),
                dropdownColor: Colors.lightBlueAccent,
                isExpanded: false,
              )),

          Center(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 30,),
            const Text("Short alert"),
            Checkbox(
              checkColor: Colors.white,
              value: isChecked_short,
              onChanged: (bool? value) {
                setState(() {
                  isChecked_short = value!;
                  isChecked_long = false;
                  isChecked_audio = false;
                });
              },
            ),

              const Text("Long alert"),
              Checkbox(
                checkColor: Colors.white,
                value: isChecked_long,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked_short = false;
                    isChecked_long = value!;
                    isChecked_audio = false;
                  });
                },
              ),

              const Text("Audio alert"),
              Checkbox(
                checkColor: Colors.white,
                value: isChecked_audio,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked_short = false;
                    isChecked_long = false;
                    isChecked_audio = value!;
                  });
                },
              ),
      ],
    ),
    )
        ],
      )),
    );
  }

  //the following is a widget to create custom elevated buttons
  ElevatedButton buildElevatedButton(
      {required IconData icon,
      required Color iconColor,
      required Function() f}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(7.0),
        side: const BorderSide(
          color: Colors.green,
          width: 5.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        primary: Colors.white,
        elevation: 10.0,
      ),
      onPressed: f,
      //https://api.flutter.dev/flutter/material/Icons-class.html icons library for flutter
      icon: Icon(
        icon,
        color: iconColor,
        size: 40.0,
      ),
      label: const Text(''),
    );
  }

  Future send_for_prediction(List data, BuildContext context) async{
    String url=MAIN_URL+"/predict";
    http.Response response = await http.post(Uri.parse(url),body: jsonEncode(data));
    String res = response.body.toString();
    print("RESPONSE from predict = "+res);
    if (res=="1"){
      // return 1;
      if(isChecked_long){
        sendAlert_long(context);
      }else if(isChecked_audio){
        sendAlert_audio(context);
      }else{
        sendAlert_short(context);
      }

    }
    else{
      return 0;
    }
  }


  //the following function is called when mic button is pressed
  Future<void> record(BuildContext context_alert) async {
    //starting the clock
    timerStart();

    //setting the ID for the in-car-location recording starts
    seatID = _value;
    //setting the ID for the session
    sessionID = widget.nowUID;

    //the following deals with recording audio and storing
    String newfilepath = '/sdcard/Download/audio/';
    timestampname = DateTime.now().millisecondsSinceEpoch.toString();

    //creating directory for audio data
    Directory dir = Directory(path.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync();
    }

    //creating directory for sensor data
    Directory dirSensor =
        Directory(path.dirname('/sdcard/Download/sensor/temp.csv'));
    if (!dirSensor.existsSync()) {
      dirSensor.createSync();
    }

    //starting the recording
    _isRecoding = true;
    String currPath =
        newfilepath + sessionID + "_" + seatID + "_" + timestampname + ".wav";
    _myRecorder.openAudioSession();
    await _myRecorder.startRecorder(
      toFile: currPath,
      codec: Codec.pcm16WAV,
    );

    rows = [];
    temp_rows = [] ;
    List<String> _dataHead = [sessionID, seatID, timestampname];
    //adding header to csv, multiple sub headers are added to ease adding cases when a sensor isn't available
    _rowHeader = [];

    //header for accelerometer
    List<String> _accelerometerHeader = [
      "Accelerometer x",
      "Accelerometer y",
      "Accelerometer z"
    ];
    _rowHeader.addAll(_accelerometerHeader);

    //header for gyroscope
    List<String> _gyroscopeHeader = [
      "Gyroscope x",
      "Gyroscope y",
      "Gyroscope z"
    ];
    _rowHeader.addAll(_gyroscopeHeader);

    //header for magnetometer
    List<String> _magnetometerHeader = [
      "Magnetometer x",
      "Magnetometer y",
      "Magnetometer z"
    ];
    _rowHeader.addAll(_magnetometerHeader);

    //header for gps
    List<String> _gpsHeader = ["GPS-Longitude", "GPS-Latitude", "GPS-Speed"];
    _rowHeader.addAll(_gpsHeader);

    //header for proximity sensor
    List<String> _proximityHeader = ["Proximity_ON/OFF"]; //1 is near 0 is far
    _rowHeader.addAll(_proximityHeader);

    //header for absolute Orientation sensor
    List<String> _absoluteOrientationHeader = [
      "Orientation yaw",
      "Orientation pitch",
      "Orientation roll"
    ];
    _rowHeader.addAll(_absoluteOrientationHeader);
    _rowHeader.add("Screen");
    rows.add(_dataHead);
    rows.add(_rowHeader); //adding all sub headers to header

    //saving the sensor data from overall in a new row in rows
    //https://mightytechno.com/how-to-use-timer-and-periodic-in-flutter/ - tutorial on timer and timer.periodic
    int locationErrorFlag = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {

      // if screen is on it'll return false (we checking if screen is locked or not)
      // if screen is of it'll return true
      bool? isScreenOn = await isLockScreen();
      print("isLockScreen = "+isScreenOn.toString());

      double isScreenOnBinary = 1;
      if(isScreenOn!=null && isScreenOn){
        isScreenOnBinary = 0.0;
      }
      else{
        isScreenOnBinary = 1.0 ;
      }

      _overAll = []; //clearing the 1D list before recording new data
      print("1");
      //getting and adding the gps values to a 1D list since it isn't in a stream
      _gpsValues = [];
      _locationData = await location.getLocation();
      print("2");
      try{
        _gpsValues.add(_locationData.longitude!.toDouble());
        _gpsValues.add(_locationData.latitude!.toDouble());
        _gpsValues.add(_locationData.speed!.toDouble());
      }catch(e){
        _gpsValues.add(-0.0);
        _gpsValues.add(-0.0);
        _gpsValues.add(-0.0);
      }


      // _gpsValues.add(-0.0);
      // _gpsValues.add(-0.0);
      // _gpsValues.add(-0.0);

      print("3");
      //adding the sensor data in one row of _overAll(1D list)
      _overAll.addAll(_accelerometerValues);
      _overAll.addAll(_gyroscopeValues);

      try{
        _overAll.addAll(_magnetometerValues);
      }catch(e){
        _overAll.addAll([-0.0,-0.0,-0.0]);
      }

      // _overAll.addAll(_magnetometerValues);
      _overAll.addAll(_gpsValues);
      _overAll.addAll(_proximityValue);
      try{
        _overAll.addAll(_absoluteOrientationValue);
      }catch(e){
        _overAll.addAll([-0.0,-0.0,-0.0]);
      }
      // _overAll.addAll(_absoluteOrientationValue);
      _overAll.addAll([isScreenOnBinary]);
      print("4");
      //the following adds sensor data in _overAll(1D List) to rows(2D List) every 1 second

      final overAll = _overAll.map((double v) => v.toStringAsFixed(4)).toList();
      rows.add(overAll);
      temp_rows.add(overAll);
      print("temp_rows len = "+temp_rows.length.toString());
      if (temp_rows.length>=MAIN_Timer){
        print("SENDING data");
        send_for_prediction(temp_rows,context_alert);
        temp_rows = [];
      }

      print("overAll = "+overAll.toString());
      locationErrorFlag = 0;
    });
  }

  //the following function is called when stop button is pressed
  Future<String?> stopRecord() async {
    //stopping the clock
    timerStop();

    //closing the audio recording session
    _myRecorder.closeAudioSession();
    _isRecoding = false;

    //https://iamkaival.medium.com/read-write-csv-in-flutter-web-9f8ec960914c - tutorial on csv creation and use
    //https://medium.flutterdevs.com/exploring-csv-in-flutter-fafc57b02eb1 - tutorial on csv creation and use
    //converting the data stored in rows to a csv
    String csvData = const ListToCsvConverter().convert(rows);
    final senPath = '/sdcard/Download/sensor/' +
        sessionID +
        "_" +
        seatID +
        "_" +
        timestampname +
        ".csv";
    final File file = File(senPath);
    file.writeAsString(csvData);

    //ending the execution of data writing in rows 2D list
    _timer.cancel();
    // locationErrorFlag =0;
    return await _myRecorder.stopRecorder();
  }
}
