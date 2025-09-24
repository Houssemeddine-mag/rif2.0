import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
      "December 8-9, 2025"; // Will be updated from Firebase

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
        conferenceStartDate = "Coming Soon";
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
          conferenceStartDate = "Coming Soon";
        }
      } else {
        conferenceStartDate = "Coming Soon";
      }
    } catch (e) {
      print('Error updating dates from programs: $e');
      setState(() {
        conferenceStartDate = "Coming Soon";
      });
    }
  }

  String _formatConferenceDate(DateTime date) {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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
    if (conferenceStartDate == "Coming Soon" || allPrograms.isEmpty) {
      return "Dates to be confirmed - Coming soon";
    }

    // Check if conference is ongoing or has passed
    if (remaining.isNegative || remaining == Duration.zero) {
      return "The conference is in progress!";
    }

    // Normal countdown
    return "Starting in: ${_formatDuration(remaining)}";
  }

  String _getParticipantText() {
    final speakerCount = programStats['totalSpeakers'] ?? 0;
    if (speakerCount == 0 || allPrograms.isEmpty) {
      return "Participants - Coming Soon";
    }
    return "$speakerCount+ Participants";
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // Try different launch modes for better compatibility
      bool launched = false;

      // First try: External application (browser)
      if (await canLaunchUrl(uri)) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print('External application launch failed: $e');
        }
      }

      // Second try: Platform default (in-app browser)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      // Third try: In-app web view
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } catch (e) {
          print('In-app web view launch failed: $e');
        }
      }

      // If all methods failed, show error
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open link: $url'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Copy',
                textColor: Colors.white,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied to clipboard'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                image: DecorationImage(
                  image: AssetImage('lib/resource/constantine.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                      0.5), // Semi-transparent overlay for text readability
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sponsor logos at top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcATop,
                          ),
                          child: Image.asset(
                            'lib/resource/IEEE dz.png',
                            height: 50,
                            width: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcATop,
                          ),
                          child: Image.asset(
                            'lib/resource/IEEE.png',
                            height: 60,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcATop,
                          ),
                          child: Image.asset(
                            'lib/resource/LOGO_Univ2-removebg-preview.png',
                            height: 50,
                            width: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "The 14th International Conference on Research In ComputIng At Feminine",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _iconText(Icons.calendar_today, conferenceStartDate),
                        _iconText(
                            Icons.location_on, "Constantine University 2"),
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
            ),

            SizedBox(height: 20),

            // Quick Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(programStats['totalConferences']?.toString() ?? "0",
                    "Conferences"),
                _statCard(programStats['totalSpeakers']?.toString() ?? "0",
                    "Speakers"),
                _statCard(programStats['keynoteSessions']?.toString() ?? "0",
                    "Keynotes"),
              ],
            ),

            SizedBox(height: 20),

            // Upcoming Events
            Text(
              "Upcoming Sessions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            isLoading
                ? Container(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF614f96),
                      ),
                    ),
                  )
                : upcomingEvents.isEmpty
                    ? Container(
                        height: 150,
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: Color(0xFFE6DFF2),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Color(0xFF614f96),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "No upcoming sessions",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF614f96),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Check the full program",
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
                child: Text("View full program"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF614f96),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 20),

            // About Section
            Text(
              "About RIF 2025",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Color(0xFF614f96),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "The International Conference on Women in Computer Science Research (RIF) brings together researchers, engineers and practitioners in computer science. RIF promotes collaboration and innovation, with a focus on emerging technologies. The 2025 edition emphasizes women's contributions to artificial intelligence, inviting original research and practical work in computer science, through regular or short papers, and offers hybrid participation for broader accessibility.",
                      style: TextStyle(color: Colors.black87, height: 1.4),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchURL(
                                'https://www.univ-constantine2.dz/rif/25/'),
                            icon: Icon(Icons.web, size: 18),
                            label: Text("Visit website"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF614f96),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchURL(
                                'https://www.univ-constantine2.dz/rif/25/past-editions/'),
                            icon: Icon(Icons.history, size: 18),
                            label: Text("Past editions"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE6DFF2),
                              foregroundColor: Color(0xFF614f96),
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        "Organizer Mode",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF614f96),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _organizerButton("Manage Notifications"),
                          _organizerButton("View Evaluations"),
                          _organizerButton("Manage Live Chat"),
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
                  color: Color(0xFF614f96),
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
    String mainSpeaker = "Speaker not defined";
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
      color: Color(0xFFE6DFF2),
      child: ListTile(
        leading: speakerImage != null
            ? Container(
                width: 50,
                height: 50,
                child: ClipOval(child: speakerImage),
              )
            : CircleAvatar(
                backgroundColor: Color(0xFF614f96),
                child: Icon(Icons.person, color: Colors.white),
              ),
        title: Text(
          event.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("By $mainSpeaker"),
            Text("${event.start}${event.end != null ? ' - ${event.end}' : ''}"),
            if (event.date.isNotEmpty)
              Text(
                _formatDate(event.date),
                style: TextStyle(
                  color: Color(0xFF614f96),
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
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
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
      child: Text(label, style: TextStyle(color: Color(0xFF614f96))),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFE6DFF2),
        foregroundColor: Color(0xFF614f96),
      ),
    );
  }
}
