import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_event/keyboard_event.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(490, 325),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.setResizable(false);
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final List<String> _err = [];
  final List<String> _event = [];
  late KeyboardEvent keyboardEvent;
  int eventNum = 0;
  bool listenIsOn = false;
  final _isHours = true;
  late String keybind;
  bool isKeybinding = false;
  late bool darkTheme;

  void _populateKey() async {
    getKey().then((String value) {
      setState(() {
        keybind = value;
      });
    });
  }

  Future saveKey(String key) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('key', key);
  }

  Future<String> getKey() async {
    final pref = await SharedPreferences.getInstance();
    String s = pref.getString('key') ?? "F";
    return s;
  }

  @override
  void dispose() async {
    super.dispose();
    await _stopWatchTimer.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    keyboardEvent = KeyboardEvent();
    _populateKey();
    _populateTheme();
    /*
    _stopWatchTimer.rawTime.listen((value) =>
        print('rawTime $value ${StopWatchTimer.getDisplayTime(value)}'));
    _stopWatchTimer.minuteTime.listen((value) => print('minuteTime $value'));
    _stopWatchTimer.secondTime.listen((value) => print('secondTime $value'));
    _stopWatchTimer.records.listen((value) => print('records $value'));
    _stopWatchTimer.fetchStopped
        .listen((value) => print('stopped from stream'));
    _stopWatchTimer.fetchEnded.listen((value) => print('ended from stream'));
    */
  }

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countUp,
    /*
    onChange: (value) => print('onChange $value'),
    onChangeRawSecond: (value) => print('onChangeRawSecond $value'),
    onChangeRawMinute: (value) => print('onChangeRawMinute $value'),
    onStopped: () {
      print('onStop');
    },
    onEnded: () {
      print('onEnded');
    },
    */
  );

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    List<String> err = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await KeyboardEvent.platformVersion;
    } on PlatformException {
      err.add('Failed to get platform version.');
    }
    try {
      await KeyboardEvent.init();
    } on PlatformException {
      err.add('Failed to get virtual-key map.');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      if (platformVersion != null) _platformVersion = platformVersion;
      if (err.isNotEmpty) _err.addAll(err);
    });
  }

/*
  Positioned positionedButton(IconData icon, double bottom, String label,
      {double? left, double? right, double? top}) {
    return Positioned(
        top: top,
        right: right,
        bottom: bottom,
        left: left,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(label),
            ),
            FloatingActionButton(
              heroTag: 'StartStop',
              onPressed: () {},
              shape: const CircleBorder(),
              child: Icon(
                icon, //meter função para trocar icons consoante a execução do timer - play || stop
                size: 40,
              ),
            ),
          ],
        ));
  }
*/
  void switchStpState() {
    if (_stopWatchTimer.isRunning) {
      _stopWatchTimer.onStopTimer();
    } else {
      _stopWatchTimer.onResetTimer();
      _stopWatchTimer.onStartTimer();
    }
  }

  void _populateTheme() async {
    getTheme().then((bool value) {
      setState(() {
        darkTheme = value;
      });
    });
  }

  Future saveTheme(bool b) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('theme', b);
  }

  Future<bool> getTheme() async {
    final pref = await SharedPreferences.getInstance();
    bool b = pref.getBool('theme') ?? true;
    return b;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Stopwatch"),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StreamBuilder<int>(
                  stream: _stopWatchTimer.rawTime,
                  initialData: _stopWatchTimer.rawTime.value,
                  builder: (context, snap) {
                    final value = snap.data!;
                    final displayTime =
                        StopWatchTimer.getDisplayTime(value, hours: _isHours);
                    return Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            displayTime,
                            style: const TextStyle(
                                fontSize: 40,
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: Stack(fit: StackFit.expand, children: [
            Positioned(
                top: 100,
                left: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                        text: TextSpan(
                            text: "Keyboard listening: ",
                            style: TextStyle(
                                color: darkTheme ? Colors.white : Colors.black),
                            children: <TextSpan>[
                          TextSpan(
                              text: listenIsOn ? "ON" : "OFF",
                              style: TextStyle(
                                  color: listenIsOn ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold))
                        ])),
                    Switch(
                        value: listenIsOn,
                        onChanged: (bool newValue) {
                          setState(() {
                            if (!isKeybinding) listenIsOn = newValue;
                            if (listenIsOn && !isKeybinding) {
                              keyboardEvent.startListening((keyEvent) {
                                setState(() {
                                  if (keyEvent.vkName == keybind &&
                                      !isKeybinding &&
                                      keyEvent.isKeyDown) {
                                    switchStpState();
                                  }
                                  ;
                                });
                              });
                            } else if (!listenIsOn && !isKeybinding) {
                              keyboardEvent.cancelListening();
                            }
                          });
                        })
                  ],
                )),
            Positioned(
                right: 3,
                bottom: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _stopWatchTimer.isRunning ? "Stop" : "Start",
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          switchStpState();
                        });
                      },
                      shape: const CircleBorder(),
                      backgroundColor: _stopWatchTimer.isRunning
                          ? const Color.fromARGB(255, 224, 76, 18)
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        _stopWatchTimer.isRunning
                            ? Icons.stop
                            : Icons
                                .play_arrow, //meter função para trocar icons consoante a execução do timer - play || stop
                        size: 40,
                      ),
                    ),
                  ],
                )),
            Positioned(
                bottom: 0,
                left: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          isKeybinding ? "Type key..." : "Keybind: $keybind"),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          if (isKeybinding == false) {
                            isKeybinding = true;
                            if (listenIsOn) {
                              listenIsOn = false;
                              keyboardEvent.cancelListening();
                            }
                            keyboardEvent.startListening((keyEvent) {
                              setState(() {
                                if (keyEvent.isKeyDown) {
                                  saveKey(keyEvent.vkName!);
                                  _populateKey();
                                  //keybind = keyEvent.vkName!;
                                  isKeybinding = false;
                                  keyboardEvent.cancelListening();
                                }
                              });
                            });
                          } else if (isKeybinding == true) {
                            isKeybinding = false;
                            keyboardEvent.cancelListening();
                          }
                        });
                      },
                      shape: const CircleBorder(),
                      backgroundColor: isKeybinding
                          ? const Color.fromARGB(255, 224, 76, 18)
                          : Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.keyboard,
                        size: 40,
                      ),
                    ),
                  ],
                )),
            Positioned(
                top: 80,
                right: 0,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        darkTheme = !darkTheme;
                        saveTheme(darkTheme);
                      });
                    },
                    shape: const CircleBorder(),
                    child: Icon(
                      darkTheme ? Icons.brightness_3_sharp : Icons.sunny,
                      size: 20,
                    ),
                  ),
                )),
          ])),
    );
  }
}
