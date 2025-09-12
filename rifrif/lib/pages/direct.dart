import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';
import '../services/presentation_service.dart';

class DirectPage extends StatefulWidget {
  const DirectPage({Key? key}) : super(key: key);

  @override
  _DirectPageState createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isLive = false;
  String _errorMessage = '';

  // Question submission
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmittingQuestion = false;

  // Update with your Windows machine's IP address
  final String _streamUrl =
      'http://192.168.100.11:8888/live/RIFLIVE/index.m3u8';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingQuestion = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to ask questions');
      }

      // Get smart presentation title based on current time
      final smartPresentationTitle =
          await PresentationService.getSmartPresentationTitle();

      // Create question document
      final questionData = {
        'questionText': _questionController.text.trim(),
        'authorName': user.displayName ?? 'Anonymous',
        'authorEmail': user.email ?? '',
        'presentationTitle': smartPresentationTitle,
        'presentationId':
            smartPresentationTitle.toLowerCase().replaceAll(' ', '_'),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isAnswered': false,
        'answer': null,
        'answeredAt': null,
        'submittedVia':
            'Live Stream', // Track that this was submitted via live stream
      };

      await FirebaseFirestore.instance
          .collection('questions')
          .add(questionData);

      _questionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(smartPresentationTitle != 'Live Stream'
              ? 'Question submitted to: $smartPresentationTitle'
              : 'Question submitted and will be auto-assigned'),
          backgroundColor: Color(0xFFAA6B94),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit question: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingQuestion = false;
      });
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('Attempting to connect to stream: $_streamUrl');

      // Dispose previous controllers if they exist
      _chewieController?.dispose();
      _videoPlayerController?.dispose();

      _videoPlayerController = VideoPlayerController.network(
        _streamUrl,
        httpHeaders: {
          'User-Agent': 'RIF Flutter App',
        },
      );

      // Add timeout for initialization
      await _videoPlayerController!.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - stream may not be available');
        },
      );

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowedScreenSleep: false,
          showControlsOnInitialize: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: Color(0xFFAA6B94),
            handleColor: Color(0xFFAA6B94),
            backgroundColor: Colors.grey,
            bufferedColor: Color(0xFFAA6B94).withOpacity(0.5),
          ),
          errorBuilder: (context, errorMessage) {
            print('Chewie error: $errorMessage');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Stream Error',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        _isLoading = false;
        _isLive = true;
      });
      print('Stream initialized successfully');
    } catch (e) {
      print('Error initializing stream: $e');
      setState(() {
        _isLoading = false;
        _isLive = false;
        _errorMessage =
            'Failed to load stream: ${e.toString()}\n\nMake sure OBS is streaming to:\nrtmp://192.168.100.11:1935/live/RIFLIVE\n\nStream may need a few seconds to start after OBS begins streaming.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Conference Stream',
          style: TextStyle(
            color: Color(0xFFAA6B94),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFAA6B94)),
            onPressed: _initializePlayer,
            tooltip: 'Refresh Stream',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Stream Section
            _buildStreamSection(),

            // Questions and Interaction Section
            _buildInteractionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamSection() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 250, // Fixed height for the video player
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              _buildStreamContent(),
              // Live indicator
              if (_isLive)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFAA6B94),
            ),
            SizedBox(height: 16),
            Text(
              'Connecting to live stream...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text(
              'Stream Unavailable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Stream is currently offline',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _initializePlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFAA6B94),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Center(
      child: Text(
        'Initializing stream...',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildInteractionSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Icon(Icons.question_answer, color: Color(0xFFAA6B94)),
              SizedBox(width: 8),
              Text(
                'Live Q&A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Question Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isLive
                  ? Color(0xFFAA6B94).withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLive
                    ? Color(0xFFAA6B94).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isLive ? Icons.live_help : Icons.help_outline,
                      color: _isLive ? Color(0xFFAA6B94) : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLive
                            ? 'Ask a Question'
                            : 'Questions Available During Live Stream',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isLive ? Color(0xFFAA6B94) : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                if (!_isLive) ...[
                  SizedBox(height: 8),
                  Text(
                    'Questions can only be submitted when the live stream is active.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                SizedBox(height: 12),
                TextField(
                  controller: _questionController,
                  enabled: _isLive,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _isLive
                        ? 'Type your question here...'
                        : 'Questions disabled - stream not active',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _isLive
                            ? Color(0xFFAA6B94).withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _isLive ? Color(0xFFAA6B94) : Colors.grey,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: _isLive ? Colors.white : Colors.grey[100],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSubmittingQuestion || !_isLive)
                            ? null
                            : _submitQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isLive ? Color(0xFFAA6B94) : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmittingQuestion
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Submitting...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isLive ? Icons.send : Icons.block,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(_isLive
                                      ? 'Submit Question'
                                      : 'Stream Required'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Stream Info Section
          _buildStreamInfo(),
        ],
      ),
    );
  }

  Widget _buildStreamInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFAA6B94).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFAA6B94).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFAA6B94)),
              SizedBox(width: 8),
              Text(
                'Stream Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoRow(
              'Conference', 'RIF 2025 - Women in Computer Science Research'),
          _buildInfoRow('Status', _isLive ? 'Live' : 'Offline'),
          _buildInfoRow('Quality', '720p HD'),
          _buildInfoRow('Viewers', '125+ participants'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAA6B94),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _questionController.dispose();
    super.dispose();
  }
}
