class Conference {
  final String title;
  final String presenter;
  final String affiliation;
  final String start;
  final String end;
  final String? resume;
  final bool isKeynote;
  // Legacy rating fields removed - now using individual user ratings

  Conference({
    required this.title,
    required this.presenter,
    required this.affiliation,
    required this.start,
    required this.end,
    this.resume,
    this.isKeynote = false,
  });

  factory Conference.fromMap(Map<String, dynamic> map) {
    return Conference(
      title: map['title'] ?? '',
      presenter: map['presenter'] ?? '',
      affiliation: map['affiliation'] ?? '',
      start: map['start'] ?? '',
      end: map['end'] ?? '',
      resume: map['resume'],
      isKeynote: map['isKeynote'] ?? false,
      // Legacy rating fields ignored - using individual user ratings now
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'presenter': presenter,
      'affiliation': affiliation,
      'start': start,
      'end': end,
      'resume': resume,
      'isKeynote': isKeynote,
      // Legacy rating fields removed - using individual user ratings now
    };
  }
}

class Keynote {
  final String name;
  final String affiliation;
  final String bio;
  final String image;

  Keynote({
    required this.name,
    required this.affiliation,
    required this.bio,
    required this.image,
  });

  factory Keynote.fromMap(Map<String, dynamic> map) {
    return Keynote(
      name: map['name'] ?? '',
      affiliation: map['affiliation'] ?? '',
      bio: map['bio'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'affiliation': affiliation,
      'bio': bio,
      'image': image,
    };
  }
}

class ProgramSession {
  final String id;
  final String type; // session, keynote, break, ceremony
  final String title;
  final String date;
  final String start;
  final String? end; // Made optional since not all sessions have end times
  final String? endDate; // End date for multi-day sessions
  final String? room; // Room where the session takes place
  final List<String> chairs;
  final Keynote? keynote;
  final String? keynoteDescription;
  final bool keynoteHasConference;
  final List<Conference> conferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProgramSession({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.start,
    this.end, // Made optional
    this.endDate, // Optional end date field
    this.room, // Optional room field
    required this.chairs,
    this.keynote,
    this.keynoteDescription,
    this.keynoteHasConference = false,
    required this.conferences,
    this.createdAt,
    this.updatedAt,
  });

  factory ProgramSession.fromMap(String id, Map<String, dynamic> map) {
    return ProgramSession(
      id: id,
      type: map['type'] ?? 'session',
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      start: map['start'] ?? '',
      end: map['end'], // Optional, can be null
      endDate: map['endDate'], // Optional end date field
      room: map['room'], // Optional room field
      chairs: List<String>.from(map['chairs'] ?? []),
      keynote: map['keynote'] != null ? Keynote.fromMap(map['keynote']) : null,
      keynoteDescription: map['keynoteDescription'],
      keynoteHasConference: map['keynoteHasConference'] ?? false,
      conferences: (map['conferences'] as List<dynamic>?)
              ?.map((conf) => Conference.fromMap(conf))
              .toList() ??
          [],
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  // Helper method to parse Firebase timestamp or string date
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      // Handle Firebase Timestamp objects
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        return timestamp.toDate();
      }

      // Handle string dates
      if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }

      // Handle milliseconds since epoch
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'date': date,
      'start': start,
      'end': end,
      'endDate': endDate,
      'room': room,
      'chairs': chairs,
      'keynote': keynote?.toMap(),
      'keynoteDescription': keynoteDescription,
      'keynoteHasConference': keynoteHasConference,
      'conferences': conferences.map((conf) => conf.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get all speakers for this session
  List<String> get allSpeakers {
    List<String> speakers = [];

    // Add keynote speaker if exists
    if (keynote != null) {
      speakers.add(keynote!.name);
    }

    // Add conference presenters
    for (var conference in conferences) {
      if (!speakers.contains(conference.presenter)) {
        speakers.add(conference.presenter);
      }
    }

    return speakers;
  }

  // Helper method to check if session is today
  bool get isToday {
    try {
      final sessionDate = DateTime.parse(date);
      final today = DateTime.now();
      return sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if session is upcoming (today or future)
  bool get isUpcoming {
    try {
      final sessionDate = DateTime.parse(date);
      final today = DateTime.now();
      return sessionDate.isAfter(today.subtract(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if session has finished
  bool get hasFinished {
    try {
      final now = DateTime.now();

      // Determine the actual end date (use endDate if provided, otherwise use date)
      final actualEndDate = endDate != null && endDate!.isNotEmpty
          ? DateTime.parse(endDate!)
          : DateTime.parse(date);

      // If we have an end time, check against it
      if (end != null && end!.isNotEmpty) {
        final endTimeParts = end!.split(':');
        final endDateTime = DateTime(
          actualEndDate.year,
          actualEndDate.month,
          actualEndDate.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );
        return now.isAfter(endDateTime);
      }

      // If no end time, just check if the end date has passed
      return now.isAfter(actualEndDate.add(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  // Helper method to get remaining time until session ends
  Duration? get timeUntilEnd {
    try {
      final now = DateTime.now();

      // Determine the actual end date
      final actualEndDate = endDate != null && endDate!.isNotEmpty
          ? DateTime.parse(endDate!)
          : DateTime.parse(date);

      // If we have an end time, calculate exact duration
      if (end != null && end!.isNotEmpty) {
        final endTimeParts = end!.split(':');
        final endDateTime = DateTime(
          actualEndDate.year,
          actualEndDate.month,
          actualEndDate.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );

        if (now.isBefore(endDateTime)) {
          return endDateTime.difference(now);
        }
        return null; // Already finished
      }

      // If no end time, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to get status string
  String get sessionStatus {
    if (hasFinished) {
      return 'Finished';
    }

    final timeLeft = timeUntilEnd;
    if (timeLeft != null) {
      final hours = timeLeft.inHours;
      final minutes = timeLeft.inMinutes.remainder(60);

      if (hours > 24) {
        final days = hours ~/ 24;
        return 'Ends in $days day${days > 1 ? 's' : ''}';
      } else if (hours > 0) {
        return 'Ends in ${hours}h ${minutes}m';
      } else if (minutes > 0) {
        return 'Ends in ${minutes}m';
      } else {
        return 'Ending soon';
      }
    }

    return 'In progress';
  }

  // Helper method to format date for display
  String get formattedDate {
    try {
      final sessionDate = DateTime.parse(date);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
      ];
      final weekdays = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche'
      ];

      return '${weekdays[sessionDate.weekday - 1]} ${sessionDate.day} ${months[sessionDate.month - 1]} ${sessionDate.year}';
    } catch (e) {
      return date;
    }
  }
}
