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
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF614f96),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          speaker['name'] ?? 'Unknown Speaker',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speaker image
                        if (speaker['imageData'] != null &&
                            speaker['imageData'].isNotEmpty)
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF614f96),
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildSpeakerImage(speaker['imageData']),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Speaker details
                        Text(
                          'Title: ${speaker['title'] ?? 'Not specified'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Institution: ${speaker['institution'] ?? 'Not specified'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Biography
                        const Text(
                          'Biography:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF614f96),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          speaker['biography'] ?? 'No biography available.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
