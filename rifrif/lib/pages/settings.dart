import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _sessionNotifications = true;
  bool _conferenceNotifications = true;
  bool _generalNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _sessionNotifications = prefs.getBool('session_notifications') ?? true;
        _conferenceNotifications =
            prefs.getBool('conference_notifications') ?? true;
        _generalNotifications = prefs.getBool('general_notifications') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('session_notifications', _sessionNotifications);
      await prefs.setBool('conference_notifications', _conferenceNotifications);
      await prefs.setBool('general_notifications', _generalNotifications);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });

    await _saveSettings();

    if (enabled) {
      // Subscribe to general topic when enabling notifications
      await PushNotificationService.subscribeToTopic('general');
      _showSnackBar('Notifications enabled', Colors.green);
    } else {
      // Unsubscribe from all topics when disabling notifications
      await PushNotificationService.unsubscribeFromTopic('general');
      await PushNotificationService.unsubscribeFromTopic('sessions');
      await PushNotificationService.unsubscribeFromTopic('conferences');
      _showSnackBar('Notifications disabled', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFAA6B94),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAA6B94)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFAA6B94), Color(0xFFC87BAA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'App Preferences',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Customize your RIF 2025 experience',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Notifications Section
                  _buildSectionTitle('Notifications', Icons.notifications),

                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Master notification toggle
                        _buildSwitchTile(
                          title: 'Enable Notifications',
                          subtitle:
                              'Receive notifications about sessions and updates',
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          icon: Icons.notifications_active,
                          iconColor: Color(0xFFAA6B94),
                        ),

                        if (_notificationsEnabled) ...[
                          Divider(height: 1),

                          // Session notifications
                          _buildSwitchTile(
                            title: 'Session Notifications',
                            subtitle: 'Get notified about upcoming sessions',
                            value: _sessionNotifications,
                            onChanged: (value) async {
                              setState(() {
                                _sessionNotifications = value;
                              });
                              await _saveSettings();

                              if (value) {
                                await PushNotificationService.subscribeToTopic(
                                    'sessions');
                              } else {
                                await PushNotificationService
                                    .unsubscribeFromTopic('sessions');
                              }
                            },
                            icon: Icons.event,
                            iconColor: Colors.blue,
                          ),

                          Divider(height: 1),

                          // Conference notifications
                          _buildSwitchTile(
                            title: 'Conference Notifications',
                            subtitle:
                                'Get notified about specific presentations',
                            value: _conferenceNotifications,
                            onChanged: (value) async {
                              setState(() {
                                _conferenceNotifications = value;
                              });
                              await _saveSettings();

                              if (value) {
                                await PushNotificationService.subscribeToTopic(
                                    'conferences');
                              } else {
                                await PushNotificationService
                                    .unsubscribeFromTopic('conferences');
                              }
                            },
                            icon: Icons.mic,
                            iconColor: Colors.green,
                          ),

                          Divider(height: 1),

                          // General notifications
                          _buildSwitchTile(
                            title: 'General Notifications',
                            subtitle: 'Receive general announcements',
                            value: _generalNotifications,
                            onChanged: (value) async {
                              setState(() {
                                _generalNotifications = value;
                              });
                              await _saveSettings();
                            },
                            icon: Icons.info,
                            iconColor: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_notificationsEnabled) ...[
                    SizedBox(height: 24),

                    // Notification Behavior Section
                    _buildSectionTitle('Notification Behavior', Icons.tune),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: 'Sound',
                            subtitle: 'Play sound for notifications',
                            value: _soundEnabled,
                            onChanged: (value) async {
                              setState(() {
                                _soundEnabled = value;
                              });
                              await _saveSettings();
                            },
                            icon: Icons.volume_up,
                            iconColor: Colors.purple,
                          ),
                          Divider(height: 1),
                          _buildSwitchTile(
                            title: 'Vibration',
                            subtitle: 'Vibrate for notifications',
                            value: _vibrationEnabled,
                            onChanged: (value) async {
                              setState(() {
                                _vibrationEnabled = value;
                              });
                              await _saveSettings();
                            },
                            icon: Icons.vibration,
                            iconColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24),

                  // App Information Section
                  _buildSectionTitle('About', Icons.info_outline),

                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          title: 'RIF 2025',
                          subtitle:
                              'International Conference on Women in Computer Science Research',
                          icon: Icons.school,
                          iconColor: Color(0xFFAA6B94),
                        ),
                        Divider(height: 1),
                        _buildInfoTile(
                          title: 'Version',
                          subtitle: '2.0.0',
                          icon: Icons.info,
                          iconColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Reset Settings Button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _showResetDialog,
                      icon: Icon(Icons.restore, color: Colors.red[600]),
                      label: Text(
                        'Reset to Default',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[300]!),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFAA6B94), size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFAA6B94),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFFAA6B94),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _showResetDialog() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings'),
        content: Text(
            'Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      setState(() {
        _notificationsEnabled = true;
        _sessionNotifications = true;
        _conferenceNotifications = true;
        _generalNotifications = true;
        _soundEnabled = true;
        _vibrationEnabled = true;
      });
      await _saveSettings();
      _showSnackBar('Settings reset to default', Colors.green);
    }
  }
}
