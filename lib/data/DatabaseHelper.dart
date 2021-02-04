import 'dart:async';
import 'dart:io' as io;

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

///
/// NOTE: Bool and Date are not SQLite supported types as of this writing.
/// (https://pub.dartlang.org/packages/sqflite)
///

class DatabaseHelper {
  final int _version = 1;

  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper.internal();

  static Database _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    } else {
      _db = await initDb();
      return _db;
    }
  }

  dynamic initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "blescanner.db");

    debugPrint("in initDB");

    var tDb = await openDatabase(
      path,
      version: _version,
      readOnly: false,
      onCreate: _onCreate,
    );

    return tDb;
  }

  _onCreate(Database db, int version) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String deviceId = "device1";

    if (io.Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.androidId;
    } else if (io.Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.utsname.nodename;
    }

    ///
    /// Creating the Device Settings Table
    ///
    await db.execute("CREATE TABLE device_setting( "
        "device_name TEXT, "
        "location_name TEXT,"
        "upload_url TEXT,"
        "refresh_interval INTEGER DEFAULT 30"
        " )");
    await db.insert("device_setting", {
      "device_name": deviceId,
      "location_name": "Bldg1 Rm1",
      "upload_url": "http://localhost/bleServer",
      "refresh_interval": 30
    });

    await db.execute("CREATE TABLE scanned_devices("
        "scanned_name TEXT,"
        "scanned_id TEXT,"
        "scanned_rssi INTEGER,"
        "scanned_time TEXT"
        " )");

    debugPrint("Creating Database");
  }

  int boolToInt(bool val) {
    return val == true ? 1 : 0;
  }

  bool intToBool(int val) {
    return val == 1 ? true : false;
  }

  insertScannedDevice(
      String devName, String devId, int devRssi, String timeStamp) async {
    Database dbClient = await db;

    await dbClient.insert("scanned_devices", {
      "scanned_name": devName,
      "scanned_id": devId,
      "scanned_rssi": devRssi,
      "scanned_time": timeStamp
    });
  }

  Future<List<Map<String, dynamic>>> getScannedDevices() async {
    Database dbClient = await db;

    List<Map<String, dynamic>> retVal = await dbClient
        .rawQuery("select device_name,location_name,scanned_name,scanned_id,"
            "scanned_rssi,scanned_time from device_setting,scanned_devices");

    //await dbClient.query("scanned_devices");

    return retVal;
  }

  deleteScannedDevices() async {
    Database dbClient = await db;

    dbClient.delete("scanned_devices");
  }

  updateDeviceSettings(
      String devName, String locName, String url, int refInterval) async {
    Database dbClient = await db;

    await dbClient.update("device_setting", {
      "device_name": devName,
      "location_name": locName,
      "upload_url": url,
      "refresh_interval": refInterval
    });
  }

  Future<Map<String, dynamic>> getDeviceSettings() async {
    Database dbClient = await db;

    List<Map<String, dynamic>> retVal = await dbClient.query("device_setting");

    if (retVal == null) {
      return null;
    }
    if (retVal.isEmpty) {
      return null;
    }

    return retVal[0];
  }
}
