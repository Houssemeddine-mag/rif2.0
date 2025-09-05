class Conference {
  final String title;
  final String presenter;
  final String affiliation;
  final String start;
  final String end;
  final String? resume;
  final bool isKeynote;

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
