import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/program_model.dart';
import '../services/presentation_service.dart';

class PresentationPage extends StatefulWidget {
  const PresentationPage({Key? key}) : super(key: key);

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  final TextEditingController _answerController = TextEditingController();

  String? _selectedPresentationTitle;
  List<Question> _questions = [];
  List<Question> _unassignedQuestions = [];
  List<Conference> _conferences = [];
  List<ProgramSession> _programSessions = [];

  @override
  void initState() {
    super.initState();
    _loadConferences();
    _loadUnassignedQuestions();
  }

  // Handle back button press with confirmation
  Future<bool> _onWillPop() async {
    return await _showExitConfirmation() ?? false;
  }

  // Show exit confirmation dialog
  Future<bool?> _showExitConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Exit Presenter Dashboard',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Text(
              'Are you sure you want to leave the presenter dashboard? You will be redirected to the login page.',
              style: TextStyle(fontSize: 14),
              softWrap: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF614f96),
                foregroundColor: Colors.white,
              ),
              child: Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUnassignedQuestions() async {
    try {
      // Get all questions first
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .orderBy('timestamp', descending: true)
          .get();

      List<Question> allQuestions = snapshot.docs
          .map((doc) => Question.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      // Get all program sessions to check timing
      List<Question> unassigned = [];

      for (Question question in allQuestions) {
        bool isAssignedToAnyPresentation = false;

        // Check if this question's timestamp falls within any presentation timing
        for (ProgramSession session in _programSessions) {
          for (Conference conference in session.conferences) {
            if (await _isQuestionWithinPresentationTime(
                question, conference, session.date)) {
              isAssignedToAnyPresentation = true;
              break;
            }
          }
          if (isAssignedToAnyPresentation) break;
        }

        // If question is not within any presentation timing, it's unassigned
        if (!isAssignedToAnyPresentation) {
          unassigned.add(question);
        }
      }

      setState(() {
        _unassignedQuestions = unassigned;
      });
      print(
          'Loaded ${_unassignedQuestions.length} unassigned questions out of ${allQuestions.length} total questions');
    } catch (e) {
      print('Error loading unassigned questions: $e');
    }
  }

  Future<bool> _isQuestionWithinPresentationTime(
      Question question, Conference conference, String sessionDateStr) async {
    try {
      // Parse session date string (assuming format like "2025-09-12" or "12/09/2025")
      DateTime sessionDate;
      if (sessionDateStr.contains('-')) {
        // Format: YYYY-MM-DD
        sessionDate = DateTime.parse(sessionDateStr);
      } else if (sessionDateStr.contains('/')) {
        // Format: DD/MM/YYYY
        final parts = sessionDateStr.split('/');
        sessionDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        print('Unsupported date format: $sessionDateStr');
        return false;
      }

      // Parse presentation start and end times
      final startTimeParts = conference.start.split(':');
      final endTimeParts = conference.end.split(':');

      final presentationStart = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final presentationEnd = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      // Check if question timestamp is within presentation time
      return question.timestamp.isAfter(presentationStart) &&
          question.timestamp.isBefore(presentationEnd);
    } catch (e) {
      print('Error checking question timing for ${conference.title}: $e');
      return false;
    }
  }

  Future<void> _loadConferences() async {
    try {
      final programSnapshot = await FirebaseFirestore.instance
          .collection('programs')
          .orderBy('date')
          .get();

      List<Conference> allConferences = [];
      List<ProgramSession> allSessions = [];

      for (var doc in programSnapshot.docs) {
        final data = doc.data();
        final programSession = ProgramSession.fromMap(doc.id, data);
        allSessions.add(programSession);

        // Add all conferences from this session
        for (var conference in programSession.conferences) {
          allConferences.add(conference);
        }
      }

      setState(() {
        _conferences = allConferences;
        _programSessions = allSessions;
      });

      print(
          'Loaded ${_conferences.length} conferences from ${_programSessions.length} sessions');

      // Auto-assign unassigned questions to correct presentations
      await PresentationService.autoAssignQuestionsToPresentation();

      // Check if there's a currently active presentation
      final activePresentation =
          await PresentationService.getCurrentActivePresentation();
      if (activePresentation != null) {
        setState(() {
          _selectedPresentationTitle = activePresentation.title;
        });
        await _loadQuestionsForPresentation(activePresentation.title);
        print('Auto-selected active presentation: ${activePresentation.title}');
      }
    } catch (e) {
      print('Error loading conferences: $e');
    }
  }

  Future<void> _loadQuestionsForPresentation(String presentationTitle) async {
    try {
      // Get all questions first
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .orderBy('timestamp', descending: true)
          .get();

      List<Question> allQuestions = snapshot.docs
          .map((doc) => Question.fromMap({'id': doc.id, ...doc.data()}))
          .toList();

      // Find the selected conference and its timing
      Conference? selectedConference;
      String? sessionDateStr;

      for (ProgramSession session in _programSessions) {
        for (Conference conference in session.conferences) {
          if (conference.title == presentationTitle) {
            selectedConference = conference;
            sessionDateStr = session.date;
            break;
          }
        }
        if (selectedConference != null) break;
      }

      if (selectedConference == null || sessionDateStr == null) {
        print('Conference not found: $presentationTitle');
        setState(() {
          _questions = [];
        });
        return;
      }

      // Filter questions that fall within this presentation's timing
      List<Question> presentationQuestions = [];

      for (Question question in allQuestions) {
        if (await _isQuestionWithinPresentationTime(
            question, selectedConference, sessionDateStr)) {
          presentationQuestions.add(question);
        }
      }

      setState(() {
        _questions = presentationQuestions;
      });
      print(
          'Loaded ${_questions.length} questions for $presentationTitle based on timing');
    } catch (e) {
      print('Error loading questions for presentation: $e');
    }
  }

  Future<void> _answerQuestion(Question question, String answer) async {
    try {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(question.id)
          .update({
        'answer': answer,
        'isAnswered': true,
        'answeredAt': Timestamp.now(),
      });

      // Reload questions to show updated status
      if (_selectedPresentationTitle != null) {
        _loadQuestionsForPresentation(_selectedPresentationTitle!);
      }
      // Refresh unassigned questions in case the answered question was unassigned
      _loadUnassignedQuestions();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error answering question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit answer. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: _buildPresenterDashboard(),
    );
  }

  Widget _buildPresenterDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Presenter Dashboard',
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
              if (_selectedPresentationTitle != null) {
                _loadQuestionsForPresentation(_selectedPresentationTitle!);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF614f96)),
            onPressed: () async {
              final shouldExit = await _showExitConfirmation();
              if (shouldExit == true) {
                // Navigation is handled in the dialog
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32, // Account for padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    if (_selectedPresentationTitle == null)
                      _buildWelcomeSection(),

                    // Presentations section
                    _buildPresentationsSection(),

                    // Unassigned Questions Section (always show)
                    SizedBox(height: 24),
                    _buildUnassignedQuestionsSection(),

                    // Questions section (only show if presentation is selected)
                    if (_selectedPresentationTitle != null) ...[
                      SizedBox(height: 24),
                      _buildQuestionsSection(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Color(0xFF614f96).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF614f96).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.slideshow_outlined,
            size: 48,
            color: Color(0xFF614f96),
          ),
          SizedBox(height: 16),
          Text(
            'Welcome to Presenter Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF614f96),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select your presentation below to view and answer questions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationsSection() {
    return FutureBuilder<Conference?>(
      future: PresentationService.getCurrentActivePresentation(),
      builder: (context, snapshot) {
        final activePresentation = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Status Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: activePresentation != null
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: activePresentation != null
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        activePresentation != null
                            ? Icons.live_tv
                            : Icons.schedule,
                        color: activePresentation != null
                            ? Colors.green
                            : Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        activePresentation != null
                            ? 'Currently Active Presentation'
                            : 'No Active Presentation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: activePresentation != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Spacer(),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final assignedCount = await PresentationService
                                .autoAssignQuestionsToPresentation();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Auto-assigned $assignedCount questions'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Reload questions if a presentation is selected
                              if (_selectedPresentationTitle != null) {
                                _loadQuestionsForPresentation(
                                    _selectedPresentationTitle!);
                              }
                              // Refresh unassigned questions
                              _loadUnassignedQuestions();
                            }
                          },
                          icon: Icon(Icons.auto_fix_high, size: 16),
                          label: Text(
                            'Auto-Assign',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF614f96),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activePresentation != null) ...[
                    SizedBox(height: 8),
                    Text(
                      activePresentation.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      '${activePresentation.start} - ${activePresentation.end}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 8),
                    Text(
                      'Questions will be auto-assigned based on timing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Section header
            Row(
              children: [
                Icon(Icons.slideshow, color: Color(0xFF614f96)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Presentations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF614f96),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Presentations list
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _conferences.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conference = _conferences[index];
                final isSelected =
                    _selectedPresentationTitle == conference.title;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedPresentationTitle == conference.title) {
                        // Deselect if clicking the same presentation
                        _selectedPresentationTitle = null;
                        _questions.clear();
                      } else {
                        // Select new presentation
                        _selectedPresentationTitle = conference.title;
                        _loadQuestionsForPresentation(conference.title);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF614f96).withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Color(0xFF614f96) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF614f96).withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? Color(0xFF614f96)
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                conference.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Color(0xFF614f96)
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.only(left: 32),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${conference.start} - ${conference.end}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Color(0xFF614f96)
                                            .withValues(alpha: 0.8)
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected && _questions.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF614f96),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_questions.length} Q',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnassignedQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.help_center_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unassigned Questions (Outside Timings)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.orange),
              onPressed: _loadUnassignedQuestions,
              tooltip: 'Refresh unassigned questions',
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All questions submitted outside any presentation time slots. These need manual assignment or direct answers.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Unassigned questions list
        _unassignedQuestions.isEmpty
            ? _buildNoUnassignedQuestionsState()
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _unassignedQuestions.length,
                separatorBuilder: (context, index) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final question = _unassignedQuestions[index];
                  return _buildUnassignedQuestionCard(question);
                },
              ),
      ],
    );
  }

  Widget _buildNoUnassignedQuestionsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: Colors.green[600],
          ),
          SizedBox(height: 12),
          Text(
            'All questions are assigned!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No questions are currently outside presentation timings',
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedQuestionCard(Question question) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Unassigned',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatTime(question.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Question text
            Container(
              width: double.infinity,
              child: Text(
                question.questionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                softWrap: true,
              ),
            ),
            SizedBox(height: 8),

            // User info
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asked by ${question.authorName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignQuestionDialog(question),
                    icon: Icon(Icons.assignment, size: 16),
                    label: Text('Assign'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _answerUnassignedQuestion(question),
                    icon: Icon(Icons.reply, size: 16),
                    label: Text('Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteQuestionDialog(question),
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Question',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteQuestionDialog(Question question) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Question'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete this question?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      question.questionText,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Asked by: ${question.authorName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteQuestion(question);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 16),
                  SizedBox(width: 4),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting question...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(question.id)
          .delete();

      // Refresh the unassigned questions list
      _loadUnassignedQuestions();

      // Also refresh selected presentation questions if needed
      if (_selectedPresentationTitle != null) {
        _loadQuestionsForPresentation(_selectedPresentationTitle!);
      }

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Question deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting question: $e');

      // Hide loading and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to delete question. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignQuestionDialog(Question question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Question: ${question.questionText}'),
              SizedBox(height: 16),
              Text('Select a presentation to assign this question to:'),
              SizedBox(height: 12),
              Container(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: _conferences.length,
                  itemBuilder: (context, index) {
                    final conference = _conferences[index];
                    return ListTile(
                      title: Text(
                        conference.title,
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text('${conference.start} - ${conference.end}'),
                      onTap: () {
                        _assignQuestionToPresentation(
                            question, conference.title);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignQuestionToPresentation(
      Question question, String presentationTitle) async {
    try {
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(question.id)
          .update({
        'presentationTitle': presentationTitle,
        'presentationId': presentationTitle.toLowerCase().replaceAll(' ', '_'),
      });

      // Refresh both lists
      _loadUnassignedQuestions();
      if (_selectedPresentationTitle != null) {
        _loadQuestionsForPresentation(_selectedPresentationTitle!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question assigned to "$presentationTitle"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error assigning question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign question. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _answerUnassignedQuestion(Question question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final answerController = TextEditingController();
        return AlertDialog(
          title: Text('Answer Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(question.questionText),
              SizedBox(height: 16),
              TextField(
                controller: answerController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (answerController.text.trim().isNotEmpty) {
                  _answerQuestion(question, answerController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: Text('Submit Answer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions header
        Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF614f96)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Questions During: $_selectedPresentationTitle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF614f96),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF614f96).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF614f96).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFF614f96), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing all questions submitted during this presentation\'s scheduled time.',
                  style: TextStyle(
                    color: Color(0xFF614f96),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Questions list
        _questions.isEmpty
            ? _buildNoQuestionsState()
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                separatorBuilder: (context, index) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _buildQuestionCard(question);
                },
              ),
      ],
    );
  }

  Widget _buildNoQuestionsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No questions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Questions from the audience will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: question.isAnswered
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.isAnswered ? 'Answered' : 'Pending',
                      style: TextStyle(
                        color: question.isAnswered
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatTime(question.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Question text
            Container(
              width: double.infinity,
              child: Text(
                question.questionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                softWrap: true,
              ),
            ),
            SizedBox(height: 8),

            // User info
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asked by ${question.authorName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Answer section
            if (question.isAnswered && question.answer != null) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      child: Text(
                        question.answer!,
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: TextField(
                  controller: _answerController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF614f96)),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_answerController.text.trim().isNotEmpty) {
                      _answerQuestion(question, _answerController.text.trim());
                      _answerController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF614f96),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 8),
                      Text('Submit Answer'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}
