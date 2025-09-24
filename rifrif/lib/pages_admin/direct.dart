import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class DirectPage extends StatefulWidget {
  const DirectPage({Key? key}) : super(key: key);

  @override
  State<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _customDataController = TextEditingController();

  String _selectedType = 'general';
  String _selectedPriority = 'normal';
  bool _isSending = false;

  final Map<String, IconData> _typeIcons = {
    'general': Icons.info,
    'session': Icons.event,
    'conference': Icons.mic,
    'urgent': Icons.warning,
    'announcement': Icons.campaign,
  };

  final Map<String, Color> _typeColors = {
    'general': Colors.blue,
    'session': Colors.green,
    'conference': Colors.purple,
    'urgent': Colors.red,
    'announcement': Colors.orange,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _customDataController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      await NotificationService.sendGeneralNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Notification sent successfully to all users!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        _customDataController.clear();
        setState(() {
          _selectedType = 'general';
          _selectedPriority = 'normal';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Error sending notification: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _typeIcons[_selectedType] ?? Icons.info,
              color: _typeColors[_selectedType] ?? Colors.blue,
            ),
            SizedBox(width: 8),
            Text('Notification Preview'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _typeColors[_selectedType]?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _typeIcons[_selectedType] ?? Icons.info,
                          size: 16,
                          color: _typeColors[_selectedType],
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _titleController.text.isNotEmpty
                              ? _titleController.text
                              : 'Notification Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedPriority == 'high'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedPriority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedPriority == 'high'
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _messageController.text.isNotEmpty
                        ? _messageController.text
                        : 'Notification message content...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Now • RIF 2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendNotification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF614f96),
              foregroundColor: Colors.white,
            ),
            child: Text('Send Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      appBar: AppBar(
        title: Text(
          'Send Custom Notification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF614f96),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_titleController.text.isNotEmpty &&
              _messageController.text.isNotEmpty)
            IconButton(
              onPressed: _showPreviewDialog,
              icon: Icon(Icons.preview),
              tooltip: 'Preview Notification',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      colors: [Color(0xFF614f96), Color(0xFF7862ab)],
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
                          Icon(Icons.notifications_active,
                              color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Notification Composer',
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
                        'Create and send custom notifications to all RIF 2025 participants',
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

              // Notification Type Section
              Text(
                'Notification Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
              SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeChip(
                                'general', 'General', Icons.info, Colors.blue),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeChip('session', 'Session',
                                Icons.event, Colors.green),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeChip('conference', 'Conference',
                                Icons.mic, Colors.purple),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeChip(
                                'urgent', 'Urgent', Icons.warning, Colors.red),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      _buildTypeChip('announcement', 'Announcement',
                          Icons.campaign, Colors.orange),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Priority Section
              Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
              SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPriorityChip('normal', 'Normal',
                            Icons.notifications, Colors.grey),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildPriorityChip('high', 'High Priority',
                            Icons.priority_high, Colors.red),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Title Section
              Text(
                'Notification Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
              SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Notification Title',
                          hintText: 'Enter a clear, concise title',
                          prefixIcon:
                              Icon(Icons.title, color: Color(0xFF614f96)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF614f96), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a notification title';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters long';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Notification Message',
                          hintText: 'Enter your detailed message here...',
                          prefixIcon:
                              Icon(Icons.message, color: Color(0xFF614f96)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF614f96), width: 2),
                          ),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a notification message';
                          }
                          if (value.trim().length < 10) {
                            return 'Message must be at least 10 characters long';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  // Test notification button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await PushNotificationService.testLocalNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Test notification sent! Check your notification panel.'),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.bug_report, color: Colors.blue),
                      label: Text('Test System Notification',
                          style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Main action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _titleController.text.isNotEmpty &&
                                  _messageController.text.isNotEmpty
                              ? _showPreviewDialog
                              : null,
                          icon: Icon(Icons.preview),
                          label: Text('Preview'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Color(0xFF614f96)),
                            foregroundColor: Color(0xFF614f96),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendNotification,
                          icon: _isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(Icons.send),
                          label: Text(
                              _isSending ? 'Sending...' : 'Send Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF614f96),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Quick Templates Section
              Text(
                'Quick Templates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
              SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTemplateItem(
                      'Welcome Message',
                      'Welcome to RIF 2025! We\'re excited to have you join us for this amazing conference.',
                      Icons.waving_hand,
                      Colors.green,
                    ),
                    Divider(height: 1),
                    _buildTemplateItem(
                      'Session Reminder',
                      'Don\'t forget! The next session starts in 15 minutes. Please prepare to join.',
                      Icons.access_time,
                      Colors.orange,
                    ),
                    Divider(height: 1),
                    _buildTemplateItem(
                      'Break Announcement',
                      'It\'s time for a coffee break! Sessions will resume in 30 minutes.',
                      Icons.coffee,
                      Colors.brown,
                    ),
                    Divider(height: 1),
                    _buildTemplateItem(
                      'Important Update',
                      'Important update: Please check the updated schedule in your program.',
                      Icons.update,
                      Colors.red,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
      String priority, String label, IconData icon, Color color) {
    final isSelected = _selectedPriority == priority;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateItem(
      String title, String message, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {
        setState(() {
          _titleController.text = title;
          _messageController.text = message;
          _selectedType = title.toLowerCase().contains('session')
              ? 'session'
              : title.toLowerCase().contains('important')
                  ? 'urgent'
                  : 'general';
          _selectedPriority =
              title.toLowerCase().contains('important') ? 'high' : 'normal';
        });
      },
    );
  }
}
