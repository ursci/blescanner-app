import 'package:blescanner_app/pages/BlePage.dart';
import 'package:flutter/material.dart';

void main() => runApp(BleApp());

class BleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Bluetooth Device Scanner",
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: BlePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
