// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/presentation_service.dart';

// class DirectPage extends StatefulWidget {
//   const DirectPage({Key? key}) : super(key: key);

//   @override
//   _DirectPageState createState() => _DirectPageState();
// }

// class _DirectPageState extends State<DirectPage> {
//   // Socket.IO and WebView variables
//   IO.Socket? socket;
//   WebViewController? webViewController;
//   bool _isStreamActive = false;
//   int _viewerCount = 0;
//   List<Map<String, dynamic>> _viewers = [];
//   List<Map<String, dynamic>> _questions = [];
  
//   // UI state variables
//   bool _isLoading = false;
//   bool _isConnected = false;
//   String _errorMessage = '';
//   String _connectionStatus = 'Disconnected';
  
//   // Room code and controls
//   final TextEditingController _roomCodeController = TextEditingController();
//   final TextEditingController _questionController = TextEditingController();
//   bool _isSubmittingQuestion = false;
//   bool _isJoiningRoom = false;
  
//   // WebRTC server URLs - try domain first, then IP as fallback
//   final List<String> _webrtcServerUrls = [
//     'https://myappstore.live:3001',  // Primary: domain with HTTPS and correct port
//     'http://myappstore.live:3001',   // Fallback: domain with HTTP and explicit port
//     'http://4.178.186.35:3001', // Fallback: IP with HTTP and correct port
//   ];
//   String _currentServerUrl = '';
//   int _serverUrlIndex = 0;
//   String? _currentRoomId;
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     _initializeRenderers();
//   }

//   Future<void> _initializeRenderers() async {
//     try {
//       // Initialize WebView controller with enhanced settings for video streaming
//       webViewController = WebViewController()
//         ..setJavaScriptMode(JavaScriptMode.unrestricted)
//         ..setBackgroundColor(const Color(0x00000000))
//         ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
//         ..enableZoom(false)
//         ..setNavigationDelegate(NavigationDelegate(
//           onPageStarted: (String url) {
//             print('WebView started loading: $url');
//           },
//           onPageFinished: (String url) {
//             print('WebView finished loading: $url');
//             setState(() {
//               _isLoading = false;
//             });
//             // Wait a bit for the page to fully render before injecting handlers
//             Future.delayed(Duration(milliseconds: 1000), () {
//               _injectVideoHandlers();
//             });
//           },
//           onWebResourceError: (WebResourceError error) {
//             print('WebView error: ${error.description}');
//             setState(() {
//               _errorMessage = 'Failed to load stream: ${error.description}';
//               _isLoading = false;
//             });
//           },
//         ))
//         ..addJavaScriptChannel(
//           'StreamStatus',
//           onMessageReceived: (JavaScriptMessage message) {
//             print('Stream status: ${message.message}');
//             if (message.message == 'stream-connected') {
//               setState(() {
//                 _isStreamActive = true;
//                 _connectionStatus = 'Stream connected';
//               });
//             } else if (message.message == 'stream-error') {
//               setState(() {
//                 _errorMessage = 'Video stream failed to load';
//               });
//             }
//           },
//         )
//         ..addJavaScriptChannel(
//           'VideoDebug',
//           onMessageReceived: (JavaScriptMessage message) {
//             print('Video Debug: ${message.message}');
//           },
//         );
//       print('WebView controller initialized successfully');
//     } catch (e) {
//       print('Error initializing WebView: $e');
//     }
//   }

//   Future<void> _injectVideoHandlers() async {
//     if (webViewController != null) {
//       await webViewController!.runJavaScript('''
//         console.log("Enhanced video handlers initialized - looking for video#remote-video");
        
//         // Immediate DOM diagnostic
//         console.log('=== IMMEDIATE DOM DIAGNOSTIC ===');
//         console.log('- document.readyState:', document.readyState);
//         console.log('- document.body exists:', !!document.body);
//         console.log('- document.getElementById("remote-video"):', !!document.getElementById('remote-video'));
//         console.log('- document.querySelectorAll("video").length:', document.querySelectorAll('video').length);
//         console.log('- document.innerHTML length:', document.documentElement.innerHTML.length);
//         console.log('- document.title:', document.title);
//         console.log('- window.location.href:', window.location.href);
        
//         // Check DOM tree structure
//         if (document.body) {
//           console.log('- document.body.children.length:', document.body.children.length);
//           const videoContainer = document.querySelector('.video-container');
//           if (videoContainer) {
//             console.log('- Video container found, innerHTML length:', videoContainer.innerHTML.length);
//             console.log('- Video container children:', Array.from(videoContainer.children).map(c => c.tagName + '#' + c.id));
//           } else {
//             console.log('- No .video-container found');
//           }
//         }
//         console.log('=== END IMMEDIATE DIAGNOSTIC ===');
        
