import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:isolate';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Using isolate to calc simple numbers'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  bool started = false;
  bool firstStart = true;
  int lastSimpleNumber = 1;
  AnimationController _controller;
  Isolate currentIsolate;
  SendPort mainSendPort;
  ReceivePort mainReceivePort;
  Capability resumeCapability;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 5))..repeat();
  }

  void onStartPressed() {
    setState(() {
      if (started) {
        mainSendPort.send(false);
      } else if (currentIsolate == null) {
        spawnIsolate();
      } else {
        mainSendPort.send(true);
      }
      started = !started;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Icon(Icons.ac_unit_sharp, size: 96, color: Colors.lightBlue),
            ),
            Container(
              child: Text(
                lastSimpleNumber.toString(),
                style: TextStyle(fontSize: 24),
              ),
              padding: EdgeInsets.symmetric(vertical: 32),
            )
          ])),
      floatingActionButton: FloatingActionButton(
        onPressed: onStartPressed,
        tooltip: 'Increment',
        child: started ? Icon(Icons.pause) : Icon(Icons.not_started),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  static _calcSimpleNumbers(SendPort callerSendPort) async {
    ReceivePort isolateReceivePort = ReceivePort();
    callerSendPort.send(isolateReceivePort.sendPort);
    bool started = true;
    isolateReceivePort.listen((message) {
      started = message;
      print("Received: " + message.toString());
    });

    int i = 1;
    while (true) {
      if(started) {
        if (isSimple(i)) {
          callerSendPort.send(i);
          await Future<void>.delayed(Duration(milliseconds: 500));
        }
        i++;
      }
      else {
        await Future<void>.delayed(Duration(milliseconds: 500));
      }
    }
  }

  static bool isSimple(int num) {
    for (int i = 2; i < num; i++) {
      if (num % i == 0) return false;
    }
    return true;
  }

  void spawnIsolate() async {
    mainReceivePort = ReceivePort();
    currentIsolate = await Isolate.spawn(_calcSimpleNumbers, mainReceivePort.sendPort);
    mainReceivePort.listen((message) {
      if(message is SendPort){
        mainSendPort = message;
        return;
      }
      setState(() {
        lastSimpleNumber = message;
      });
    });
  }
}
