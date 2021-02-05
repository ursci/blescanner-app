import 'dart:io';

import 'package:blescanner_app/pages/BlePage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(BleApp());

class BleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      PermissionHandler().requestPermissions(
          [PermissionGroup.location, PermissionGroup.sensors]);
    }

    return MaterialApp(
      title: "Bluetooth Device Scanner",
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: BlePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
