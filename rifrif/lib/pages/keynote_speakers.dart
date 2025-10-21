import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class KeynoteSpeakersPage extends StatefulWidget {
  const KeynoteSpeakersPage({super.key});

  @override
  State<KeynoteSpeakersPage> createState() => _KeynoteSpeakersPageState();
}

class _KeynoteSpeakersPageState extends State<KeynoteSpeakersPage> {
  List<Map<String, dynamic>> speakers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadKeynoteSpeakers();
  }

  Future<void> loadKeynoteSpeakers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('keynote_speakers')
          .orderBy('order', descending: false)
          .get();

      setState(() {
        speakers = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading speakers: $e')),
        );
      }
    }
  }

  Widget _buildSpeakerImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }

    try {
      // Remove the data URL prefix if present (data:image/jpeg;base64,)
      String base64String = imageData;
      if (imageData.contains(',')) {
        base64String = imageData.split(',')[1];
      }

      final Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
  }

  void _showBioDialog(BuildContext context, Map<String, dynamic> speaker) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main Card Content (positioned below the image)
              Container(
                margin: const EdgeInsets.only(top: 80), // Lowered the card more
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button in top right corner
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Space for the overlapping image
                    const SizedBox(height: 35),

                    // Speaker Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        speaker['name'] ?? 'Unknown Speaker',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2d2d2d),
                          letterSpacing: 0.5,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Title
                    if (speaker['title'] != null && speaker['title'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF614f96).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                size: 16,
                                color: const Color(0xFF614f96),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                speaker['title'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.3,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Institution
                    if (speaker['institution'] != null &&
                        speaker['institution'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF614f96).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 16,
                                color: const Color(0xFF614f96),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                speaker['institution'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.3,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Elegant Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        height: 0.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.grey.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Biography section
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF614f96)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: const Color(0xFF614f96),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF614f96),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Biography text
                            Text(
                              speaker['biography'] ?? 'No biography available.',
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.8,
                                color: Colors.grey[800],
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.left,
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Picture - Positioned half outside, half inside
              Positioned(
                top: 10, // Lowered from 0 to 10
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF614f96).withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF614f96).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: speaker['imageData'] != null &&
                                speaker['imageData'].isNotEmpty
                            ? _buildSpeakerImage(speaker['imageData'])
                            : Container(
                                color:
                                    const Color(0xFF614f96).withOpacity(0.08),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 70,
                                  color: Color(0xFF614f96),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keynote Speakers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF614f96),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF614f96),
              ),
            )
          : speakers.isEmpty
              ? const Center(
                  child: Text(
                    'No keynote speakers available yet.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF614f96),
                  onRefresh: loadKeynoteSpeakers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: speakers.length,
                    itemBuilder: (context, index) {
                      final speaker = speakers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              const Color(0xFF614f96).withOpacity(0.08),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Profile Picture - Centered and larger
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF614f96),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF614f96)
                                          .withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child:
                                      _buildSpeakerImage(speaker['imageData']),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Speaker Name - Centered and prominent
                              Text(
                                speaker['name'] ?? 'Unknown Speaker',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF614f96),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Title - Centered
                              if (speaker['title'] != null &&
                                  speaker['title'].isNotEmpty)
                                Text(
                                  speaker['title'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Institution - Centered
                              if (speaker['institution'] != null &&
                                  speaker['institution'].isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF614f96)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    speaker['institution'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF614f96),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // Bio Button - Centered and styled
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showBioDialog(context, speaker),
                                icon: const Icon(Icons.person,
                                    color: Colors.white),
                                label: const Text(
                                  'Read Bio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF614f96),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      const Color(0xFF614f96).withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
