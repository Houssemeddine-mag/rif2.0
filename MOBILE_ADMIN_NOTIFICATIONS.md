# Mobile Admin Notification System

## Overview

The mobile admin notification system allows conference organizers to send real-time notifications to conference attendees through the RIF mobile app. This system uses Firebase Firestore for real-time communication between the admin interface and user devices.

## Admin Access

To access the mobile admin interface:

1. **Email**: `M_admin@RIF.com`
2. **Password**: `Di8dibXp`

These static credentials bypass the regular Firebase authentication system and provide direct access to the admin interface located in the `pages_admin` folder.

## Admin Features

### 1. Program Management with Notifications

- View all conference sessions organized by date
- Send notifications for entire sessions
- Send notifications for individual conferences
- Real-time program updates

### 2. Notification Types

#### Session Notifications

- Notify all attendees about a session
- Includes session title, date, and time
- Sent from the session card "Notify" button

#### Conference Notifications

- Notify about specific presentations
- Includes presenter information
- Sent from individual conference "Notify" buttons in the session details

#### General Notifications

- Custom messages for important announcements
- Can be sent with different priority levels

### 3. Admin Interface Layout

The admin interface (`pages_admin` folder) includes:

- **Home**: Overview dashboard with conference statistics
- **Program**: Session management with notification controls
- **Direct**: Live streaming/screen sharing controls
- **Profile**: Admin profile management
- **Settings**: System configuration

## User Experience

### Notification Reception

- Real-time notification bell in the app header
- Visual badge showing unread notification count
- Animated bell when new notifications arrive
- Sound and visual alerts (device-dependent)

### Notification Panel

- Swipe-up modal showing all notifications
- Categorized by type (session, conference, general)
- Timestamp and read status indicators
- Mark as read functionality

### Notification Types for Users

1. **Session Notifications** (📅): About upcoming sessions
2. **Conference Notifications** (🎤): About specific presentations
3. **General Notifications** (ℹ️): Important announcements

## Technical Implementation

### Firebase Structure

```
notifications/
├── [notification_id]
│   ├── type: "session" | "conference" | "general"
│   ├── title: "Notification Title"
│   ├── message: "Notification Message"
│   ├── timestamp: Firestore Timestamp
│   ├── isRead: boolean
│   ├── priority: "normal" | "high"
│   └── [type-specific fields...]
```

### Key Components

1. **NotificationService** (`lib/services/notification_service.dart`)

   - Firebase Firestore integration
   - Real-time notification streams
   - Send/receive notification methods

2. **NotificationBell** (`lib/widgets/notification_bell.dart`)

   - User-facing notification widget
   - Real-time badge updates
   - Notification panel interface

3. **Admin Program Page** (`lib/pages_admin/program.dart`)
   - Session notification controls
   - Conference notification controls
   - Custom message dialogs

### Real-time Features

- **Live Updates**: Notifications appear instantly on user devices
- **Unread Counts**: Real-time badge count updates
- **Stream Subscriptions**: Persistent connections for instant delivery
- **Offline Support**: Notifications queue when offline and sync when reconnected

## Usage Instructions

### For Admins

1. **Login**: Use the static credentials to access admin interface
2. **Navigate to Program**: View all conference sessions
3. **Send Session Notification**:

   - Click "Notify" button on any session card
   - Customize the notification message
   - Click "Send Notification"

4. **Send Conference Notification**:
   - Click on a session to view details
   - Click "Notify" button next to specific conferences
   - Customize the message for that presentation
   - Send notification

### For Users

1. **Receive Notifications**: Bell icon shows badge when notifications arrive
2. **View Notifications**: Tap bell icon to open notification panel
3. **Read Notifications**: Tap notifications to mark as read
4. **Mark All Read**: Use "Mark all as read" button in notification panel

## Security Considerations

- Static admin credentials are used for simplicity (replace with proper auth in production)
- Firebase security rules should restrict notification write access to admin users
- All notifications are publicly readable by authenticated users
- Consider implementing notification categories and user preferences

## Future Enhancements

1. **Push Notifications**: Integrate with Firebase Cloud Messaging (FCM)
2. **Notification Scheduling**: Schedule notifications for future delivery
3. **User Preferences**: Allow users to configure notification types
4. **Rich Notifications**: Support images, buttons, and actions
5. **Analytics**: Track notification delivery and engagement rates
6. **Multi-language**: Support multiple languages for notifications

## File Structure

```
lib/
├── services/
│   └── notification_service.dart      # Firebase notification service
├── widgets/
│   └── notification_bell.dart         # User notification widget
├── pages_admin/
│   ├── main_layout.dart              # Admin main layout
│   ├── program.dart                  # Admin program with notifications
│   ├── home.dart                     # Admin dashboard
│   └── [other admin pages...]
├── pages/
│   └── main_layout.dart              # User main layout (with notification bell)
└── Auth/
    └── login.dart                    # Login with static admin credentials
```

This notification system provides a complete real-time communication channel between conference organizers and attendees, enhancing the overall conference experience with timely updates and important announcements.
