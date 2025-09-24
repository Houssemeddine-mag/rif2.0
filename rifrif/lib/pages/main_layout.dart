import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/sidebar.dart';
import '../widgets/notification_bell.dart';
import '../services/firebase_service.dart';
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

  String get _welcomeMessage {
    final user = FirebaseService.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return " ${user.displayName}";
    } else if (user != null && user.email != null) {
      // Extract name from email (part before @)
      final emailName = user.email!.split('@').first;
      return " $emailName";
    } else {
      return "Bienvenue";
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.exit_to_app,
                    color: Color(0xFF614f96),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Quitter l\'application',
                    style: TextStyle(
                      color: Color(0xFF614f96),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Êtes-vous sûr de vouloir quitter l\'application ?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Don't exit
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Exit the app
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF614f96),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Quitter',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmDisconnect() async {
    final bool shouldDisconnect = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: Color(0xFF614f96),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Déconnexion',
                    style: TextStyle(
                      color: Color(0xFF614f96),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Don't disconnect
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Confirm disconnect
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF614f96),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Se déconnecter',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldDisconnect) {
      try {
        // Sign out the user
        await FirebaseService.signOut();

        // Navigate to login page (AuthWrapper will handle the routing)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } catch (e) {
        print('Error during logout: $e');
        // Show error message if logout fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop(); // Exit the app
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Color(0xFF614f96)),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            _welcomeMessage,
            style: TextStyle(
              color: Color(0xFF614f96),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: false,
          actions: [
            // Notification bell for regular users
            NotificationBell(),
            SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Image.asset('lib/resource/labolire_T.png', height: 40),
                  SizedBox(width: 8),
                  Image.asset('lib/resource/Logo NTIC.png', height: 40),
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
          onDisconnectRequested: _confirmDisconnect,
        ),
        body: _pages[_selectedIndex],
      ),
    );
  }
}
