// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/question_model.dart';
// import '../services/presentation_service.dart';

// class DirectPage extends StatefulWidget {
//   const DirectPage({Key? key}) : super(key: key);

//   @override
//   _DirectPageState createState() => _DirectPageState();
// }

// class _DirectPageState extends State<DirectPage> {
//   VideoPlayerController? _videoPlayerController;
//   ChewieController? _chewieController;
//   bool _isLoading = true;
//   bool _isLive = false;
//   String _errorMessage = '';

//   // Question submission
//   final TextEditingController _questionController = TextEditingController();
//   bool _isSubmittingQuestion = false;

//   // Update with your Windows machine's IP address
//   final String _streamUrl =
//       'http://192.168.100.11:8888/live/RIFLIVE/index.m3u8';

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   Future<void> _submitQuestion() async {
//     if (_questionController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please enter a question'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmittingQuestion = true;
//     });

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception('You must be logged in to ask questions');
//       }

//       // Get smart presentation title based on current time
//       final smartPresentationTitle =
//           await PresentationService.getSmartPresentationTitle();

//       // Create question document
//       final questionData = {
//         'questionText': _questionController.text.trim(),
//         'authorName': user.displayName ?? 'Anonymous',
//         'authorEmail': user.email ?? '',
//         'presentationTitle': smartPresentationTitle,
//         'presentationId':
//             smartPresentationTitle.toLowerCase().replaceAll(' ', '_'),
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//         'isAnswered': false,
//         'answer': null,
//         'answeredAt': null,
//         'submittedVia':
//             'Live Stream', // Track that this was submitted via live stream
//       };

//       await FirebaseFirestore.instance
//           .collection('questions')
//           .add(questionData);

//       _questionController.clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(smartPresentationTitle != 'Live Stream'
//               ? 'Question submitted to: $smartPresentationTitle'
//               : 'Question submitted and will be auto-assigned'),
//           backgroundColor: Color(0xFF614f96),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to submit question: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSubmittingQuestion = false;
//       });
//     }
//   }

//   Future<void> _initializePlayer() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });

//       print('Attempting to connect to stream: $_streamUrl');

//       // Dispose previous controllers if they exist
//       _chewieController?.dispose();
//       _videoPlayerController?.dispose();

//       // ignore: deprecated_member_use
//       _videoPlayerController = VideoPlayerController.network(
//         _streamUrl,
//         httpHeaders: {
//           'User-Agent': 'RIF Flutter App',
//         },
//       );

//       // Add timeout for initialization
//       await _videoPlayerController!.initialize().timeout(
//         Duration(seconds: 10),
//         onTimeout: () {
//           throw Exception('Connection timeout - stream may not be available');
//         },
//       );

//       setState(() {
//         _chewieController = ChewieController(
//           videoPlayerController: _videoPlayerController!,
//           autoPlay: true,
//           looping: false,
//           allowFullScreen: true,
//           allowedScreenSleep: false,
//           showControlsOnInitialize: false,
//           materialProgressColors: ChewieProgressColors(
//             playedColor: Color(0xFF614f96),
//             handleColor: Color(0xFF614f96),
//             backgroundColor: Colors.grey,
//             bufferedColor: Color(0xFF614f96).withOpacity(0.5),
//           ),
//           errorBuilder: (context, errorMessage) {
//             print('Chewie error: $errorMessage');
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 48, color: Colors.red),
//                   SizedBox(height: 16),
//                   Text(
//                     'Stream Error',
//                     style: TextStyle(color: Colors.white, fontSize: 18),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     errorMessage,
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//         _isLoading = false;
//         _isLive = true;
//       });
//       print('Stream initialized successfully');
//     } catch (e) {
//       print('Error initializing stream: $e');
//       setState(() {
//         _isLoading = false;
//         _isLive = false;
//         _errorMessage =
//             'Failed to load stream: ${e.toString()}\n\nMake sure OBS is streaming to:\nrtmp://192.168.100.11:1935/live/RIFLIVE\n\nStream may need a few seconds to start after OBS begins streaming.';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Live Conference Stream',
//           style: TextStyle(
//             color: Color(0xFF614f96),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: Color(0xFF614f96)),
//             onPressed: _initializePlayer,
//             tooltip: 'Refresh Stream',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Live Stream Section
//             _buildStreamSection(),

