import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? school;
  final String? schoolLevel;
  final String? gender; // 'male', 'female', or null
  final DateTime? birthday;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isProfileComplete;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.school,
    this.schoolLevel,
    this.gender,
    this.birthday,
    this.location,
    this.createdAt,
    this.updatedAt,
    this.isProfileComplete = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      school: map['school'],
      schoolLevel: map['schoolLevel'],
      gender: map['gender'],
      birthday: map['birthday'] != null
          ? (map['birthday'] is Timestamp
              ? (map['birthday'] as Timestamp).toDate()
              : DateTime.parse(map['birthday']))
          : null,
      location: map['location'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
      isProfileComplete: map['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'school': school,
      'schoolLevel': schoolLevel,
      'gender': gender,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'location': location,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isProfileComplete': isProfileComplete,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? school,
    String? schoolLevel,
    String? gender,
    DateTime? birthday,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      school: school ?? this.school,
      schoolLevel: schoolLevel ?? this.schoolLevel,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return displayName![0].toUpperCase();
      }
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  String get displayEmailOrName {
    return displayName?.isNotEmpty == true
        ? displayName!
        : email.split('@').first;
  }

  // Get profile circle color based on gender
  Color get profileCircleColor {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Color(0xFF4FC3F7); // Blue for male
      case 'female':
        return Color(0xFFFF69B4); // Pink for female
      default:
        return Color(0xFFAA6B94); // Default app theme color
    }
  }
}