//         // Check if we're in the right document
//         function handleVideoElement(video) {
//           if (!video) {
//             console.log("No video element provided to handleVideoElement");
//             return;
//           }
          
//           console.log("Configuring video element:", {
//             id: video.id,
//             tagName: video.tagName,
//             src: video.src,
//             srcObject: !!video.srcObject,
//             videoWidth: video.videoWidth,
//             videoHeight: video.videoHeight,
//             readyState: video.readyState,
//             style: video.style.cssText,
//             offsetWidth: video.offsetWidth,
//             offsetHeight: video.offsetHeight
//           });
          
//           // Force mobile-optimized settings
//           video.muted = true;
//           video.autoplay = true;
//           video.controls = true;
//           video.playsInline = true;
//           video.setAttribute('webkit-playsinline', 'true');
//           video.style.width = '100%';
//           video.style.height = 'auto';
//           video.style.maxWidth = '100%';
//           video.style.display = 'block !important';
//           video.style.visibility = 'visible';
//           video.style.objectFit = 'contain';
//           video.style.backgroundColor = '#000';
          
//           console.log("Video element configured with mobile settings");
          
//           // Remove any existing event listeners to avoid duplicates
//           if (video._handlersAttached) {
//             console.log("Handlers already attached, skipping");
//             return;
//           }
//           video._handlersAttached = true;
          
//           // Add comprehensive event handlers
//           video.addEventListener('loadedmetadata', function() {
//             console.log("Video metadata loaded:", {
//               duration: this.duration,
//               videoWidth: this.videoWidth,
//               videoHeight: this.videoHeight
//             });
//           });
          
//           video.addEventListener('loadeddata', function() {
//             console.log("Video data loaded, attempting to play...");
//             this.play().then(() => {
//               console.log("Video playing successfully");
//               if (window.StreamStatus) {
//                 window.StreamStatus.postMessage('stream-connected');
//               }
//             }).catch(e => {
//               console.error("Video play failed:", e.message);
//               // Try muted play
//               this.muted = true;
//               this.play().then(() => {
//                 console.log("Video playing muted");
//                 if (window.StreamStatus) {
//                   window.StreamStatus.postMessage('stream-connected');
//                 }
//               }).catch(err => {
//                 console.error("Muted play also failed:", err.message);
//                 if (window.StreamStatus) {
//                   window.StreamStatus.postMessage('stream-error');
//                 }
//               });
//             });
//           });
          
//           video.addEventListener('canplay', function() {
//             console.log("Video can play - attempting play");
//             this.play().catch(e => console.log("Play attempt failed:", e));
//           });
          
//           video.addEventListener('error', function(e) {
//             console.error("Video error:", e.type, this.error ? this.error.message : 'Unknown error');
//             if (window.StreamStatus) {
//               window.StreamStatus.postMessage('stream-error');
//             }
//           });
          
//           // Additional events for debugging
//           ['loadstart', 'progress', 'suspend', 'abort', 'emptied', 'stalled', 'play', 'pause', 'playing', 'waiting', 'seeking', 'seeked', 'ended'].forEach(eventType => {
//             video.addEventListener(eventType, function() {
//               console.log('Video event:', eventType, {
//                 currentTime: this.currentTime,
//                 duration: this.duration,
//                 readyState: this.readyState,
//                 paused: this.paused,
//                 srcObject: !!this.srcObject
//               });
//             });
//           });
          
//           // If video already has data, try to play immediately
//           if (video.readyState >= 3) { // HAVE_FUTURE_DATA
//             console.log("Video has data, attempting immediate play");
//             video.play().catch(e => console.log("Immediate play failed:", e));
//           }
//         }
        
//         // Function to specifically find the remote-video element
//         function findRemoteVideo() {
//           const video = document.getElementById('remote-video');
//           console.log('Looking for remote-video element:', !!video);
//           if (video) {
//             console.log('Found remote-video element:', {
//               id: video.id,
//               tagName: video.tagName,
//               display: getComputedStyle(video).display,
//               visibility: getComputedStyle(video).visibility
//             });
//             return video;
//           }
          
//           // Fallback: look for any video element
//           const videos = document.querySelectorAll('video');
//           console.log('Fallback: found', videos.length, 'video elements');
//           return videos.length > 0 ? videos[0] : null;
//         }
        
//         // Function to find and handle all video elements
//         function processAllVideos() {
//           console.log('=== Processing all videos ===');
          
