import 'dart:async';

import 'package:blescanner_app/data/DatabaseHelper.dart';
import 'package:blescanner_app/pages/ConfigPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BlePage extends StatefulWidget {
  @override
  BlePageState createState() => BlePageState();
}

class BlePageState extends State {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;

  int _fb = 1;
  bool _bluetoothIsOn = true;
  Widget _displayWidget;

  DatabaseHelper _dbh = DatabaseHelper();
  Map<String, dynamic> _deviceInfo = Map<String, dynamic>();

  Timer _timer;

  @override
  void initState() {
    super.initState();
    getDeviceInfo();
  }

  getDeviceInfo() async {
    _deviceInfo = await _dbh.getDeviceSettings();

    if (_deviceInfo != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int refInterval = 30;

    if (_fb == 1 && _deviceInfo.isNotEmpty) {
      _displayWidget = startEmptyScreen();
      refInterval = _deviceInfo["refresh_interval"];
    }

    Widget waitWidget = Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(
              height: 20,
            ),
            Text(_deviceInfo.isEmpty ? "Loading Data" : "Scanning For Devices"),
          ],
        ),
      ),
    );

    return _deviceInfo.isEmpty
        ? Scaffold(body: waitWidget)
        : Scaffold(
            appBar: AppBar(
              title: Text("Bluetooth Device Scanner"),
              centerTitle: true,
              automaticallyImplyLeading: true,
              actions: <Widget>[
                IconButton(
                  onPressed: _fb != 1
                      ? null
                      : () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      ConfigPage(_deviceInfo)))
                              .then((v) {
                            getDeviceInfo();
                          });
                        },
                  icon: Icon(Icons.settings),
                ),
              ],
            ),
            floatingActionButton: SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                elevation: 20.0,
                backgroundColor: _fb == 1 ? Colors.indigo : Colors.red,
                child: Icon(
                  _fb == 1 ? Icons.settings_input_antenna : Icons.block,
                  color: Colors.white,
                  size: 32.0,
                ),
                onPressed: () async {
                  bool bleISon = await _flutterBlue.isOn;
                  setState(() {
                    if (bleISon) {
                      _bluetoothIsOn = true;
                      if (_fb == 1) {
                        _fb = 0;

                        _displayWidget = waitWidget;
                        scanDevices();

                        _timer = Timer.periodic(Duration(seconds: refInterval),
                            (timer) {
                          _timer = timer;
                          setState(() {
                            _displayWidget = waitWidget;
                            scanDevices();
                          });
                        });
                      } else {
                        _fb = 1;
                        _timer.cancel();
                        _displayWidget = startEmptyScreen();
                      }
                    } else {
                      _bluetoothIsOn = false;
                      _fb = 1;
                    }
                  });
                },
              ),
            ),
            body:
                _bluetoothIsOn == true ? _displayWidget : bluetoothOffScreen(),
          );
  }

  scanDevices() async {
    debugPrint("*** scanning ${DateTime.now().toIso8601String()}***");
    if (_bluetoothIsOn) {
      List<ScanResult> results =
          await _flutterBlue.scan(timeout: Duration(seconds: 4)).toList();

      await _flutterBlue.stopScan();

      List<Widget> bleList = List<Widget>();
      results = results.toSet().toList();

      String dateTime = DateTime.now().toIso8601String();
      DatabaseHelper dbh = DatabaseHelper();

      for (ScanResult result in results) {
        Color bColor;

        switch (result.device.type) {
          case BluetoothDeviceType.classic:
            bColor = Colors.blue;
            break;
          case BluetoothDeviceType.unknown:
            bColor = Colors.black;
            break;
          case BluetoothDeviceType.le:
            bColor = Colors.indigo;
            break;
          case BluetoothDeviceType.dual:
            bColor = Colors.deepPurple;
            break;
          default:
            bColor = Colors.black;
        }

        Card t = Card(
          elevation: 8.0,
          child: ListTile(
            leading: Icon(
              Icons.devices_other,
              size: 38.0,
              color: bColor,
            ),
            title: result.device.name.length > 0
                ? Text(result.device.name)
                : Text("na"),
            subtitle: Text("${result.device.id.id}"),
            trailing: Text(
              "${result.rssi}",
              style: result.rssi >= -75
                  ? TextStyle(color: Colors.green)
                  : TextStyle(color: Colors.red),
            ),
          ),
        );
        bleList.add(t);
        dbh.insertScannedDevice(
            result.device.name, result.device.id.id, result.rssi, dateTime);

        debugPrint(
            "Name: ${result.device.name} ,Id: ${result.device.id}, RSSI: ${result.rssi} ${result.device.type}");
      }
      setState(() {
        _fb == 1
            ? _displayWidget = startEmptyScreen()
            : _displayWidget = SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: bleList,
                  ),
                ),
              );
      });
    }
  }

  Widget startEmptyScreen() {
    return Container(
      padding: EdgeInsets.all(15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            DataTable(dataRowHeight: 40, columns: [
              DataColumn(label: Text("")),
              DataColumn(label: Text("")),
            ], rows: [
              DataRow(cells: [
                DataCell(Text("Device ID")),
                DataCell(Text(
                  _deviceInfo["device_name"],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ))
              ]),
              DataRow(cells: [
                DataCell(Text("Location Name")),
                DataCell(Text(
                  _deviceInfo["location_name"],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ))
              ]),
              DataRow(cells: [
                DataCell(Text("Scan Interval")),
                DataCell(Text(
                  "${_deviceInfo["refresh_interval"]} seconds",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ))
              ])
            ]),
            SizedBox(height: 60),
            Text(
              "Press Button to Start the Scan.",
              style: TextStyle(color: Colors.indigo, fontSize: 24.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget bluetoothOffScreen() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        //mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.bluetooth_disabled,
            size: 180.0,
            color: Colors.blueAccent,
          ),
          Text('Bluetooth Adapter is  not available',
              style: TextStyle(color: Colors.blueAccent, fontSize: 22.0)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }
}