//             // Questions and Interaction Section
//             _buildInteractionSection(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStreamSection() {
//     return Container(
//       margin: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           height: 250, // Fixed height for the video player
//           width: double.infinity,
//           color: Colors.black,
//           child: Stack(
//             children: [
//               _buildStreamContent(),
//               // Live indicator
//               if (_isLive)
//                 Positioned(
//                   top: 12,
//                   right: 12,
//                   child: Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 8,
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         SizedBox(width: 4),
//                         Text(
//                           'LIVE',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStreamContent() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Color(0xFF614f96),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Connecting to live stream...',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 48, color: Colors.red),
//             SizedBox(height: 12),
//             Text(
//               'Stream Unavailable',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 8),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 'Stream is currently offline',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.white70),
//               ),
//             ),
//             SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: _initializePlayer,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF614f96),
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//               child: Text('Retry', style: TextStyle(fontSize: 12)),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_chewieController != null) {
//       return Chewie(controller: _chewieController!);
//     }

//     return Center(
//       child: Text(
//         'Initializing stream...',
//         style: TextStyle(color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildInteractionSection() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Section Title
//           Row(
//             children: [
//               Icon(Icons.question_answer, color: Color(0xFF614f96)),
//               SizedBox(width: 8),
//               Text(
//                 'Live Q&A',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF614f96),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),

