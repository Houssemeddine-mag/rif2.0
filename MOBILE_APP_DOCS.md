# 📱 RIF 2025 Mobile App Documentation

## Overview

The **RIF 2025 Mobile App** is a Flutter-based application that serves both regular conference attendees and administrators. It provides a comprehensive interface for viewing conference programs, rating presentations, and managing conference activities.

## 🚀 Getting Started

### Installation & Setup

```bash
# Navigate to the mobile app directory
cd rifrif

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
```

### First Launch

1. **Welcome Screen**: Introduction to the conference
2. **Authentication**: Sign up or log in with email/Google
3. **Profile Setup**: Complete your profile information
4. **Notifications**: Grant permission for conference updates

## 👥 User Types & Interfaces

### 🎯 Regular Users (Conference Attendees)

#### Authentication & Profile

- **Sign Up/Login**: Email/password or Google authentication
- **Profile Management**: Personal information, school, location
- **Profile Completion**: Enhanced features for complete profiles

#### Conference Features

- **Home Dashboard**: Conference overview and statistics
- **Program Schedule**: Browse sessions by date and time
- **Presentation Details**: View speaker information and abstracts
- **Rating System**: Rate presentations and presenters (1-5 stars)
- **Comments**: Provide detailed feedback on presentations
- **Notifications**: Real-time conference updates

#### Navigation Structure

```
🏠 Home
├── Conference overview
├── Countdown timer
├── Quick statistics
└── Upcoming sessions

📅 Program
├── Sessions by date
├── Presentation details
├── Speaker information
└── Rating interface

👤 Profile
├── Personal information
├── Profile completion
├── Settings
└── Account management

🔔 Notifications
├── Conference updates
├── Session reminders
└── General announcements
```

### 👨‍💼 Admin Users (Conference Organizers)

#### Admin Access

- **Login**: Special admin credentials required
- **Admin Interface**: Separate navigation and features
- **Elevated Permissions**: Full conference management access

#### Admin Features

- **Dashboard**: Real-time conference statistics
- **Program Management**: Create/edit sessions and presentations
- **Speaker Management**: Add speaker profiles and images
- **Notification Broadcasting**: Send updates to all attendees
- **Live Streaming**: Direct access to conference streams
- **Settings**: Conference configuration

#### Admin Navigation Structure

```
🏠 Admin Home
├── Conference statistics
├── Registration metrics
├── Quick actions
└── System status

📋 Program Management
├── Session creation/editing
├── Speaker management
├── Schedule organization
└── Presentation details

📢 Notifications
├── Broadcast messages
├── Targeted notifications
├── Priority levels
└── Message templates

📺 Direct/Streaming
├── Live stream controls
├── Screen sharing
└── Presentation mode

⚙️ Settings
├── Conference configuration
├── User management
└── System preferences
```

## 🔧 Key Features

### 📊 Presentation Rating System

- **Dual Rating**: Separate ratings for presenter and presentation
- **Star Interface**: Intuitive 1-5 star rating system
- **Comments**: Optional detailed feedback
- **Real-time Sync**: Ratings sync immediately to admin panel

#### How to Rate Presentations:

1. Navigate to **Program** tab
2. Find the presentation you want to rate
3. **Tap** on the presentation card
4. **Rate the Presenter** (1-5 stars)
5. **Rate the Presentation** (1-5 stars)
6. **Add Comments** (optional)
7. **Submit Rating**

### 🔔 Notification System

- **Real-time Updates**: Instant conference notifications
- **Visual Indicators**: Badge counts on notification bell
- **Categories**: Session updates, general announcements
- **Interactive**: Tap notifications to view details

### 👤 Profile Management

- **Complete Profile**: Enhanced app experience
- **School Information**: Academic affiliation
- **Location Data**: Geographic information
- **Profile Pictures**: Upload personal photos
- **Settings**: Customize app preferences

### 📅 Program Browsing

- **Date Navigation**: Browse sessions by conference day
- **Session Details**: Comprehensive presentation information
- **Speaker Profiles**: View presenter backgrounds
- **Time Management**: Clear scheduling information

## 🎨 User Interface

### Design Principles

- **Conference Branding**: Purple theme (#AA6B94)
- **Accessibility**: Clear fonts and contrast
- **Intuitive Navigation**: Bottom tab navigation
- **Responsive Design**: Works on all screen sizes

### Key Screens

#### Home Screen

- Conference banner with countdown
- Statistics cards (sessions, speakers, participants)
- Recent updates and highlights

#### Program Screen

- Tabbed interface by date
- Session cards with time and speakers
- Tap-to-rate functionality
- Visual rating indicators

#### Profile Screen

- User information display
- Profile completion progress
- Edit capabilities
- Settings access

## 🔐 Authentication & Security

### Login Methods

- **Email/Password**: Traditional authentication
- **Google Sign-in**: Quick social login
- **Auto-login**: Remember user sessions

### Security Features

- **Firebase Authentication**: Secure backend
- **Profile Validation**: Complete profile requirements
- **Session Management**: Automatic logout options

## 📱 Technical Specifications

### Requirements

- **Platform**: Android 6.0+ (API level 23)
- **Storage**: ~50MB app size
- **Network**: Internet required for real-time features
- **Permissions**: Camera (profile pics), Notifications

### Performance

- **Startup Time**: <3 seconds
- **Real-time Updates**: <1 second sync
- **Offline Capability**: Basic program viewing
- **Battery Optimization**: Efficient background processing

## 🐛 Troubleshooting

### Common Issues

#### Login Problems

- Check internet connection
- Verify email/password accuracy
- Try Google sign-in alternative
- Clear app cache if needed

#### Rating Not Saving

- Ensure stable internet connection
- Check if both ratings are provided
- Retry submission after network recovery

#### Notifications Not Working

- Check notification permissions
- Verify app is not in battery optimization
- Restart app if needed

#### Profile Issues

- Complete all required fields
- Use supported image formats for photos
- Check character limits for text fields

### Support Options

- **In-app Help**: Access through settings
- **Error Reporting**: Automatic crash reports
- **Contact Support**: Through profile settings

## 📊 Analytics & Privacy

### Data Collection

- **Usage Analytics**: Anonymous usage patterns
- **Performance Metrics**: App performance data
- **User Preferences**: Settings and customizations

### Privacy Protection

- **Personal Data**: Encrypted and secure
- **Optional Sharing**: User-controlled data sharing
- **GDPR Compliance**: European privacy standards
- **Data Retention**: Configurable retention periods

## 🔄 Updates & Versioning

### Update Process

- **Automatic Updates**: Via app stores
- **In-app Notifications**: Update availability alerts
- **Backward Compatibility**: Supports older versions

### Version History

- **v2.0**: Full rating system, enhanced UI
- **v1.5**: Admin interface, notifications
- **v1.0**: Initial release, basic features

---

**For technical support**: Contact the development team  
**For conference questions**: Reach out to organizers  
**Emergency issues**: Use in-app support features
