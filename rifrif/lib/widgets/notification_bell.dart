import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/user_notification_service.dart';
import '../services/firebase_service.dart';
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
  List<Map<String, dynamic>> visibleNotifications = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool isAdmin = false;
  bool isProcessing = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _setupAnimationController();
    _checkUserRole();
    _setupStreams();
  }

  void _checkUserRole() {
    // Check if current user is admin based on email
    final user = FirebaseService.currentUser;
    if (user != null && user.email != null) {
      // Define admin emails here or check from database
      const adminEmails = [
        'admin@rif.edu',
        'admin@example.com',
        // Add your admin emails here
      ];
      isAdmin = adminEmails.contains(user.email);
    }
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
    // Listen to notifications changes
    _notificationsSubscription =
        NotificationService.getNotificationsStream().listen(
      (notifs) async {
        if (mounted) {
          await _updateNotificationState(notifs);
        }
      },
      onError: (error) {
        print('Error listening to notifications: $error');
      },
    );
  }

  // Helper method to update notification state
  Future<void> _updateNotificationState(
      List<Map<String, dynamic>> notifs) async {
    notifications = notifs;

    // Filter notifications based on user dismissals
    visibleNotifications =
        await UserNotificationService.filterVisibleNotifications(notifs);

    // Calculate unread count for visible notifications
    final visibleUnreadCount =
        await UserNotificationService.getVisibleUnreadCount(notifs);

    setState(() {
      final oldCount = unreadCount;
      unreadCount = visibleUnreadCount;

      // Animate bell when new notifications arrive
      if (visibleUnreadCount > oldCount && visibleUnreadCount > 0) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
    });
  }

  // Method to refresh notifications manually
  Future<void> _refreshNotifications() async {
    try {
      // Cancel existing subscription
      _notificationsSubscription?.cancel();

      // Set up new stream
      _setupStreams();

      // Small delay to allow stream to initialize
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print('Error refreshing notifications: $e');
    }
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
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setState(() {
                                    isProcessing = true;
                                  });

                                  // Show immediate UI feedback
                                  if (mounted) {
                                    setState(() {
                                      // Immediately update UI to show all as read
                                      unreadCount = 0;
                                      for (var notification
                                          in visibleNotifications) {
                                        notification['isRead'] = true;
                                      }
                                    });
                                  }

                                  try {
                                    if (isAdmin) {
                                      await NotificationService.markAllAsRead();
                                    } else {
                                      // For regular users, mark all visible notifications as read locally
                                      for (final notification
                                          in visibleNotifications) {
                                        final id = notification['id'];
                                        if (id != null) {
                                          await UserNotificationService
                                              .markAsReadLocally(id);
                                        }
                                      }
                                    }

                                    // Refresh the notifications display for consistency
                                    await _refreshNotifications();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'All notifications marked as read'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('Error marking all as read: $e');
                                    // Refresh to get correct state if there was an error
                                    await _refreshNotifications();

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to mark notifications as read'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isProcessing = false;
                                      });
                                    }
                                  }
                                },
                          child: isProcessing
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                )
                              : Text('Mark all read'),
                        ),
                      if (visibleNotifications.isNotEmpty)
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setState(() {
                                    isProcessing = true;
                                  });

                                  // Show confirmation dialog for clearing all notifications
                                  final shouldClear = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(isAdmin
                                          ? 'Delete All Notifications'
                                          : 'Clear All Notifications'),
                                      content: Text(isAdmin
                                          ? 'Are you sure you want to delete all notifications for everyone? This action cannot be undone.'
                                          : 'Are you sure you want to clear all notifications from your view? They will still exist for other users.'),
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
                                          child: Text(isAdmin
                                              ? 'Delete All'
                                              : 'Clear All'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldClear == true) {
                                    // Show immediate UI feedback
                                    if (mounted) {
                                      setState(() {
                                        if (isAdmin) {
                                          // Admin: Clear all notifications immediately in UI
                                          notifications.clear();
                                          visibleNotifications.clear();
                                        } else {
                                          // Regular user: Clear from visible list immediately
                                          visibleNotifications.clear();
                                        }
                                        unreadCount = 0;
                                      });
                                    }

                                    try {
                                      if (isAdmin) {
                                        // Admin: Delete all notifications from database
                                        await NotificationService
                                            .deleteAllNotifications();
                                      } else {
                                        // Regular user: Dismiss all notifications locally
                                        for (final notification
                                            in notifications) {
                                          final id = notification['id'];
                                          if (id != null) {
                                            await UserNotificationService
                                                .dismissNotification(id);
                                          }
                                        }
                                      }

                                      // Refresh for consistency
                                      await _refreshNotifications();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(isAdmin
                                                ? 'All notifications deleted for everyone'
                                                : 'All notifications cleared from your view'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error clearing notifications: $e');
                                      // Refresh to get correct state if there was an error
                                      await _refreshNotifications();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(isAdmin
                                                ? 'Failed to delete notifications'
                                                : 'Failed to clear notifications'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  }

                                  // Reset processing state
                                  if (mounted) {
                                    setState(() {
                                      isProcessing = false;
                                    });
                                  }
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                          ),
                          child: Text(isAdmin ? 'Delete All' : 'Clear All'),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Notifications list
              Expanded(
                child: visibleNotifications.isEmpty
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
                        itemCount: visibleNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = visibleNotifications[index];
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
    final isReadInDB = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'general';
    final timestamp = notification['timestamp'];
    final notificationId = notification['id'];

    // For regular users, check local read status as well
    return FutureBuilder<bool>(
      future: isAdmin
          ? Future.value(false)
          : UserNotificationService.isNotificationReadLocally(notificationId),
      builder: (context, snapshot) {
        final isReadLocally = snapshot.data ?? false;
        final isRead = isAdmin ? isReadInDB : (isReadInDB || isReadLocally);

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
                      Expanded(
                        child: Text(
                          notification['sessionTitle'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                  // Delete/Dismiss button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: Icon(
                        isAdmin ? Icons.delete_outline : Icons.clear,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isAdmin
                                ? 'Delete Notification'
                                : 'Clear Notification'),
                            content: Text(isAdmin
                                ? 'Are you sure you want to delete this notification for everyone?'
                                : 'Are you sure you want to clear this notification from your view?'),
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
                                child: Text(isAdmin ? 'Delete' : 'Clear'),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          // Show immediate UI feedback
                          if (mounted) {
                            setState(() {
                              if (isAdmin) {
                                // Admin: Remove from both lists immediately
                                notifications.removeWhere(
                                    (n) => n['id'] == notificationId);
                                visibleNotifications.removeWhere(
                                    (n) => n['id'] == notificationId);
                              } else {
                                // Regular user: Remove from visible list immediately
                                visibleNotifications.removeWhere(
                                    (n) => n['id'] == notificationId);
                              }
                              // Recalculate unread count
                              unreadCount = visibleNotifications
                                  .where((n) => !(n['isRead'] ?? false))
                                  .length;
                            });
                          }

                          try {
                            if (isAdmin) {
                              // Admin: Delete from database
                              await NotificationService.deleteNotification(
                                  notificationId);
                            } else {
                              // Regular user: Dismiss locally
                              await UserNotificationService.dismissNotification(
                                  notificationId);
                            }

                            // Refresh for consistency
                            await _refreshNotifications();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAdmin
                                      ? 'Notification deleted for everyone'
                                      : 'Notification cleared from your view'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error deleting/dismissing notification: $e');
                            // Refresh to get correct state if there was an error
                            await _refreshNotifications();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAdmin
                                      ? 'Failed to delete notification'
                                      : 'Failed to clear notification'),
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
                // Show immediate UI feedback
                if (mounted) {
                  setState(() {
                    // Find and update the notification in the lists
                    final notificationIndex = visibleNotifications
                        .indexWhere((n) => n['id'] == notificationId);
                    if (notificationIndex != -1) {
                      visibleNotifications[notificationIndex]['isRead'] = true;
                    }

                    final allNotificationIndex = notifications
                        .indexWhere((n) => n['id'] == notificationId);
                    if (allNotificationIndex != -1) {
                      notifications[allNotificationIndex]['isRead'] = true;
                    }

                    // Recalculate unread count
                    unreadCount = visibleNotifications
                        .where((n) => !(n['isRead'] ?? false))
                        .length;
                  });
                }

                try {
                  if (isAdmin) {
                    await NotificationService.markAsRead(notificationId);
                  } else {
                    await UserNotificationService.markAsReadLocally(
                        notificationId);
                  }

                  // Refresh for consistency
                  await _refreshNotifications();
                } catch (e) {
                  print('Error marking notification as read: $e');
                  // Refresh to get correct state if there was an error
                  await _refreshNotifications();
                }
              }
            },
          ),
        );
      },
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