//           // First try to find the specific remote-video element
//           const remoteVideo = findRemoteVideo();
//           if (remoteVideo) {
//             console.log('Processing remote-video element');
//             handleVideoElement(remoteVideo);
//             return 1; // Found and processed
//           }
          
//           // Fallback: process all video elements
//           const videos = document.querySelectorAll('video');
//           console.log('Processing', videos.length, 'video elements');
          
//           videos.forEach((video, index) => {
//             console.log('Processing video', index + ':', video.id || 'no-id');
//             handleVideoElement(video);
//           });
          
//           return videos.length;
//         }
        
//         // Enhanced monitoring for video elements
//         function startVideoMonitoring() {
//           console.log('Starting video monitoring...');
          
//           // Initial processing with detailed logging
//           const videoCount = processAllVideos();
//           console.log('Initial scan found', videoCount, 'video elements');
          
//           // Set up mutation observer for dynamically added videos
//           if (typeof MutationObserver !== 'undefined') {
//             console.log('Setting up MutationObserver');
//             const observer = new MutationObserver(function(mutations) {
//               console.log('DOM mutations detected:', mutations.length);
//               let foundVideos = false;
              
//               mutations.forEach(function(mutation) {
//                 if (mutation.type === 'childList') {
//                   mutation.addedNodes.forEach(function(node) {
//                     if (node.tagName === 'VIDEO') {
//                       console.log('New video element detected via mutation');
//                       handleVideoElement(node);
//                       foundVideos = true;
//                     } else if (node.querySelectorAll) {
//                       const videos = node.querySelectorAll('video');
//                       if (videos.length > 0) {
//                         console.log('Found', videos.length, 'video elements in new node');
//                         videos.forEach(handleVideoElement);
//                         foundVideos = true;
//                       }
//                     }
//                   });
//                 }
                
//                 if (mutation.type === 'attributes' && mutation.target.tagName === 'VIDEO') {
//                   console.log('Video element attributes changed');
//                   handleVideoElement(mutation.target);
//                   foundVideos = true;
//                 }
//               });
              
//               if (!foundVideos) {
//                 // Still check if video is now present after DOM changes
//                 setTimeout(() => {
//                   const count = processAllVideos();
//                   if (count > 0) {
//                     console.log('Found video after DOM change:', count);
//                   }
//                 }, 100);
//               }
//             });
            
//             observer.observe(document.body, {
//               childList: true,
//               subtree: true,
//               attributes: true,
//               attributeFilter: ['src', 'srcObject', 'style', 'class']
//             });
//           } else {
//             console.log('MutationObserver not available');
//           }
          
//           // More frequent periodic checks with detailed logging
//           let checkCount = 0;
//           const intervalId = setInterval(() => {
//             checkCount++;
//             console.log('Periodic check #' + checkCount);
//             const count = processAllVideos();
            
//             // Log DOM structure occasionally for debugging
//             if (checkCount % 10 === 1) {
//               const videoContainer = document.querySelector('.video-container');
//               if (videoContainer) {
//                 console.log('Video container found, children:', videoContainer.children.length);
//                 console.log('Video container HTML:', videoContainer.innerHTML.substring(0, 200));
//               } else {
//                 console.log('Video container not found');
//               }
//             }
//           }, 2000); // Check every 2 seconds
//         }
        
//         // Start monitoring immediately if DOM is ready, otherwise wait
//         if (document.readyState === 'loading') {
//           console.log('DOM still loading, waiting for DOMContentLoaded');
//           document.addEventListener('DOMContentLoaded', function() {
//             console.log('DOMContentLoaded event fired');
//             setTimeout(startVideoMonitoring, 500); // Small delay to ensure everything is ready
//           });
//         } else {
//           console.log('DOM already ready, starting monitoring immediately');
//           setTimeout(startVideoMonitoring, 100); // Small delay to ensure injection is complete
//         }
        
//         // Override console.log to send messages to Flutter
//         const originalConsoleLog = console.log;
//         console.log = function(...args) {
//           originalConsoleLog.apply(console, args);
//           if (window.VideoDebug) {
//             window.VideoDebug.postMessage(args.join(' '));
//           }
//         };
        
//         // Override console.error too
//         const originalConsoleError = console.error;
//         console.error = function(...args) {
//           originalConsoleError.apply(console, args);
//           if (window.VideoDebug) {
//             window.VideoDebug.postMessage('ERROR: ' + args.join(' '));
//           }
//         };
        
//         // Override RTCPeerConnection to monitor stream assignment
//         if (window.RTCPeerConnection) {
//           const originalRTCPeerConnection = window.RTCPeerConnection;
//           window.RTCPeerConnection = function(...args) {
//             const pc = new originalRTCPeerConnection(...args);
//             console.log('RTCPeerConnection created');
            
