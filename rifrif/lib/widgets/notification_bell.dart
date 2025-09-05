import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationBell extends StatefulWidget {
  const NotificationBell({Key? key}) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  int unreadCount = 0;
  List<Map<String, dynamic>> notifications = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimationController();
    _setupStreams();
  }

  void _setupAnimationController() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  void _setupStreams() {
    // Listen to unread count changes
    _unreadCountSubscription =
        NotificationService.getUnreadCountStream().listen(
      (count) {
        if (mounted) {
          setState(() {
            final oldCount = unreadCount;
            unreadCount = count;

            // Animate bell when new notifications arrive
            if (count > oldCount && count > 0) {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
            }
          });
        }
      },
      onError: (error) {
        print('Error listening to unread count: $error');
      },
    );

    // Listen to notifications changes
    _notificationsSubscription =
        NotificationService.getNotificationsStream().listen(
      (notifs) {
        if (mounted) {
          setState(() {
            notifications = notifs;
          });
        }
      },
      onError: (error) {
        print('Error listening to notifications: $error');
      },
    );
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAA6B94),
                    ),
                  ),
                  Row(
                    children: [
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () async {
                            await NotificationService.markAllAsRead();
                          },
                          child: Text('Mark all read'),
                        ),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            // Show confirmation dialog for clearing all notifications
                            final shouldClear = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Clear All Notifications'),
                                content: Text(
                                    'Are you sure you want to delete all notifications? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text('Clear All'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldClear == true) {
                              try {
                                // Delete all notifications
                                for (final notification in notifications) {
                                  await NotificationService.deleteNotification(
                                      notification['id']);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('All notifications cleared'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to clear notifications'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                          ),
                          child: Text('Clear All'),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Notifications list
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'You\'ll see updates about sessions here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'general';
    final timestamp = notification['timestamp'];

    // Format timestamp
    String timeAgo = 'Now';
    if (timestamp != null) {
      final notificationTime = timestamp.toDate();
      final difference = DateTime.now().difference(notificationTime);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'session':
        iconData = Icons.event;
        iconColor = Color(0xFFAA6B94);
        break;
      case 'conference':
        iconData = Icons.mic;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.green;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isRead ? Colors.white : Color(0xFFAA6B94).withOpacity(0.1),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            SizedBox(height: 4),
            Row(
              children: [
                if (notification['sessionTitle'] != null) ...[
                  Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    notification['sessionTitle'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 60, // Fixed width to prevent overflow
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete button
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  onPressed: () async {
                    // Show confirmation dialog
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Notification'),
                        content: Text(
                            'Are you sure you want to delete this notification?'),
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
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      try {
                        await NotificationService.deleteNotification(
                            notification['id']);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notification deleted'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete notification'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                  padding: EdgeInsets.all(2),
                ),
              ),
              SizedBox(width: 4),
              // Unread indicator
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFFAA6B94),
                    shape: BoxShape.circle,
                  ),
                )
              else
                SizedBox(width: 8), // Maintain spacing when read
            ],
          ),
        ),
        onTap: () async {
          if (!isRead) {
            await NotificationService.markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: Color(0xFFAA6B94),
                  size: 28,
                ),
                onPressed: _showNotificationsPanel,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
