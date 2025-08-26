import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFEACBE5),
            child: Icon(Icons.person, size: 50, color: Color(0xFFAA6B94)),
          ),
          SizedBox(height: 20),
          Text(
            'Profil Utilisateur',
            style: TextStyle(fontSize: 24, color: Color(0xFFAA6B94)),
          ),
        ],
      ),
    );
  }
}