//           // Question Input Section
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: _isLive
//                   ? Color(0xFF614f96).withOpacity(0.05)
//                   : Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: _isLive
//                     ? Color(0xFF614f96).withOpacity(0.2)
//                     : Colors.grey.withOpacity(0.3),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       _isLive ? Icons.live_help : Icons.help_outline,
//                       color: _isLive ? Color(0xFF614f96) : Colors.grey,
//                       size: 20,
//                     ),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _isLive
//                             ? 'Ask a Question'
//                             : 'Questions Available During Live Stream',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: _isLive ? Color(0xFF614f96) : Colors.grey,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 2,
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (!_isLive) ...[
//                   SizedBox(height: 8),
//                   Text(
//                     'Questions can only be submitted when the live stream is active.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//                 SizedBox(height: 12),
//                 TextField(
//                   controller: _questionController,
//                   enabled: _isLive,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     hintText: _isLive
//                         ? 'Type your question here...'
//                         : 'Questions disabled - stream not active',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(
//                         color: _isLive
//                             ? Color(0xFF614f96).withOpacity(0.3)
//                             : Colors.grey.withOpacity(0.3),
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(
//                         color: _isLive ? Color(0xFF614f96) : Colors.grey,
//                       ),
//                     ),
//                     disabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide:
//                           BorderSide(color: Colors.grey.withOpacity(0.3)),
//                     ),
//                     filled: true,
//                     fillColor: _isLive ? Colors.white : Colors.grey[100],
//                   ),
//                 ),
//                 SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: (_isSubmittingQuestion || !_isLive)
//                             ? null
//                             : _submitQuestion,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               _isLive ? Color(0xFF614f96) : Colors.grey,
//                           foregroundColor: Colors.white,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: _isSubmittingQuestion
//                             ? Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   SizedBox(
//                                     width: 18,
//                                     height: 18,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.white),
//                                     ),
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text('Submitting...'),
//                                 ],
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     _isLive ? Icons.send : Icons.block,
//                                     size: 18,
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text(_isLive
//                                       ? 'Submit Question'
//                                       : 'Stream Required'),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: 20),

//           // Stream Info Section
//           _buildStreamInfo(),
//         ],
//       ),
//     );
//   }

//   Widget _buildStreamInfo() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Color(0xFF614f96).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Color(0xFF614f96).withOpacity(0.3),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Color(0xFF614f96)),
//               SizedBox(width: 8),
//               Text(
//                 'Stream Information',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF614f96),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           _buildInfoRow(
//               'Conference', 'RIF 2025 - Women in Computer Science Research'),
//           _buildInfoRow('Status', _isLive ? 'Live' : 'Offline'),
//           _buildInfoRow('Quality', '720p HD'),
//           _buildInfoRow('Viewers', '125+ participants'),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF614f96),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _chewieController?.dispose();
//     _videoPlayerController?.dispose();
//     _questionController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../services/presentation_service.dart';

class DirectPage extends StatefulWidget {
  const DirectPage({Key? key}) : super(key: key);

  @override
  _DirectPageState createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isLive = false;
  String _errorMessage = '';

  // Stream monitoring variables
  Timer? _streamCheckTimer;
  Timer? _healthMonitorTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  final int _maxRetries = 5;
  DateTime? _lastPositionUpdate;
  Duration? _lastPosition;
  bool _isRecovering = false;

  // Question submission
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmittingQuestion = false;

  // Stream URLs
  final String _streamUrl =
      'http://192.168.100.11:8888/live/RIFLIVE/index.m3u8';
  final String _streamStatusUrl = 'http://192.168.100.11:9997/v2/paths/list';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStreamAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLive) {
      // App came to foreground, try to recover
      _restartPlayer();
    }
  }

  // Check if stream is available before initializing player
  Future<void> _checkStreamAvailability() async {
    try {
      final response = await http
          .get(Uri.parse(_streamStatusUrl))
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paths = data['items'] as List<dynamic>;

        // Check if our stream path is active
        final isStreamActive = paths
            .any((path) => path['name'] == 'RIFLIVE' && path['ready'] == true);

        if (isStreamActive) {
          _initializePlayer();
        } else {
          _startStreamMonitoring();
        }
      }
    } catch (e) {
      // If status check fails, try direct initialization
      _startStreamMonitoring();
    }
  }

  void _startStreamMonitoring() {
    _streamCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _checkStreamAvailability();
    });
  }

  Future<void> _initializePlayer() async {
    try {
      // Cancel monitoring timer
      _streamCheckTimer?.cancel();

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

      // Add listener for player state changes
      _videoPlayerController!.addListener(_playerListener);

      await _videoPlayerController!.initialize().timeout(Duration(seconds: 10));

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowedScreenSleep: false,
          showControlsOnInitialize: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: Color(0xFF614f96),
            handleColor: Color(0xFF614f96),
            backgroundColor: Colors.grey,
            bufferedColor: Color(0xFF614f96).withOpacity(0.5),
          ),
          errorBuilder: (context, errorMessage) {
            return _buildErrorWidget(errorMessage);
          },
        );
        _isLoading = false;
        _isLive = true;
        _retryCount = 0; // Reset retry count on success
      });

      // Start health monitoring
      _startHealthMonitoring();

      print('Stream initialized successfully');
    } catch (e) {
      _handlePlayerError('Initialization failed: ${e.toString()}');
    }
  }

  void _playerListener() {
    if (_videoPlayerController?.value.hasError == true) {
      _handlePlayerError(
          _videoPlayerController!.value.errorDescription ?? 'Unknown error');
    }
  }

  void _startHealthMonitoring() {
    _healthMonitorTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted || _videoPlayerController?.value.isPlaying != true) return;

      _checkStreamHealth();
    });
  }

  void _checkStreamHealth() {
    if (_videoPlayerController?.value.isInitialized != true) return;

    final currentPosition = _videoPlayerController!.value.position;
    final isPlaying = _videoPlayerController!.value.isPlaying;
    final isBuffering = _videoPlayerController!.value.isBuffering;

    // Detect if stream is frozen
    if (isPlaying && !isBuffering) {
      if (_lastPosition != null && currentPosition == _lastPosition) {
        // Position hasn't changed for 10 seconds - stream is frozen
        if (_lastPositionUpdate != null &&
            DateTime.now().difference(_lastPositionUpdate!) >
                Duration(seconds: 10)) {
          _recoverFromFreeze();
        }
      } else {
        _lastPosition = currentPosition;
        _lastPositionUpdate = DateTime.now();
      }
    }

    // If stuck buffering for too long, restart
    if (isBuffering && _retryCount < _maxRetries) {
      _retryCount++;
      _restartPlayer();
    }
  }

  void _recoverFromFreeze() {
    if (_isRecovering) return;

    _isRecovering = true;
    print('Stream frozen detected, attempting recovery...');

    // Try seeking forward slightly to unstuck
    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition + Duration(seconds: 2);

    _videoPlayerController!.seekTo(newPosition).then((_) {
      // If still stuck after seek, restart completely
      Future.delayed(Duration(seconds: 5), () {
        if (_videoPlayerController!.value.position == currentPosition) {
          _restartPlayer();
        }
        _isRecovering = false;
      });
    }).catchError((_) {
      _restartPlayer();
      _isRecovering = false;
    });
  }

  void _handlePlayerError(String error) {
    print('Player error: $error');

    if (_retryCount < _maxRetries) {
      _retryCount++;
      _scheduleRetry();
    } else {
      setState(() {
        _isLoading = false;
        _isLive = false;
        _errorMessage =
            'Stream error: $error\n\nRetry attempts exhausted. Please check the stream source.';
      });
    }
  }

  void _scheduleRetry() {
    _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
      _restartPlayer();
    });
  }

  void _restartPlayer() {
    print('Restarting player... Attempt $_retryCount/$_maxRetries');

    // Clean up existing controllers
    _healthMonitorTimer?.cancel();
    _retryTimer?.cancel();

    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_playerListener);
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }

    _initializePlayer();
  }

  Widget _buildErrorWidget(String errorMessage) {
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _restartPlayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF614f96),
              foregroundColor: Colors.white,
            ),
            child: Text('Reconnect'),
          ),
        ],
      ),
    );
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
        'submittedVia': 'Live Stream',
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
          backgroundColor: Color(0xFF614f96),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Conference Stream',
          style: TextStyle(
            color: Color(0xFF614f96),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF614f96)),
            onPressed: _restartPlayer,
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
          height: 250,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              _buildStreamContent(),
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
              if (_isRecovering)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Recovering...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
              color: Color(0xFF614f96),
            ),
            SizedBox(height: 16),
            Text(
              _retryCount > 0
                  ? 'Reconnecting... ($_retryCount/$_maxRetries)'
                  : 'Connecting to live stream...',
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
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _restartPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF614f96),
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
          Row(
            children: [
              Icon(Icons.question_answer, color: Color(0xFF614f96)),
              SizedBox(width: 8),
              Text(
                'Live Q&A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isLive
                  ? Color(0xFF614f96).withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLive
                    ? Color(0xFF614f96).withOpacity(0.2)
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
                      color: _isLive ? Color(0xFF614f96) : Colors.grey,
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
                          color: _isLive ? Color(0xFF614f96) : Colors.grey,
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
                            ? Color(0xFF614f96).withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _isLive ? Color(0xFF614f96) : Colors.grey,
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
                              _isLive ? Color(0xFF614f96) : Colors.grey,
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
          _buildStreamInfo(),
        ],
      ),
    );
  }

  Widget _buildStreamInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF614f96).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF614f96).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF614f96)),
              SizedBox(width: 8),
              Text(
                'Stream Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
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
          if (_retryCount > 0)
            _buildInfoRow('Connection', 'Auto-recovery active'),
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
                color: Color(0xFF614f96),
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
    WidgetsBinding.instance.removeObserver(this);
    _streamCheckTimer?.cancel();
    _healthMonitorTimer?.cancel();
    _retryTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.removeListener(_playerListener);
    _videoPlayerController?.dispose();
    _questionController.dispose();
    super.dispose();
  }
}
