import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/program_model.dart';
import 'program.dart';

class HomePage extends StatefulWidget {
  final String userRole; // 'user' or 'organizer'
  final VoidCallback? onNavigateToProgram; // Optional callback for navigation
  const HomePage({Key? key, required this.userRole, this.onNavigateToProgram})
      : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime ceremonyDate = DateTime(
    2025,
    12,
    8,
    9,
    0,
  ); // Default date, will be updated from Firebase
  Duration remaining = Duration();
  Timer? countdownTimer;
  String conferenceStartDate =
      "8-9 Décembre 2025"; // Will be updated from Firebase

  // Firebase data
  List<ProgramSession> upcomingEvents = [];
  List<ProgramSession> allPrograms = [];
  Map<String, int> programStats = {
    'totalSessions': 0,
    'totalConferences': 0,
    'totalSpeakers': 0,
    'keynoteSessions': 0,
  };
  bool isLoading = true;
  StreamSubscription<List<ProgramSession>>? _programsSubscription;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadFirebaseData();
  }

  void _loadFirebaseData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load all programs and statistics in parallel
      final futures = await Future.wait([
        FirebaseService.getAllPrograms(),
        FirebaseService.getProgramStatistics(),
      ]);

      final allProgramsList = futures[0] as List<ProgramSession>;
      final stats = futures[1] as Map<String, int>;

      // Calculate ceremony date and conference dates from program data
      _updateDatesFromPrograms(allProgramsList);

      // Get upcoming events
      final upcoming =
          allProgramsList.where((p) => p.isUpcoming).take(3).toList();

      setState(() {
        allPrograms = allProgramsList;
        upcomingEvents = upcoming;
        programStats = stats;
        isLoading = false;
      });

      // Restart countdown with new ceremony date
      _startCountdown();

      // Set up real-time listener for ongoing updates
      _programsSubscription = FirebaseService.getProgramsStream().listen(
        (programs) {
          if (mounted) {
            // Update dates when program data changes
            _updateDatesFromPrograms(programs);

            final upcoming =
                programs.where((p) => p.isUpcoming).take(3).toList();

            setState(() {
              allPrograms = programs;
              upcomingEvents = upcoming;
            });

            // Restart countdown if ceremony date changed
            _startCountdown();
          }
        },
        onError: (error) {
          print('Error in programs stream: $error');
        },
      );
    } catch (e) {
      print('Error loading Firebase data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateDatesFromPrograms(List<ProgramSession> programs) {
    if (programs.isEmpty) {
      // When no programs are available, set default values
      setState(() {
        conferenceStartDate = "Bientôt";
      });
      return;
    }

    try {
      // Sort programs by date and start time to find the first session
      List<ProgramSession> sortedPrograms = List.from(programs);
      sortedPrograms.sort((a, b) {
        int dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        return a.start.compareTo(b.start);
      });

      if (sortedPrograms.isNotEmpty) {
        final firstSession = sortedPrograms.first;

        // Parse the first session date and time
        final sessionDate = DateTime.parse(firstSession.date);
        final startTimeParts = firstSession.start.split(':');

        if (startTimeParts.length >= 2) {
          final hour = int.tryParse(startTimeParts[0]) ?? 9;
          final minute = int.tryParse(startTimeParts[1]) ?? 0;

          // Update ceremony date to the first session's date and time
          ceremonyDate = DateTime(
            sessionDate.year,
            sessionDate.month,
            sessionDate.day,
            hour,
            minute,
          );
        }

        // Calculate conference date range
        List<DateTime> uniqueDates = programs
            .map((p) {
              try {
                return DateTime.parse(p.date);
              } catch (e) {
                return null;
              }
            })
            .where((date) => date != null)
            .cast<DateTime>()
            .toSet()
            .toList();

        uniqueDates.sort();

        if (uniqueDates.isNotEmpty) {
          if (uniqueDates.length == 1) {
            // Single day conference
            conferenceStartDate = _formatConferenceDate(uniqueDates.first);
          } else {
            // Multi-day conference
            final startDate = uniqueDates.first;
            final endDate = uniqueDates.last;
            conferenceStartDate =
                "${_formatConferenceDate(startDate)} - ${_formatConferenceDate(endDate)}";
          }
        } else {
          conferenceStartDate = "Bientôt";
        }
      } else {
        conferenceStartDate = "Bientôt";
      }
    } catch (e) {
      print('Error updating dates from programs: $e');
      setState(() {
        conferenceStartDate = "Bientôt";
      });
    }
  }

  String _formatConferenceDate(DateTime date) {
    final months = [
      '',
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

    return "${date.day} ${months[date.month]} ${date.year}";
  }

  void _startCountdown() {
    // Cancel existing timer if any
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          remaining = ceremonyDate.difference(DateTime.now());
          if (remaining.isNegative) {
            countdownTimer?.cancel();
            remaining = Duration.zero;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _programsSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) {
      return "00j 00h 00m 00s";
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inDays)}j ${twoDigits(d.inHours % 24)}h ${twoDigits(d.inMinutes % 60)}m ${twoDigits(d.inSeconds % 60)}s";
  }

  String _getCountdownText() {
    // Check if we have valid program data
    if (conferenceStartDate == "Bientôt" || allPrograms.isEmpty) {
      return "Dates à confirmer - Bientôt";
    }

    // Check if conference is ongoing or has passed
    if (remaining.isNegative || remaining == Duration.zero) {
      return "La conférence est en cours!";
    }

    // Normal countdown
    return "Début dans: ${_formatDuration(remaining)}";
  }

  String _getParticipantText() {
    final speakerCount = programStats['totalSpeakers'] ?? 0;
    if (speakerCount == 0 || allPrograms.isEmpty) {
      return "Participants - Bientôt";
    }
    return "$speakerCount+ Participantes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFAA6B94), Color(0xFFC87BAA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Conférence Internationale RIF 2025",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "La Recherche en Informatique au Féminin - Constantine, Algérie",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _iconText(Icons.calendar_today, conferenceStartDate),
                      _iconText(Icons.location_on, "Université Constantine 2"),
                      _iconText(Icons.people, _getParticipantText()),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _getCountdownText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(programStats['totalConferences']?.toString() ?? "0",
                    "Conférences"),
                _statCard(programStats['totalSpeakers']?.toString() ?? "0",
                    "Intervenantes"),
                _statCard(programStats['keynoteSessions']?.toString() ?? "0",
                    "Keynotes"),
              ],
            ),

            SizedBox(height: 20),

            // Upcoming Events
            Text(
              "Prochaines Sessions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            isLoading
                ? Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFAA6B94),
                      ),
                    ),
                  )
                : upcomingEvents.isEmpty
                    ? Container(
                        height: 150,
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: Color(0xFFEACBE5),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Color(0xFFAA6B94),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Aucune session à venir",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFAA6B94),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Consultez le programme complet",
                                  style: TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: upcomingEvents.map((event) {
                          return _buildEventCard(event);
                        }).toList(),
                      ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Use callback if provided, otherwise navigate directly
                  if (widget.onNavigateToProgram != null) {
                    widget.onNavigateToProgram!();
                  } else {
                    // Fallback: Navigate directly to ProgramPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProgramPage()),
                    );
                  }
                },
                child: Text("Voir le programme complet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFAA6B94),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 20),

            // About Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "La Conférence Internationale sur la Recherche en Informatique au Féminin (RIF) réunit chercheuses, ingénieures et praticiennes en informatique. RIF favorise la collaboration et l'innovation, avec un focus sur les technologies émergentes. L'édition 2025 met l'accent sur les contributions des femmes à l'intelligence artificielle, invitant des recherches originales et des travaux pratiques en informatique, à travers des articles réguliers ou courts, et offre une participation hybride pour une accessibilité élargie.",
                  style: TextStyle(color: Colors.black87, height: 1.4),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Organizer Mode
            if (widget.userRole == 'organizer')
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mode Organisateur",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAA6B94),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _organizerButton("Gérer les Notifications"),
                          _organizerButton("Voir les Évaluations"),
                          _organizerButton("Gérer le Chat Live"),
                          _organizerButton("Analytics Dashboard"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Card(
        color: Color(0xFFFDFDFD),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
              SizedBox(height: 4),
              Text(label, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(ProgramSession event) {
    // Get the main speaker (keynote speaker or first conference speaker)
    String mainSpeaker = "Intervenant non défini";
    Widget? speakerImage;

    if (event.keynote != null && event.keynote!.name.isNotEmpty) {
      mainSpeaker = event.keynote!.name;
      if (event.keynote!.image.isNotEmpty) {
        speakerImage = _getImageFromBase64(event.keynote!.image, 40);
      }
    } else if (event.conferences.isNotEmpty &&
        event.conferences.first.presenter.isNotEmpty) {
      mainSpeaker = event.conferences.first.presenter;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Color(0xFFEACBE5),
      child: ListTile(
        leading: speakerImage != null
            ? Container(
                width: 50,
                height: 50,
                child: ClipOval(child: speakerImage),
              )
            : CircleAvatar(
                backgroundColor: Color(0xFFAA6B94),
                child: Icon(Icons.person, color: Colors.white),
              ),
        title: Text(
          event.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Par $mainSpeaker"),
            Text("${event.start}${event.end != null ? ' - ${event.end}' : ''}"),
            if (event.date.isNotEmpty)
              Text(
                _formatDate(event.date),
                style: TextStyle(
                  color: Color(0xFFAA6B94),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Use callback if provided, otherwise navigate directly
          if (widget.onNavigateToProgram != null) {
            widget.onNavigateToProgram!();
          } else {
            // Fallback: Navigate directly to ProgramPage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProgramPage()),
            );
          }
        },
      ),
    );
  }

  Widget? _getImageFromBase64(String base64String, double size) {
    try {
      if (base64String.isEmpty) return null;

      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      final Uint8List bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person, size: size);
        },
      );
    } catch (e) {
      print('Error loading image from base64: $e');
      return null;
    }
  }

  String _formatDate(String dateString) {
    try {
      // Assuming date format is YYYY-MM-DD
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final day = parts[2];
        final month = parts[1];
        final monthNames = [
          '',
          'Jan',
          'Fév',
          'Mar',
          'Avr',
          'Mai',
          'Jun',
          'Jul',
          'Aoû',
          'Sep',
          'Oct',
          'Nov',
          'Déc'
        ];
        final monthName =
            int.parse(month) <= 12 ? monthNames[int.parse(month)] : month;
        return "$day $monthName";
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Widget _organizerButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(label, style: TextStyle(color: Color(0xFFAA6B94))),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFEACBE5),
        foregroundColor: Color(0xFFAA6B94),
      ),
    );
  }
}