//             pc.addEventListener('track', function(event) {
//               console.log('Track received:', {
//                 kind: event.track.kind,
//                 id: event.track.id,
//                 enabled: event.track.enabled,
//                 readyState: event.track.readyState
//               });
              
//               if (event.streams && event.streams.length > 0) {
//                 const stream = event.streams[0];
//                 console.log('Stream received with tracks:', stream.getTracks().length);
                
//                 // Find video element and assign stream
//                 setTimeout(() => {
//                   const videos = document.querySelectorAll('video');
//                   videos.forEach(video => {
//                     if (!video.srcObject) {
//                       console.log('Assigning stream to video element');
//                       video.srcObject = stream;
//                       handleVideoElement(video);
//                     }
//                   });
//                 }, 100);
//               }
//             });
            
//             return pc;
//           };
//         }
//       ''');
//     }
//   }

//   Future<void> _connectToSignalingServer() async {
//     try {
//       setState(() {
//         _isJoiningRoom = true;
//         _errorMessage = '';
//         _connectionStatus = 'Connecting...';
//       });

//       await _tryConnectWithUrls();

//     } catch (e) {
//       print('Error connecting: $e');
//       setState(() {
//         _errorMessage = 'Failed to connect: $e';
//         _connectionStatus = 'Failed';
//         _isJoiningRoom = false;
//       });
//     }
//   }

//   Future<void> _tryConnectWithUrls() async {
//     for (int i = 0; i < _webrtcServerUrls.length; i++) {
//       _serverUrlIndex = i;
//       _currentServerUrl = _webrtcServerUrls[i];
      
//       print('Trying to connect to: $_currentServerUrl');
//       setState(() {
//         _connectionStatus = 'Trying $_currentServerUrl...';
//       });

//       try {
//         socket = IO.io(_currentServerUrl, <String, dynamic>{
//           'transports': ['websocket'],
//           'autoConnect': false,
//           'timeout': 5000,
//         });

//         bool connected = await _attemptConnection();
//         if (connected) {
//           print('Successfully connected to: $_currentServerUrl');
//           _setupSocketListeners();
//           return; // Exit on successful connection
//         }
//       } catch (e) {
//         print('Failed to connect to $_currentServerUrl: $e');
//         socket?.disconnect();
//         socket = null;
        
//         if (i == _webrtcServerUrls.length - 1) {
//           // Last attempt failed
//           throw Exception('All server URLs failed. Last error: $e');
//         }
//       }
//     }
//   }

//   Future<bool> _attemptConnection() async {
//     final completer = Completer<bool>();
//     Timer? timeoutTimer;
    
//     socket!.on('connect', (_) {
//       timeoutTimer?.cancel();
//       if (!completer.isCompleted) {
//         completer.complete(true);
//       }
//     });

//     socket!.on('connect_error', (error) {
//       timeoutTimer?.cancel();
//       if (!completer.isCompleted) {
//         completer.complete(false);
//       }
//     });

//     // Set timeout
//     timeoutTimer = Timer(Duration(seconds: 5), () {
//       if (!completer.isCompleted) {
//         completer.complete(false);
//       }
//     });

//     socket!.connect();
    
//     return completer.future;
//   }

//   void _setupSocketListeners() {
//     socket!.on('connect', (_) {
//       print('Connected to signaling server at $_currentServerUrl');
//       setState(() {
//         _connectionStatus = 'Connected to $_currentServerUrl';
//       });
//       _joinRoom();
//     });

//       socket!.on('room-joined', (data) {
//         print('Joined room: $data');
//         setState(() {
//           _isConnected = true;
//           _connectionStatus = 'Joined room ${data['roomId']}';
//           _currentRoomId = data['roomId'];
//           _userId = data['userId'];
//           _isJoiningRoom = false;
//         });
//         // Load the stream after joining
//         _connectToStream();
//       });

//       socket!.on('screen-share-started', (_) {
//         print('Screen share started');
//         setState(() {
//           _connectionStatus = 'Receiving stream...';
//         });
//       });

//       socket!.on('screen-share-stopped', (_) {
//         print('Screen share stopped');
//         setState(() {
//           _connectionStatus = 'Stream stopped';
//         });
//         _cleanupPeerConnection();
//       });

//       socket!.on('signal', (data) {
//         // Signal handling moved to WebView - no longer needed for mobile viewer
//         print('Signal received (handled by WebView): $data');
//       });

//       socket!.on('presenter-left', (_) {
//         print('Presenter left');
//         setState(() {
//           _connectionStatus = 'Presenter disconnected';
//         });
//         _cleanupPeerConnection();
//       });

