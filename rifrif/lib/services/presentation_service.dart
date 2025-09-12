import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program_model.dart';

class PresentationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find the currently active presentation based on the current date and time
  static Future<Conference?> getCurrentActivePresentation() async {
    try {
      final now = DateTime.now();

      // Get all program sessions
      final programSnapshot =
          await _firestore.collection('programs').orderBy('date').get();

      for (var doc in programSnapshot.docs) {
        final data = doc.data();
        final programSession = ProgramSession.fromMap(doc.id, data);

        try {
          // Parse the program date
          final sessionDate = DateTime.parse(programSession.date);

          // Check if it's the same day as today
          if (sessionDate.year == now.year &&
              sessionDate.month == now.month &&
              sessionDate.day == now.day) {
            // Check each conference in this session
            for (var conference in programSession.conferences) {
              if (await _isConferenceActiveNow(conference, sessionDate)) {
                return conference;
              }
            }
          }
        } catch (e) {
          print('Error parsing session date ${programSession.date}: $e');
          continue;
        }
      }

      return null; // No active presentation found
    } catch (e) {
      print('Error finding active presentation: $e');
      return null;
    }
  }

  /// Check if a specific conference is currently active
  static Future<bool> _isConferenceActiveNow(
      Conference conference, DateTime sessionDate) async {
    try {
      final now = DateTime.now();

      // Parse conference start and end times
      final startTimeParts = conference.start.split(':');
      final endTimeParts = conference.end.split(':');

      final startTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final endTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      // Check if current time falls within this presentation's time slot
      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (e) {
      print('Error checking conference time for ${conference.title}: $e');
      return false;
    }
  }

  /// Find which presentation was active at a specific timestamp
  static Future<Conference?> findPresentationByTimestamp(
      DateTime questionTime) async {
    try {
      // Get all program sessions
      final programSnapshot =
          await _firestore.collection('programs').orderBy('date').get();

      for (var doc in programSnapshot.docs) {
        final data = doc.data();
        final programSession = ProgramSession.fromMap(doc.id, data);

        try {
          final sessionDate = DateTime.parse(programSession.date);

          // Check if the question time is on the same day as this session
          if (sessionDate.year == questionTime.year &&
              sessionDate.month == questionTime.month &&
              sessionDate.day == questionTime.day) {
            // Check each conference in this session
            for (var conference in programSession.conferences) {
              final startTimeParts = conference.start.split(':');
              final endTimeParts = conference.end.split(':');

              final startTime = DateTime(
                sessionDate.year,
                sessionDate.month,
                sessionDate.day,
                int.parse(startTimeParts[0]),
                int.parse(startTimeParts[1]),
              );

              final endTime = DateTime(
                sessionDate.year,
                sessionDate.month,
                sessionDate.day,
                int.parse(endTimeParts[0]),
                int.parse(endTimeParts[1]),
              );

              // Check if question was posted during this presentation
              if (questionTime.isAfter(startTime) &&
                  questionTime.isBefore(endTime)) {
                return conference;
              }
            }
          }
        } catch (e) {
          print(
              'Error parsing session for timestamp ${programSession.date}: $e');
          continue;
        }
      }

      return null;
    } catch (e) {
      print('Error finding presentation by timestamp: $e');
      return null;
    }
  }

  /// Auto-assign unassigned questions to correct presentations based on timestamp
  static Future<int> autoAssignQuestionsToPresentation() async {
    try {
      int assignedCount = 0;

      // Get all unassigned questions (those without proper presentationTitle)
      final unassignedSnapshot = await _firestore
          .collection('questions')
          .where('presentationTitle', whereIn: ['', 'Live Stream'])
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in unassignedSnapshot.docs) {
        final questionData = doc.data();
        final questionTimestamp =
            DateTime.fromMillisecondsSinceEpoch(questionData['timestamp'] ?? 0);

        // Find which presentation was active when this question was posted
        final assignedPresentation =
            await findPresentationByTimestamp(questionTimestamp);

        if (assignedPresentation != null) {
          // Update the question with the correct presentation title
          await _firestore.collection('questions').doc(doc.id).update({
            'presentationTitle': assignedPresentation.title,
            'autoAssigned': true,
            'assignedAt': Timestamp.now(),
            'originalPresentationTitle': questionData[
                'presentationTitle'], // Keep original for debugging
          });

          assignedCount++;
          print('Auto-assigned question to: ${assignedPresentation.title}');
        }
      }

      return assignedCount;
    } catch (e) {
      print('Error auto-assigning questions: $e');
      return 0;
    }
  }

  /// Get smart presentation title for new question submission
  static Future<String> getSmartPresentationTitle() async {
    try {
      // First, try to get the currently active presentation
      final activePresentation = await getCurrentActivePresentation();
      if (activePresentation != null) {
        return activePresentation.title;
      }

      // If no active presentation, return a generic title that can be auto-assigned later
      return 'Live Stream';
    } catch (e) {
      print('Error getting smart presentation title: $e');
      return 'Live Stream';
    }
  }
}
