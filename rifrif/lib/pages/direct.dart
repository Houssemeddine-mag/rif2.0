import 'package:flutter/material.dart';

class DirectPage extends StatelessWidget {
  const DirectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chat en direct à venir',
        style: TextStyle(fontSize: 24, color: Color(0xFFAA6B94)),
      ),
    );
  }
}