//       socket!.on('disconnect', (_) {
//         print('Disconnected from server');
//         setState(() {
//           _isConnected = false;
//           _connectionStatus = 'Disconnected';
//         });
//       });

//       socket!.on('connect_error', (error) {
//         print('Connection error: $error');
//         setState(() {
//           _errorMessage = 'Connection failed: $error';
//           _connectionStatus = 'Connection failed';
//           _isJoiningRoom = false;
//         });
//       });

//       // Add viewer count and question listeners
//       socket!.on('viewer-count', (data) {
//         setState(() {
//           _viewerCount = data['count'] ?? 0;
//           _viewers = List<Map<String, dynamic>>.from(data['viewers'] ?? []);
//         });
//       });

//       socket!.on('question-received', (data) {
//         setState(() {
//           _questions.add(data);
//         });
//       });

//       socket!.on('stream-status', (data) {
//         setState(() {
//           _isStreamActive = data['active'] ?? false;
//         });
//       });
//   }

//   void _joinRoom() {
//     if (_currentRoomId != null) {
//       socket!.emit('join-room', {
//         'roomId': _currentRoomId,
//         'role': 'viewer',
//         'username': FirebaseAuth.instance.currentUser?.displayName ?? 'Viewer'
//       });
//     }
//   }

//   void _loadStreamInWebView() {
//     if (webViewController != null && _currentRoomId != null && _currentServerUrl.isNotEmpty) {
//       // Use mobile-optimized viewer that shows only the video stream
//       final streamUrl = '$_currentServerUrl/mobile-viewer.html?room=$_currentRoomId';
//       print('Loading mobile viewer URL: $streamUrl');
//       webViewController!.loadRequest(Uri.parse(streamUrl));
//       setState(() {
//         _isStreamActive = true;
//       });
//     }
//   }

//   void _connectToStream() {
//     setState(() {
//       _isLoading = true;
//       _connectionStatus = 'Loading stream...';
//     });
//     _loadStreamInWebView();
//   }

//   void _joinStreamingRoom() {
//     final roomCode = _roomCodeController.text.trim().toUpperCase();
//     if (roomCode.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please enter a room code'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _currentRoomId = roomCode;
//       _isLoading = true;
//     });

//     _connectToSignalingServer();
//   }

//   void _leaveRoom() {
//     socket?.disconnect();
//     _cleanupPeerConnection();
//     setState(() {
//       _isConnected = false;
//       _isLoading = false;
//       _currentRoomId = null;
//       _connectionStatus = 'Disconnected';
//       _errorMessage = '';
//     });
//   }

//   void _cleanupPeerConnection() {
//     // Clear WebView if needed
//     webViewController = null;
//     setState(() {
//       _isStreamActive = false;
//     });
//     print('Stream cleanup called');
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
//         'submittedVia': 'Live Stream WebRTC',
//         'roomId': _currentRoomId,
//       };

//       await FirebaseFirestore.instance
//           .collection('questions')
//           .add(questionData);

//       // Also send to WebRTC server for real-time display
//       if (socket != null && _isConnected) {
//         socket!.emit('question', {
//           'content': _questionController.text.trim(),
//           'username': user.displayName ?? 'Anonymous',
//           'timestamp': DateTime.now().toIso8601String(),
//           'roomId': _currentRoomId,
//         });
//       }

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
//           if (_isConnected)
//             IconButton(
//               icon: Icon(Icons.exit_to_app, color: Colors.red),
//               onPressed: _leaveRoom,
//               tooltip: 'Leave Room',
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Room Connection Section
//             _buildRoomConnectionSection(),
            
//             // Live Stream Section
//             _buildStreamSection(),

//             // Connection Status
//             _buildStatusSection(),

//             // Questions and Interaction Section
//             _buildInteractionSection(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRoomConnectionSection() {
//     return Container(
//       margin: EdgeInsets.all(16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Color(0xFF614f96).withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Color(0xFF614f96).withOpacity(0.2),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.meeting_room, color: Color(0xFF614f96)),
//               SizedBox(width: 8),
//               Text(
//                 'Join Stream Room',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF614f96),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
          
