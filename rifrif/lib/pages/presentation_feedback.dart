import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/program_model.dart';
import '../models/user_profile_model.dart';

class PresentationFeedbackPage extends StatefulWidget {
  final Conference conference;
  final String sessionDate;

  const PresentationFeedbackPage({
    Key? key,
    required this.conference,
    required this.sessionDate,
  }) : super(key: key);

  @override
  State<PresentationFeedbackPage> createState() =>
      _PresentationFeedbackPageState();
}

class _PresentationFeedbackPageState extends State<PresentationFeedbackPage> {
  List<Map<String, dynamic>> allRatings = [];
  Map<String, UserProfile?> userProfiles = {};
  bool isLoading = true;
  bool isSubmittingRating = false;
  String? errorMessage;

  // User's current rating
  double userPresenterRating = 0.0;
  double userPresentationRating = 0.0;
  String userComment = '';
  final TextEditingController commentController = TextEditingController();
  bool hasUserRating = false;

  @override
  void initState() {
    super.initState();
    _loadAllFeedback();
    _loadUserRating();
  }

  Future<void> _loadAllFeedback() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get all ratings for this presentation
      final ratings = await FirebaseService.getAllRatingsForPresentation(
        widget.conference,
        sessionDate: widget.sessionDate,
      );

      // Load user profiles for each rating
      Map<String, UserProfile?> profiles = {};
      for (var rating in ratings) {
        final userId = rating['userId'];
        if (userId != null && !profiles.containsKey(userId)) {
          try {
            final profile = await FirebaseService().getUserProfile(userId);
            profiles[userId] = profile;
          } catch (e) {
            profiles[userId] = null;
          }
        }
      }

      setState(() {
        allRatings = ratings;
        userProfiles = profiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading feedback: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final userRating = await FirebaseService.getUserRating(
        widget.conference,
        sessionDate: widget.sessionDate,
      );

      if (userRating != null) {
        setState(() {
          userPresenterRating =
              userRating['presenterRating']?.toDouble() ?? 0.0;
          userPresentationRating =
              userRating['presentationRating']?.toDouble() ?? 0.0;
          userComment = userRating['comment'] ?? '';
          commentController.text = userComment;
          hasUserRating = true;
        });
      }
    } catch (e) {
      print('Error loading user rating: $e');
    }
  }

  Future<void> _submitRating() async {
    if (userPresenterRating == 0.0 && userPresentationRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide at least one rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmittingRating = true;
    });

    try {
      await FirebaseService.submitUserRating(
        widget.conference,
        userPresenterRating,
        userPresentationRating,
        commentController.text.trim(),
        sessionDate: widget.sessionDate,
      );

      setState(() {
        hasUserRating = true;
        userComment = commentController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(hasUserRating ? 'Rating updated!' : 'Rating submitted!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload all feedback to show the updated rating
      await _loadAllFeedback();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmittingRating = false;
      });
    }
  }

  Widget _buildStarRating(double rating,
      {bool interactive = false, Function(double)? onRatingChanged}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating.floor();
        final isHalfFilled = index < rating.ceil() && rating % 1 >= 0.5;

        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged(index + 1.0)
              : null,
          child: Icon(
            isFilled
                ? Icons.star
                : isHalfFilled
                    ? Icons.star_half
                    : Icons.star_border,
            size: interactive ? 32 : 16,
            color: isFilled || isHalfFilled
                ? Colors.amber
                : interactive
                    ? Colors.grey[400]
                    : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final userId = rating['userId'];
    final profile = userProfiles[userId];
    final userName = profile?.displayName?.isNotEmpty == true
        ? profile!.displayName!
        : rating['userEmail']?.toString().split('@')[0] ?? 'Anonymous User';

    final timestamp = rating['ratedAt'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown time';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF614f96),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Ratings
            Row(
              children: [
                if (rating['presenterRating'] != null &&
                    rating['presenterRating'] > 0) ...[
                  Icon(Icons.person, size: 18, color: Color(0xFF614f96)),
                  SizedBox(width: 4),
                  _buildStarRating(rating['presenterRating'].toDouble()),
                  SizedBox(width: 4),
                  Text(
                    '${rating['presenterRating']}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 16),
                ],
                if (rating['presentationRating'] != null &&
                    rating['presentationRating'] > 0) ...[
                  Icon(Icons.slideshow, size: 18, color: Color(0xFF614f96)),
                  SizedBox(width: 4),
                  _buildStarRating(rating['presentationRating'].toDouble()),
                  SizedBox(width: 4),
                  Text(
                    '${rating['presentationRating']}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),

            // Comment
            if (rating['comment'] != null &&
                rating['comment'].toString().trim().isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  rating['comment'],
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildUserRatingSection() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Color(0xFF614f96)),
                SizedBox(width: 8),
                Text(
                  hasUserRating
                      ? 'Update Your Rating'
                      : 'Rate This Presentation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF614f96),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Presenter Rating
            Text(
              'Rate the Presenter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            _buildStarRating(
              userPresenterRating,
              interactive: true,
              onRatingChanged: (rating) {
                setState(() {
                  userPresenterRating = rating;
                });
              },
            ),
            SizedBox(height: 20),

            // Presentation Rating
            Text(
              'Rate the Presentation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            _buildStarRating(
              userPresentationRating,
              interactive: true,
              onRatingChanged: (rating) {
                setState(() {
                  userPresentationRating = rating;
                });
              },
            ),
            SizedBox(height: 20),

            // Comment
            Text(
              'Add a Comment (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about the presentation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF614f96)),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmittingRating ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF614f96),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: isSubmittingRating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        hasUserRating ? 'Update Rating' : 'Submit Rating',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Presentation Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF614f96),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Presentation Header
          Container(
            width: double.infinity,
            color: Color(0xFF614f96),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conference.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'by ${widget.conference.presenter}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '${widget.conference.start} - ${widget.conference.end}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF614f96)),
                        ),
                        SizedBox(height: 16),
                        Text('Loading feedback...'),
                      ],
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAllFeedback,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllFeedback,
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // User Rating Section
                              _buildUserRatingSection(),

                              // All Ratings Section
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.forum, color: Color(0xFF614f96)),
                                    SizedBox(width: 8),
                                    Text(
                                      'All Reviews (${allRatings.length})',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF614f96),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (allRatings.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Be the first to rate this presentation!',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...allRatings
                                    .map((rating) => _buildRatingCard(rating))
                                    .toList(),

                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
