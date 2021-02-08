import 'dart:convert';

import 'package:blescanner_app/data/DatabaseHelper.dart';
import 'package:blescanner_app/network/NetworkResult.dart';
import 'package:blescanner_app/network/RestUtil.dart';
import 'package:blescanner_app/utils/DialogUtil.dart';
import 'package:flutter/material.dart';

class ConfigPage extends StatefulWidget {
  final Map<String, dynamic> devSettings;

  ConfigPage(this.devSettings);

  @override
  ConfigPageState createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();

  String _devName;
  String _locName;
  String _uploadUrl;
  int _refInterval = 30;

  @override
  void initState() {
    super.initState();
    _refInterval = widget.devSettings["refresh_interval"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configure"),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Device Settings",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.indigoAccent,
                ),
              ),
              Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        initialValue: widget.devSettings["device_name"],
                        decoration: const InputDecoration(
                          hintText: 'Name of this Device',
                          labelText: 'Device Name',
                        ),
                        validator: (value) {
                          if (value.length == 0) {
                            return "device name can not be empty";
                          }
                          return null;
                        },
                        onSaved: (val) {
                          _devName = val;
                        },
                      ),
                      TextFormField(
                        initialValue: widget.devSettings["location_name"],
                        decoration: const InputDecoration(
                          hintText: 'Where this device is Located',
                          labelText: 'Location Name',
                        ),
                        validator: (value) {
                          if (value.length == 0) {
                            return "location name can not be empty";
                          }
                          return null;
                        },
                        onSaved: (val) {
                          _locName = val;
                        },
                      ),
                      TextFormField(
                        initialValue: widget.devSettings["upload_url"],
                        decoration: const InputDecoration(
                          hintText: 'Upload Server URL',
                          labelText: 'Upload URL',
                        ),
                        validator: (value) {
                          if (value.length == 0) {
                            return "URL can not be empty";
                          }
                          return null;
                        },
                        onSaved: (val) {
                          _uploadUrl = val;
                        },
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Search Interval : ",
                            style: TextStyle(fontSize: 16),
                          ),
                          DropdownButton<int>(
                            value: _refInterval,
                            onChanged: (val) {
                              setState(() {
                                _refInterval = val;
                              });
                            },
                            items: [
                              DropdownMenuItem<int>(
                                value: 30,
                                child: Text("30 seconds"),
                              ),
                              DropdownMenuItem<int>(
                                value: 60,
                                child: Text("60 seconds"),
                              ),
                              DropdownMenuItem<int>(
                                value: 180,
                                child: Text("180 seconds"),
                              ),
                              DropdownMenuItem<int>(
                                value: 300,
                                child: Text("300 seconds"),
                              ),
                              DropdownMenuItem<int>(
                                value: 600,
                                child: Text("600 seconds"),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      RaisedButton(
                        child: Text("Save"),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            _formKey.currentState.save();
                            saveToDb();
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
              Text(
                "Upload Data",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.indigoAccent,
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(22.0, 8.0, 22.0, 15.0),
                child: Text(
                  "Upload Scanned Data into the Server. "
                  "Ensure that a WIFI connection is working",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              RaisedButton(
                child: Text("Upload"),
                onPressed: () => uploadData(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  uploadData() async {
    DatabaseHelper dbh = DatabaseHelper();

    List<Map<String, dynamic>> retVal = await dbh.getScannedDevices();
    debugPrint("Records in DB: ${retVal.length}");

    if (retVal.length < 1) {
      DialogUtil.showCustomDialog(
          context, "Error", "No Data to Upload", "Close");
      return;
    }

    Map<String, dynamic> devData = await dbh.getDeviceSettings();

    DialogUtil.showOnSendDialog(context, "Uploading Data");

    Map<String, dynamic> upData = {"device_logs": retVal};

    RestUtil restUtil = RestUtil();
    NetworkResult nr = await restUtil.registerData(
        jsonEncode(upData), {}, devData["upload_url"]);

    Navigator.of(context).pop();

    if (!nr.internetConnected) {
      DialogUtil.showCustomDialog(
          context, "Error", "No Internet Connection.", "Close");
    } else if (nr.response.compareTo("NG") == 0) {
      DialogUtil.showCustomDialog(
          context, "Error", "Problem uploading data.", "Close");
    } else {
      await DialogUtil.showCustomDialog(
          context, "Upload", "Data has been uploaded.", "Close");
      dbh.deleteScannedDevices();
    }
  }

  saveToDb() async {
    DatabaseHelper dbh = DatabaseHelper();
    await dbh.updateDeviceSettings(
        _devName, _locName, _uploadUrl, _refInterval);

    DialogUtil.showCustomDialog(
        context, "Save", "Device Settings data has been saved.", "OK");
  }

  @override
  void dispose() {
    super.dispose();
  }
}
