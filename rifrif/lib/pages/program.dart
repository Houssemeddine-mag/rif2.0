import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/program_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class ProgramPage extends StatefulWidget {
  const ProgramPage({Key? key}) : super(key: key);

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage>
    with TickerProviderStateMixin {
  List<ProgramSession> allPrograms = [];
  Map<String, List<ProgramSession>> programsByDate = {};
  bool isLoading = true;
  String? errorMessage;
  String? selectedDate; // Track selected date
  TabController? _tabController;
  bool _isInitializingController = false; // Prevent multiple initializations

  // Real-time stream subscription
  StreamSubscription<List<ProgramSession>>? _programsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    // Cancel real-time subscription
    _programsSubscription?.cancel();

    // Safely dispose TabController with null check
    try {
      _tabController?.dispose();
    } catch (e) {
      // Silently handle disposal errors
      print('TabController disposal error (ignored): $e');
    }
    _tabController = null;
    super.dispose();
  }

  void _setupRealtimeListener() {
    print('Setting up real-time program listener...');

    _programsSubscription = FirebaseService.getProgramsStream().listen(
      (programs) {
        print('Received real-time update: ${programs.length} programs');
        _processPrograms(programs);
      },
      onError: (error) {
        print('Real-time listener error: $error');
        if (mounted) {
          setState(() {
            isLoading = false;
            if (allPrograms.isEmpty) {
              errorMessage = 'Real-time connection error: $error';
            }
          });
        }
      },
    );
  }

  void _processPrograms(List<ProgramSession> programs) {
    if (!mounted) return;

    print('📱 Real-time update received: ${programs.length} programs');

    // Group programs by date
    Map<String, List<ProgramSession>> groupedPrograms = {};
    for (var program in programs) {
      if (!groupedPrograms.containsKey(program.date)) {
        groupedPrograms[program.date] = [];
      }
      groupedPrograms[program.date]!.add(program);
    }

    // Sort programs within each date by start time
    groupedPrograms.forEach((date, programs) {
      programs.sort((a, b) => a.start.compareTo(b.start));
    });

    // Check if the data actually changed to avoid unnecessary rebuilds
    bool dataChanged = false;
    if (allPrograms.length != programs.length) {
      dataChanged = true;
    } else if (programsByDate.length != groupedPrograms.length) {
      dataChanged = true;
    } else {
      // Quick check if dates changed
      final currentDates = programsByDate.keys.toSet();
      final newDates = groupedPrograms.keys.toSet();
      if (!currentDates.containsAll(newDates) ||
          !newDates.containsAll(currentDates)) {
        dataChanged = true;
      }
    }

    // Only update if data actually changed
    if (dataChanged || isLoading) {
      setState(() {
        allPrograms = programs;
        programsByDate = groupedPrograms;
        isLoading = false;
        errorMessage = null; // Clear any previous errors
      });

      // Initialize tab controller after data is loaded
      if (programsByDate.isNotEmpty) {
        _initializeTabController();
      }
    }
  }

  void _initializeTabController() {
    // Prevent multiple simultaneous initializations
    if (_isInitializingController) return;

    // Don't reinitialize if we already have a working TabController with the same length
    if (_tabController != null &&
        programsByDate.isNotEmpty &&
        _tabController!.length == programsByDate.length) {
      // Just update the selected date if needed
      final dates = programsByDate.keys.toList()..sort();
      if (selectedDate == null || !programsByDate.containsKey(selectedDate)) {
        selectedDate = dates.first;
      }
      return;
    }

    _isInitializingController = true;

    try {
      // Store current selection if it exists
      String? currentSelectedDate = selectedDate;

      // Dispose existing controller if it exists
      if (_tabController != null) {
        _tabController!.dispose();
        _tabController = null;
      }

      if (programsByDate.isNotEmpty) {
        _tabController = TabController(
          length: programsByDate.length,
          vsync: this,
        );

        final dates = programsByDate.keys.toList()..sort();

        // Try to restore previous selection, otherwise use first date
        if (currentSelectedDate != null &&
            programsByDate.containsKey(currentSelectedDate)) {
          selectedDate = currentSelectedDate;
          int index = dates.indexOf(currentSelectedDate);
          if (index >= 0 && index < programsByDate.length) {
            _tabController!.index = index;
          }
        } else {
          selectedDate = dates.first;
          _tabController!.index = 0;
        }

        _tabController!.addListener(() {
          if (!mounted) return; // Safety check
          if (_tabController!.indexIsChanging) {
            final dates = programsByDate.keys.toList()..sort();
            if (_tabController!.index < dates.length) {
              setState(() {
                selectedDate = dates[_tabController!.index];
              });
            }
          }
        });
      }
    } catch (e) {
      // Silently handle any errors without showing error page
      print('TabController initialization error (handled): $e');
    } finally {
      _isInitializingController = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'RIF 2025 Program',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 6,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFAA6B94),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Only show loading if we have no data at all
    if (isLoading && allPrograms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAA6B94)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading program...',
              style: TextStyle(
                color: Color(0xFFAA6B94),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Only show error if we have no data to display
    if (errorMessage != null && allPrograms.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Data will update automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (allPrograms.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Color(0xFFAA6B94).withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No program available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The program will be published soon by the organizers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This page will update automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAA6B94),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If TabController is not ready, show loading with existing data
    if (_tabController == null || _isInitializingController) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAA6B94)),
          ),
        ),
      );
    }

    return _buildTabView();
  }

  Widget _buildTabView() {
    // Show horizontal tabs with sessions below
    if (programsByDate.isNotEmpty) {
      return Column(
        children: [
          // Program overview card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFAA6B94), Color(0xFFC87BAA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${allPrograms.length}',
                  'Sessions',
                  Icons.event,
                ),
                _buildStatItem(
                  '${allPrograms.fold<int>(0, (sum, program) => sum + program.conferences.length)}',
                  'Conferences',
                  Icons.mic,
                ),
                _buildStatItem(
                  '${_getUniqueSpeakers().length}',
                  'Speakers',
                  Icons.people,
                ),
              ],
            ),
          ),

          // Horizontal tab bar
          if (_tabController != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController!,
                isScrollable: true,
                indicator: BoxDecoration(
                  color: Color(0xFFAA6B94),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Color(0xFFAA6B94),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: programsByDate.keys.map((date) {
                  final dayPrograms = programsByDate[date]!;
                  return Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTabDate(date),
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${dayPrograms.length} session${dayPrograms.length > 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          SizedBox(height: 16),

          // Sessions for selected day
          Expanded(
            child: selectedDate != null
                ? _buildSessionsList()
                : Center(child: Text('Select a day')),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No program available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sessions will appear here once added',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSessionsList() {
    final dayPrograms = programsByDate[selectedDate!]!;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayPrograms.length,
      itemBuilder: (context, index) {
        final program = dayPrograms[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: _buildProgramCard(program),
        );
      },
    );
  }

  String _formatTabDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday]} ${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Set<String> _getUniqueSpeakers() {
    Set<String> speakers = {};
    for (var program in allPrograms) {
      speakers.addAll(program.allSpeakers);
    }
    return speakers;
  }

  // Helper method to convert base64 string to Uint8List for Image.memory
  Uint8List _getImageFromBase64(String base64String) {
    // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',').last;
    }
    return base64Decode(cleanBase64);
  }

  Widget _buildProgramCard(ProgramSession program) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProgramDetails(program),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time and type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFAA6B94).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${program.start} - ${program.end}',
                      style: TextStyle(
                        color: Color(0xFFAA6B94),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (program.keynote != null &&
                      program.keynote!.name.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          SizedBox(width: 4),
                          Text(
                            'Keynote',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Room information
              if (program.room != null && program.room!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFAA6B94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Color(0xFFAA6B94).withOpacity(0.3)),
                  ),
                  child: Text(
                    program.room!,
                    style: TextStyle(
                      color: Color(0xFFAA6B94),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Title
              Text(
                program.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 8),

              // Keynote speaker (if any)
              if (program.keynote != null &&
                  program.keynote!.name.isNotEmpty) ...[
                Row(
                  children: [
                    // Small keynote image
                    if (program.keynote!.image.isNotEmpty) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFAA6B94),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(
                            _getImageFromBase64(program.keynote!.image),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFAA6B94).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Color(0xFFAA6B94),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ] else ...[
                      Icon(Icons.person, size: 16, color: Color(0xFFAA6B94)),
                      SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        'Keynote Speaker: ${program.keynote!.name}',
                        style: TextStyle(
                          color: Color(0xFFAA6B94),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (program.keynote!.affiliation.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      program.keynote!.affiliation,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8),
              ],

              // Chairs
              if (program.chairs.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.chair, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Chaired by: ${program.chairs.join(', ')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],

              // Conference count
              if (program.conferences.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.list, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${program.conferences.length} presentation${program.conferences.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramDetails(ProgramSession program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Title and time
              Text(
                program.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAA6B94),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${program.start} - ${program.end} • ${program.formattedDate}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),

              // Room information in modal
              if (program.room != null && program.room!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFAA6B94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Color(0xFFAA6B94).withOpacity(0.3)),
                  ),
                  child: Text(
                    'Room: ${program.room!}',
                    style: TextStyle(
                      color: Color(0xFFAA6B94),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Keynote section
                      if (program.keynote != null &&
                          program.keynote!.name.isNotEmpty) ...[
                        _buildSectionTitle('Keynote Speaker'),
                        _buildKeynoteCard(program.keynote!),
                        if (program.keynoteDescription != null &&
                            program.keynoteDescription!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(
                            program.keynoteDescription!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                        SizedBox(height: 20),
                      ],

                      // Chairs section
                      if (program.chairs.isNotEmpty) ...[
                        _buildSectionTitle('Chaired by'),
                        ...program.chairs.map((chair) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: Color(0xFFAA6B94)),
                                  SizedBox(width: 8),
                                  Text(chair),
                                ],
                              ),
                            )),
                        SizedBox(height: 20),
                      ],

                      // Conferences section
                      if (program.conferences.isNotEmpty) ...[
                        _buildSectionTitle(
                            'Presentations (${program.conferences.length})'),
                        ...program.conferences.map(
                            (conference) => _buildConferenceCard(conference)),
                      ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFAA6B94),
        ),
      ),
    );
  }

  Widget _buildKeynoteCard(Keynote keynote) {
    return Card(
      color: Color(0xFFAA6B94).withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Keynote image
            if (keynote.image.isNotEmpty) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Color(0xFFAA6B94),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: Image.memory(
                    _getImageFromBase64(keynote.image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFAA6B94).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(38),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFFAA6B94),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
            ],
            // Keynote info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          keynote.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (keynote.affiliation.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      keynote.affiliation,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (keynote.bio.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      keynote.bio,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
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
  }

  Widget _buildConferenceCard(Conference conference) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRatingDialog(conference),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      conference.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (conference.isKeynote)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Keynote',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.star_rate,
                        size: 16,
                        color: Color(0xFFAA6B94),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Color(0xFFAA6B94)),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      conference.presenter,
                      style: TextStyle(
                        color: Color(0xFFAA6B94),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (conference.affiliation.isNotEmpty) ...[
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    conference.affiliation,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${conference.start} - ${conference.end}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (conference.resume != null &&
                  conference.resume!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  conference.resume!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
              // Show existing ratings if available
              if (conference.presenterRating != null ||
                  conference.presentationRating != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFAA6B94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      if (conference.presenterRating != null) ...[
                        Icon(Icons.person, size: 14, color: Color(0xFFAA6B94)),
                        SizedBox(width: 4),
                        Text(
                          '${conference.presenterRating!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFAA6B94),
                          ),
                        ),
                        _buildStarRating(conference.presenterRating!),
                        SizedBox(width: 16),
                      ],
                      if (conference.presentationRating != null) ...[
                        Icon(Icons.slideshow,
                            size: 14, color: Color(0xFFAA6B94)),
                        SizedBox(width: 4),
                        Text(
                          '${conference.presentationRating!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFAA6B94),
                          ),
                        ),
                        _buildStarRating(conference.presentationRating!),
                      ],
                    ],
                  ),
                ),
              ],
              // Tap to rate hint
              SizedBox(height: 8),
              Text(
                'Tap to rate this presentation',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating.ceil() && rating % 1 >= 0.5)
                  ? Icons.star_half
                  : Icons.star_border,
          size: 12,
          color: Colors.amber,
        );
      }),
    );
  }

  void _showRatingDialog(Conference conference) {
    double presenterRating = conference.presenterRating ?? 0.0;
    double presentationRating = conference.presentationRating ?? 0.0;
    String comment = conference.comment ?? '';
    final commentController = TextEditingController(text: comment);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Presentation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAA6B94),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    conference.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'by ${conference.presenter}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Presenter Rating
                    Text(
                      'Rate the Presenter',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              presenterRating = index + 1.0;
                            });
                          },
                          child: Icon(
                            index < presenterRating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 32,
                            color: index < presenterRating.floor()
                                ? Colors.amber
                                : Colors.grey[400],
                          ),
                        );
                      }),
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
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              presentationRating = index + 1.0;
                            });
                          },
                          child: Icon(
                            index < presentationRating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 32,
                            color: index < presentationRating.floor()
                                ? Colors.amber
                                : Colors.grey[400],
                          ),
                        );
                      }),
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
                        hintText:
                            'Share your thoughts about the presentation...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFAA6B94)),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () async {
                    await _submitRating(
                      conference,
                      presenterRating,
                      presentationRating,
                      commentController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFAA6B94),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(
    Conference conference,
    double presenterRating,
    double presentationRating,
    String comment,
  ) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Submitting your rating...'),
              ],
            ),
            backgroundColor: Color(0xFFAA6B94),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Update the conference with the new ratings
      await FirebaseService.updateConferenceRating(
        conference,
        presenterRating,
        presentationRating,
        comment,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Rating submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to submit rating: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
