# RIF 2025 - Project Documentation

Welcome to the **RIF 2025 International Conference** application suite. This project consists of a Flutter mobile application and a React-based web admin panel for managing the Women in Computer Science Research conference.

## 📱 Project Overview

**RIF 2025** is a comprehensive conference management system designed for the International Conference on Women in Computer Science Research, held in Constantine, Algeria. The system provides both mobile and web interfaces for attendees and administrators.

### 🏗️ System Architecture

```
RIF 2025 Conference System
├── 📱 Mobile App (Flutter)
│   ├── Regular User Interface
│   └── Admin Interface
├── 💻 Web Admin Panel (React)
└── 🔥 Firebase Backend
    ├── Firestore Database
    ├── Authentication
    └── Push Notifications
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.32.2 or higher)
- **Node.js** (16.0 or higher)
- **Firebase Project** configured
- **Android Studio** / **VS Code**

### 📱 Mobile App Setup

```bash
cd rifrif
flutter pub get
flutter run
```

### 💻 Admin Panel Setup

```bash
cd rif_admin
npm install
npm run dev
```

## 📁 Project Structure

```
rif2.0/
├── 📱 rifrif/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── pages/               # Regular user pages
│   │   ├── pages_admin/         # Admin user pages
│   │   ├── services/            # Firebase services
│   │   ├── models/              # Data models
│   │   └── widgets/             # Reusable widgets
│   └── android/                 # Android configuration
├── 💻 rif_admin/               # React Admin Panel
│   ├── src/
│   │   ├── Pages/              # Admin panel pages
│   │   ├── Components/         # React components
│   │   ├── services/           # API services
│   │   └── styles/             # CSS stylesheets
│   └── public/                 # Static assets
└── 📚 docs/                    # Documentation
```

## 🔗 Quick Links

- [📱 Mobile App Documentation](./MOBILE_APP_DOCS.md)
- [💻 Admin Panel Documentation](./ADMIN_PANEL_DOCS.md)
- [🔐 Admin Credentials](./ADMIN_CREDENTIALS.md)
- [🔥 Firebase Setup](./FIREBASE_SETUP.md)
- [📊 Features Overview](./FEATURES_OVERVIEW.md)

## 🌟 Key Features

### 📱 Mobile Application

- **User Authentication** (Email/Password, Google Sign-in)
- **Conference Program** with real-time updates
- **Presentation Rating System** (5-star ratings + comments)
- **Push Notifications** for conference updates
- **User Profile Management**
- **Admin Interface** for conference management

### 💻 Web Admin Panel

- **Real-time Statistics Dashboard**
- **Program Management** (sessions, presentations, speakers)
- **User Management** and analytics
- **Presentation Analytics** with ratings and feedback
- **Notification Broadcasting**
- **Data Export** capabilities

### 🔥 Backend Features

- **Real-time Firestore Database**
- **User Authentication & Profiles**
- **Push Notification Service**
- **File Storage** for speaker images
- **Analytics & Reporting**

## 🎯 Target Users

### 👥 Conference Attendees

- View conference schedule and speakers
- Rate presentations and provide feedback
- Receive real-time notifications
- Manage personal profiles

### 👨‍💼 Conference Administrators

- Manage conference program and sessions
- Monitor user engagement and feedback
- Send notifications to attendees
- Access comprehensive analytics

### 🎤 Speakers/Presenters

- View their presentation schedule
- Access presentation materials
- See audience feedback and ratings

## 🏆 Conference Information

**Conference**: RIF 2025 - Women in Computer Science Research  
**Location**: Constantine University 2, Algeria  
**Date**: December 2025  
**Organizers**: Computer Science Department

## 📞 Support & Contact

For technical support or questions about the conference system:

- **Technical Issues**: Contact the development team
- **Conference Questions**: Contact the organizing committee
- **Account Issues**: Use the in-app support features

## 📄 License

This project is developed for the RIF 2025 International Conference. All rights reserved.

---

**Last Updated**: September 2025  
**Version**: 2.0  
**Status**: Production Ready
