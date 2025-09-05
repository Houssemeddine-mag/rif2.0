import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Paramètres à venir',
        style: TextStyle(fontSize: 24, color: Color(0xFFAA6B94)),
      ),
    );
  }
}
