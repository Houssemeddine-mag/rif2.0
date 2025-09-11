/// Enhanced Rating System for Individual User Ratings
/// This model supports multiple user ratings per presentation

import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual user rating for a specific presentation
class UserRating {
  final String id;
  final String userId;
  final String userEmail;
  final String presentationId;
  final String conferenceTitle;
  final String presenter;
  final String startTime;
  final String date;
  final double presenterRating;
  final double presentationRating;
  final String comment;
  final DateTime ratedAt;
  final DateTime updatedAt;

  UserRating({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.presentationId,
    required this.conferenceTitle,
    required this.presenter,
    required this.startTime,
    required this.date,
    required this.presenterRating,
    required this.presentationRating,
    required this.comment,
    required this.ratedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'presentationId': presentationId,
      'conferenceTitle': conferenceTitle,
      'presenter': presenter,
      'startTime': startTime,
      'date': date,
      'presenterRating': presenterRating,
      'presentationRating': presentationRating,
      'comment': comment,
      'ratedAt': Timestamp.fromDate(ratedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserRating.fromMap(String id, Map<String, dynamic> map) {
    return UserRating(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      presentationId: map['presentationId'] ?? '',
      conferenceTitle: map['conferenceTitle'] ?? '',
      presenter: map['presenter'] ?? '',
      startTime: map['startTime'] ?? '',
      date: map['date'] ?? '',
      presenterRating: (map['presenterRating'] ?? 0.0).toDouble(),
      presentationRating: (map['presentationRating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      ratedAt: (map['ratedAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Generate unique presentation ID based on conference details
  static String generatePresentationId(
      String conferenceTitle, String presenter, String startTime, String date) {
    return '${conferenceTitle}_${presenter}_${startTime}_$date'
        .replaceAll(' ', '_')
        .toLowerCase();
  }
}

/// Aggregated analytics for a presentation
class PresentationAnalytics {
  final String presentationId;
  final String conferenceTitle;
  final String presenter;
  final String startTime;
  final String date;
  final double averagePresenterRating;
  final double averagePresentationRating;
  final int totalRatings;
  final int totalComments;
  final Map<String, int> presenterRatingDistribution;
  final Map<String, int> presentationRatingDistribution;
  final DateTime lastUpdated;

  PresentationAnalytics({
    required this.presentationId,
    required this.conferenceTitle,
    required this.presenter,
    required this.startTime,
    required this.date,
    required this.averagePresenterRating,
    required this.averagePresentationRating,
    required this.totalRatings,
    required this.totalComments,
    required this.presenterRatingDistribution,
    required this.presentationRatingDistribution,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'presentationId': presentationId,
      'conferenceTitle': conferenceTitle,
      'presenter': presenter,
      'startTime': startTime,
      'date': date,
      'averagePresenterRating': averagePresenterRating,
      'averagePresentationRating': averagePresentationRating,
      'totalRatings': totalRatings,
      'totalComments': totalComments,
      'presenterRatingDistribution': presenterRatingDistribution,
      'presentationRatingDistribution': presentationRatingDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory PresentationAnalytics.fromMap(Map<String, dynamic> map) {
    return PresentationAnalytics(
      presentationId: map['presentationId'] ?? '',
      conferenceTitle: map['conferenceTitle'] ?? '',
      presenter: map['presenter'] ?? '',
      startTime: map['startTime'] ?? '',
      date: map['date'] ?? '',
      averagePresenterRating: (map['averagePresenterRating'] ?? 0.0).toDouble(),
      averagePresentationRating:
          (map['averagePresentationRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
      presenterRatingDistribution:
          Map<String, int>.from(map['presenterRatingDistribution'] ?? {}),
      presentationRatingDistribution:
          Map<String, int>.from(map['presentationRatingDistribution'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
