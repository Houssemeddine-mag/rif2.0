import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final VoidCallback? onDisconnectRequested;

  const Sidebar({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
    this.onDisconnectRequested,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFFFDFDFD),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF614f96), Color(0xFF7862ab)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/resource/rifnonbgcopy.png',
                    height: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'RIF Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            title: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Programme',
            index: 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.chat_outlined,
            title: 'Direct',
            index: 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            index: 3,
          ),
          Spacer(),
          Divider(),
          _buildNavItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            index: 4,
          ),
          _buildNavItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Logout',
            index: 5,
            onTap: () {
              Navigator.pop(context); // Close drawer first
              if (onDisconnectRequested != null) {
                onDisconnectRequested!();
              } else {
                // Fallback: direct logout without confirmation
                _performLogout(context);
              }
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Color(0xFF614f96) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Color(0xFF614f96) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap ??
          () {
            onItemSelected(index);
            Navigator.pop(context); // Close drawer
          },
      selected: isSelected,
      selectedTileColor: Color(0xFFE6DFF2).withOpacity(0.2),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
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
          content: Text('Error during logout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