//           if (!_isConnected) ...[
//             TextField(
//               controller: _roomCodeController,
//               decoration: InputDecoration(
//                 labelText: 'Enter Room Code',
//                 hintText: 'e.g., ABC123',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Color(0xFF614f96)),
//                 ),
//                 prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF614f96)),
//               ),
//               textCapitalization: TextCapitalization.characters,
//               maxLength: 6,
//             ),
//             SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isJoiningRoom ? null : _joinStreamingRoom,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF614f96),
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: _isJoiningRoom
//                     ? Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           ),
//                           SizedBox(width: 8),
//                           Text('Joining...'),
//                         ],
//                       )
//                     : Text(
//                         'Join Stream',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//               ),
//             ),
//           ] else ...[
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.green.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Connected to Room: $_currentRoomId',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                         Text(
//                           'User ID: ${_userId ?? "Unknown"}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.green[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: _leaveRoom,
//                     child: Text('Leave', style: TextStyle(color: Colors.red)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
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
//           height: 250,
//           width: double.infinity,
//           color: Colors.black,
//           child: Stack(
//             children: [
//               _buildStreamContent(),
//               // Live indicator
//               if (_isConnected && _isStreamActive)
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
//               'Connection Error',
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
//                 _errorMessage,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.white70),
//               ),
//             ),
//             SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _errorMessage = '';
//                 });
//                 if (_currentRoomId != null) {
//                   _connectToSignalingServer();
//                 }
//               },
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

//     if (!_isConnected) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.videocam_off, size: 48, color: Colors.white54),
//             SizedBox(height: 12),
//             Text(
//               'Enter room code above to join stream',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_isConnected) {
//       if (_isStreamActive && webViewController != null) {
//         return Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.white24),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: WebViewWidget(controller: webViewController!),
//           ),
//         );
//       } else {
//         return Container(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(color: Colors.white),
//                 SizedBox(height: 16),
//                 Text('Loading video stream...', 
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 SizedBox(height: 8),
//                 Text('Room: $_currentRoomId', 
//                   style: TextStyle(color: Colors.white70, fontSize: 12),
//                 ),
//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     _connectToStream();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF614f96),
//                     foregroundColor: Colors.white,
//                   ),
//                   child: Text('Retry Stream'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.hourglass_empty, size: 48, color: Colors.white54),
//           SizedBox(height: 12),
//           Text(
//             'Waiting for presenter to start sharing...',
//             style: TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusSection() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isConnected ? Icons.wifi : Icons.wifi_off,
//             color: _isConnected ? Colors.green : Colors.grey,
//             size: 20,
//           ),
//           SizedBox(width: 8),
//           Text(
//             _connectionStatus,
//             style: TextStyle(
//               color: _isConnected ? Colors.green[700] : Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
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
//               color: _isConnected
//                   ? Color(0xFF614f96).withOpacity(0.05)
//                   : Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: _isConnected
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
//                       _isConnected ? Icons.live_help : Icons.help_outline,
//                       color: _isConnected ? Color(0xFF614f96) : Colors.grey,
//                     ),
//                     SizedBox(width: 8),
//                     Text(
//                       _isConnected ? 'Ask a Question' : 'Join stream to ask questions',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: _isConnected ? Color(0xFF614f96) : Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 12),
//                 TextField(
//                   controller: _questionController,
//                   enabled: _isConnected,
//                   maxLines: 3,
//                   decoration: InputDecoration(
//                     hintText: _isConnected
//                         ? 'Type your question here...'
//                         : 'Connect to ask questions',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Color(0xFF614f96)),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: (_isConnected && !_isSubmittingQuestion)
//                         ? _submitQuestion
//                         : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF614f96),
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isSubmittingQuestion
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                               SizedBox(width: 8),
//                               Text('Submitting...'),
//                             ],
//                           )
//                         : Text(
//                             'Submit Question',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: 16),

