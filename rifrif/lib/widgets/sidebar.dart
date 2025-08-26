import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const Sidebar({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
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
                colors: [Color(0xFFAA6B94), Color(0xFFC87BAA)],
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
            title: 'Accueil',
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
            title: 'Profil',
            index: 3,
          ),
          Spacer(),
          Divider(),
          _buildNavItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            index: 4,
          ),
          _buildNavItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Déconnexion',
            index: 5,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/');
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
      leading: Icon(icon, color: isSelected ? Color(0xFFAA6B94) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Color(0xFFAA6B94) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap:
          onTap ??
          () {
            onItemSelected(index);
            Navigator.pop(context); // Close drawer
          },
      selected: isSelected,
      selectedTileColor: Color(0xFFEACBE5).withOpacity(0.2),
    );
  }
}
