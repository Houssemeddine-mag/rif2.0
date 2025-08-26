import 'package:flutter/material.dart';

class ProgramPage extends StatelessWidget {
  const ProgramPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Programme à venir',
        style: TextStyle(fontSize: 24, color: Color(0xFFAA6B94)),
      ),
    );
  }
}