//           // Instructions
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.blue.withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.info, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text(
//                       'How to use',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[700],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   '1. Get the room code from the presenter\n'
//                   '2. Enter the code and tap "Join Stream"\n'
//                   '3. Watch the live presentation\n'
//                   '4. Ask questions using the form below',
//                   style: TextStyle(
//                     color: Colors.blue[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     socket?.disconnect();
//     _cleanupPeerConnection();
//     _roomCodeController.dispose();
//     _questionController.dispose();
//     super.dispose();
//   }
// }

 //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
//***************************************************************************************************************************  //************************************************************************************************************************* */
  //********************************************NEW WITH VM AZURE mediamtx*************************************************** */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */
  //************************************************************************************************************************* */

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
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

  // Server connection status variables
  bool _isServerConnected = false;
  String _serverConnectionStatus = 'Checking server...';
  String _streamConnectionStatus = 'Not connected';

  // Question submission
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmittingQuestion = false;

  // Stream URLs - MediaMTX HLS endpoint
final String _streamUrl = 'http://4.178.186.35:8888/live/index.m3u8';

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
  // Future<void> _checkStreamAvailability() async {
  //   try {
  //     final response = await http
  //         .get(Uri.parse(_streamStatusUrl))
  //         .timeout(Duration(seconds: 5));
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final paths = data['items'] as List<dynamic>;

  //       // Check if our stream path is active
  //       final isStreamActive = paths
  //           .any((path) => path['name'] == 'RIFLIVE' && path['ready'] == true);

  //       if (isStreamActive) {
  //         _initializePlayer();
  //       } else {
  //         _startStreamMonitoring();
  //       }
  //     }
  //   } catch (e) {
  //     // If status check fails, try direct initialization
  //     _startStreamMonitoring();
  //   }
  // }
  
  Future<void> _checkStreamAvailability() async {
    if (!mounted) return;

    print('🔍 Checking stream availability at: $_streamUrl');
    setState(() {
      _serverConnectionStatus = 'Checking server connection...';
    });

    try {
      final response = await http
          .get(Uri.parse(_streamUrl))
          .timeout(Duration(seconds: 10));

      if (!mounted) return;

      print('📡 Server response: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ Server is accessible, stream available');
        setState(() {
          _isServerConnected = true;
          _serverConnectionStatus = 'Server connected ✅';
          _streamConnectionStatus = 'Stream available, initializing player...';
        });
        _initializePlayer();
      } else if (response.statusCode == 404) {
        print('❌ Stream not found (404) - Stream may not be active');
        setState(() {
          _isServerConnected = true;
          _serverConnectionStatus = 'Server connected ✅';
          _streamConnectionStatus = 'Stream not active (404)';
        });
        _startStreamMonitoring();
      } else {
        print('⚠️ Server responded with status: ${response.statusCode}');
        setState(() {
          _isServerConnected = false;
          _serverConnectionStatus = 'Server error (${response.statusCode})';
          _streamConnectionStatus = 'Stream unavailable';
        });
        _startStreamMonitoring();
      }
    } catch (e) {
      print('❌ Stream availability check failed: $e');
      if (mounted) {
        setState(() {
          _isServerConnected = false;
          _serverConnectionStatus = 'Server unreachable ❌';
          _streamConnectionStatus = 'Connection failed: ${e.toString()}';
        });
        _startStreamMonitoring();
      }
    }
  }

  void _startStreamMonitoring() {
    if (!mounted) return;

    print('🔄 Starting stream monitoring - checking every 5 seconds');
    setState(() {
      _streamConnectionStatus = 'Monitoring for stream...';
    });

    _streamCheckTimer?.cancel();
    _streamCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      print('🔄 Periodic stream check...');
      await _checkStreamAvailability();
    });
  }

  Future<void> _safeDisposeControllers() async {
    try {
      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoPlayerController != null) {
        _videoPlayerController!.removeListener(_playerListener);
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }
    } catch (e) {
      print('Error disposing controllers: $e');
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    try {
      // Cancel monitoring timer
      _streamCheckTimer?.cancel();

      if (!mounted) return;

      print('🎬 Initializing video player for: $_streamUrl');
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _streamConnectionStatus = 'Initializing video player...';
      });

      // Dispose previous controllers if they exist
      await _safeDisposeControllers();

      if (!mounted) return;

      print('📱 Creating VideoPlayerController...');
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_streamUrl),
        httpHeaders: {
          'User-Agent': 'RIF Flutter App',
          'Accept': '*/*',
        },
      );

      // Add listener for player state changes
      _videoPlayerController!.addListener(_playerListener);

      print('⏳ Initializing video player...');
      await _videoPlayerController!.initialize().timeout(Duration(seconds: 15));

      if (!mounted) return;

      print('✅ Video player initialized successfully');
      print('📹 Video dimensions: ${_videoPlayerController!.value.size}');
      print('📹 Video duration: ${_videoPlayerController!.value.duration}');

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowedScreenSleep: false,
          showControlsOnInitialize: true,
          showControls: true,
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
        _retryCount = 0;
        _streamConnectionStatus = 'Video player ready ✅';
      });

      // Start health monitoring
      _startHealthMonitoring();

      print('🎉 Stream initialized and playing successfully');
    } catch (e) {
      print('❌ Player initialization failed: $e');
      _handlePlayerError('Video player initialization failed: ${e.toString()}');
    }
  }

  void _playerListener() {
    if (!mounted) return;

    try {
      if (_videoPlayerController?.value.hasError == true) {
        _handlePlayerError(
            _videoPlayerController!.value.errorDescription ?? 'Unknown error');
      }
    } catch (e) {
      print('Player listener error: $e');
    }
  }

  void _startHealthMonitoring() {
    if (!mounted) return;

    _healthMonitorTimer?.cancel();
    _healthMonitorTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_videoPlayerController?.value.isPlaying != true) return;
      _checkStreamHealth();
    });
  }

  void _checkStreamHealth() {
    if (!mounted || _videoPlayerController?.value.isInitialized != true) return;

    try {
      final currentPosition = _videoPlayerController!.value.position;
      final isPlaying = _videoPlayerController!.value.isPlaying;
      final isBuffering = _videoPlayerController!.value.isBuffering;

      // Detect if stream is frozen (less aggressive timing)
      if (isPlaying && !isBuffering) {
        if (_lastPosition != null && currentPosition == _lastPosition) {
          // Position hasn't changed for 15 seconds - stream is frozen
          if (_lastPositionUpdate != null &&
              DateTime.now().difference(_lastPositionUpdate!) >
                  Duration(seconds: 15)) {
            _recoverFromFreeze();
          }
        } else {
          _lastPosition = currentPosition;
          _lastPositionUpdate = DateTime.now();
        }
      }

      // If stuck buffering for too long, restart (less aggressive)
      if (isBuffering && _retryCount < _maxRetries) {
        // Only restart after 30 seconds of buffering
        if (_lastPositionUpdate != null &&
            DateTime.now().difference(_lastPositionUpdate!) >
                Duration(seconds: 30)) {
          _retryCount++;
          _restartPlayer();
        }
      }
    } catch (e) {
      print('Stream health check error: $e');
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
    print('❌ Player error: $error');

    setState(() {
      _streamConnectionStatus = 'Video player error: $error';
    });

    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('🔄 Scheduling retry attempt ${_retryCount}/${_maxRetries}');
      setState(() {
        _streamConnectionStatus = 'Retrying... (${_retryCount}/${_maxRetries})';
      });
      _scheduleRetry();
    } else {
      setState(() {
        _isLoading = false;
        _isLive = false;
        _errorMessage =
            'Stream error: $error\n\nRetry attempts exhausted. Please check the stream source.';
        _streamConnectionStatus = 'Failed after ${_maxRetries} retry attempts';
      });
    }
  }

  void _scheduleRetry() {
    _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
      _restartPlayer();
    });
  }

  void _restartPlayer() {
    if (!mounted) return;

    print('Restarting player... Attempt $_retryCount/$_maxRetries');

    // Clean up existing timers
    _healthMonitorTimer?.cancel();
    _retryTimer?.cancel();
    _streamCheckTimer?.cancel();

    // Reset recovery state
    _isRecovering = false;
    _lastPosition = null;
    _lastPositionUpdate = null;

    // Safely dispose controllers
    _safeDisposeControllers().then((_) {
      if (mounted) {
        _initializePlayer();
      }
    }).catchError((e) {
      print('Error in restart player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLive = false;
          _errorMessage =
              'Failed to restart player. Please try manual refresh.';
        });
      }
    });
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
    // Crash prevention wrapper
    try {
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
              onPressed: () {
                try {
                  _restartPlayer();
                } catch (e) {
                  print('Error in restart: $e');
                }
              },
              tooltip: 'Refresh Stream',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Connection Status Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: _isServerConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isServerConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isServerConnected ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverConnectionStatus,
                            style: TextStyle(
                              color: _isServerConnected ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_streamConnectionStatus.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _isLive ? Icons.videocam : Icons.videocam_off,
                            color: _isLive ? Colors.blue : Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _streamConnectionStatus,
                              style: TextStyle(
                                color: _isLive ? Colors.blue : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
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
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Build error: $e');
      // Fallback UI in case of crash
      return Scaffold(
        appBar: AppBar(
          title: Text('Live Stream'),
          backgroundColor: Color(0xFF614f96),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Stream temporarily unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please try refreshing the page'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _initializePlayer();
                  }
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStreamSection() {
    try {
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
    } catch (e) {
      print('Error building stream section: $e');
      return Container(
        height: 250,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Stream view error',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildStreamContent() {
    try {
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
                  'Stream is currently offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  try {
                    _restartPlayer();
                  } catch (e) {
                    print('Error in retry: $e');
                  }
                },
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
    } catch (e) {
      print('Error building stream content: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Stream Error',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Unable to display stream',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }
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
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel all timers
    _streamCheckTimer?.cancel();
    _healthMonitorTimer?.cancel();
    _retryTimer?.cancel();

    // Dispose controllers safely
    try {
      _chewieController?.dispose();
    } catch (e) {
      print('Error disposing chewie controller: $e');
    }

    try {
      _videoPlayerController?.removeListener(_playerListener);
      _videoPlayerController?.dispose();
    } catch (e) {
      print('Error disposing video controller: $e');
    }

    try {
      _questionController.dispose();
    } catch (e) {
      print('Error disposing question controller: $e');
    }

    super.dispose();
  }
}