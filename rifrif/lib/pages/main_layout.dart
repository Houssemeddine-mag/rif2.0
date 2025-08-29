import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'direct.dart';
import 'home.dart';
import 'profile.dart';
import 'program.dart';
import 'settings.dart';

class MainLayout extends StatefulWidget {
  final String userRole;
  const MainLayout({Key? key, required this.userRole}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        userRole: widget.userRole,
        onNavigateToProgram: () {
          setState(() {
            _selectedIndex = 1; // Navigate to program page
          });
        },
      ),
      ProgramPage(),
      DirectPage(),
      ProfilePage(),
      SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFFAA6B94)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Image.asset('lib/resource/labolire_T.png', height: 30),
                SizedBox(width: 8),
                Image.asset('lib/resource/Logo NTIC.png', height: 30),
              ],
            ),
          ),
        ],
      ),
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: _pages[_selectedIndex],
    );
  }
}
