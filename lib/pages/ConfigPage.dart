import 'package:flutter/material.dart';

class ConfigPage extends StatefulWidget {
  final Map<String, dynamic> devSettings;

  ConfigPage(this.devSettings);

  @override
  ConfigPageState createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context) {
    debugPrint("Configure: ${widget.devSettings["device_name"]}");

    return Scaffold(
      appBar: AppBar(
        title: Text("Configure"),
        centerTitle: true,
      ),
    );
  }
}
