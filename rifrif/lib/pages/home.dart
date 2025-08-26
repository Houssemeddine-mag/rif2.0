import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String userRole; // 'user' or 'organizer'
  const HomePage({Key? key, required this.userRole}) : super(key: key);

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
  ); // set by admin in real app
  Duration remaining = Duration();
  Timer? countdownTimer;

  List<Map<String, String>> upcomingEvents = [
    {
      "title": "Intelligence Artificielle et Genre",
      "speaker": "Dr. Sarah Benali",
      "time": "09:00 - 10:30",
      "location": "Amphithéâtre A",
      "type": "Conférence Plénière",
    },
    {
      "title": "Réseaux de Neurones en Traitement d'Images",
      "speaker": "Prof. Amina Kheddar",
      "time": "11:00 - 12:00",
      "location": "Salle 101",
      "type": "Présentation",
    },
    {
      "title": "Table Ronde: Femmes en Tech",
      "speaker": "Panel d'expertes",
      "time": "14:00 - 15:30",
      "location": "Grand Amphithéâtre",
      "type": "Table Ronde",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        remaining = ceremonyDate.difference(DateTime.now());
        if (remaining.isNegative) countdownTimer?.cancel();
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inDays)}j ${twoDigits(d.inHours % 24)}h ${twoDigits(d.inMinutes % 60)}m ${twoDigits(d.inSeconds % 60)}s";
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
                      _iconText(Icons.calendar_today, "8-9 Décembre 2025"),
                      _iconText(Icons.location_on, "Université Constantine 2"),
                      _iconText(Icons.people, "500+ Participantes"),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Début dans: ${_formatDuration(remaining)}",
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
                _statCard("45", "Conférences"),
                _statCard("120", "Intervenantes"),
                _statCard("12", "Pays Représentés"),
              ],
            ),

            SizedBox(height: 20),

            // Upcoming Events
            Text(
              "Prochaines Sessions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Column(
              children: upcomingEvents.map((event) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  color: Color(0xFFEACBE5),
                  child: ListTile(
                    title: Text(
                      event["title"]!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Par ${event["speaker"]}"),
                        Text("${event["time"]} | ${event["location"]}"),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/program');
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
