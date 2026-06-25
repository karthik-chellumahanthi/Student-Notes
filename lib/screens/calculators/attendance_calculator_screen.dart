import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';

class AttendanceCalculatorScreen extends StatefulWidget {
  const AttendanceCalculatorScreen({super.key});

  @override
  State<AttendanceCalculatorScreen> createState() =>
      _AttendanceCalculatorScreenState();
}

class _AttendanceCalculatorScreenState extends State<AttendanceCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Quick Calc State ---
  final TextEditingController _totalClassesController = TextEditingController();
  final TextEditingController _attendedClassesController =
      TextEditingController();
  double _calcPercentage = 0.0;
  String _calcMessage = "";
  Color _calcMessageColor = Colors.black;

  // --- Daily Log State ---
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  Map<String, AttendanceStatus> _attendanceData = {};

  int _totalPresent = 0;
  int _totalAbsent = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadDailyAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalClassesController.dispose();
    _attendedClassesController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAttendance() async {
    final data = await AttendanceService.getAttendanceData();
    setState(() {
      _attendanceData = data;
      _recalculateOverall();
    });
  }

  void _recalculateOverall() {
    _totalPresent = 0;
    _totalAbsent = 0;
    for (var status in _attendanceData.values) {
      if (status == AttendanceStatus.present) _totalPresent++;
      if (status == AttendanceStatus.absent) _totalAbsent++;
    }
  }

  void _toggleDayStatus(DateTime date) {
    String dateStr = AttendanceService.formatDate(date);
    AttendanceStatus currentStatus =
        _attendanceData[dateStr] ?? AttendanceStatus.none;

    AttendanceStatus nextStatus;
    if (currentStatus == AttendanceStatus.none) {
      nextStatus = AttendanceStatus.present;
    } else if (currentStatus == AttendanceStatus.present) {
      nextStatus = AttendanceStatus.absent;
    } else if (currentStatus == AttendanceStatus.absent) {
      nextStatus = AttendanceStatus.holiday;
    } else {
      nextStatus = AttendanceStatus.none;
    }

    setState(() {
      if (nextStatus == AttendanceStatus.none) {
        _attendanceData.remove(dateStr);
      } else {
        _attendanceData[dateStr] = nextStatus;
      }
      _recalculateOverall();
    });

    AttendanceService.saveAttendanceData(_attendanceData);
  }

  void _startNewSemester() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start New Semester?'),
          content: const Text(
            'This will permanently delete all your tracked attendance data. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                await AttendanceService.clearAll();
                setState(() {
                  _attendanceData.clear();
                  _recalculateOverall();
                });
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Quick Calculator Logic ---
  void _calculateQuick() {
    FocusScope.of(context).unfocus();

    int total = int.tryParse(_totalClassesController.text) ?? 0;
    int attended = int.tryParse(_attendedClassesController.text) ?? 0;

    if (total <= 0) {
      setState(() {
        _calcPercentage = 0;
        _calcMessage = "Total classes must be greater than 0.";
        _calcMessageColor = Colors.red;
      });
      return;
    }

    if (attended > total) {
      setState(() {
        _calcPercentage = 0;
        _calcMessage = "Attended classes cannot be more than total classes.";
        _calcMessageColor = Colors.red;
      });
      return;
    }

    double percentage = (attended / total) * 100;
    _updateCalcMessage(percentage, attended, total);
  }

  void _updateCalcMessage(double percentage, int attended, int total) {
    String message = "";
    Color color = Colors.black;

    if (percentage >= 75) {
      int canBunk = 0;
      while (((attended) / (total + canBunk + 1)) * 100 >= 75) {
        canBunk++;
      }
      if (canBunk == 0) {
        message = "You are exactly at 75%. You cannot miss the next class!";
        color = Colors.orange;
      } else {
        message =
            "You can safely bunk $canBunk more class${canBunk > 1 ? 'es' : ''} and stay above 75%.";
        color = Colors.green;
      }
    } else {
      int needToAttend = 0;
      while (((attended + needToAttend) / (total + needToAttend)) * 100 < 75) {
        needToAttend++;
      }
      message =
          "You need to attend $needToAttend more class${needToAttend > 1 ? 'es' : ''} to reach 75%.";
      color = Colors.red;
    }

    setState(() {
      _calcPercentage = percentage;
      _calcMessage = message;
      _calcMessageColor = color;
    });
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Start New Semester',
              onPressed: _startNewSemester,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Daily Log", icon: Icon(Icons.calendar_month)),
            Tab(text: "Quick Calc", icon: Icon(Icons.calculate)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDailyLogTab(theme), _buildQuickCalcTab(theme)],
      ),
    );
  }

  Widget _buildDailyLogTab(ThemeData theme) {
    int totalClasses = _totalPresent + _totalAbsent;
    double overallPercentage = totalClasses == 0
        ? 0
        : (_totalPresent / totalClasses) * 100;

    return Column(
      children: [
        // Overall stats header
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.primaryColor.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Present", _totalPresent.toString(), Colors.green),
              _buildStatItem("Absent", _totalAbsent.toString(), Colors.red),
              _buildStatItem(
                "Overall",
                "${overallPercentage.toStringAsFixed(1)}%",
                overallPercentage >= 75 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),

        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                "${_getMonthName(_currentMonth.month)} ${_currentMonth.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.green, "Present"),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.red, "Absent"),
              const SizedBox(width: 12),
              _buildLegendDot(Colors.orange, "Holiday"),
            ],
          ),
        ),

        // Calendar Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCalendarGrid(),
          ),
        ),

        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Tap any date to cycle: Present -> Absent -> Holiday -> Clear",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    // Determine days in month and starting weekday
    int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    int firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;

    // Adjust weekday to make Sunday = 0
    int startOffset = firstWeekday == 7 ? 0 : firstWeekday;

    List<Widget> days = [];

    // Weekday headers
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (var day in weekdays) {
      days.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    // Empty padding for start of month
    for (int i = 0; i < startOffset; i++) {
      days.add(const SizedBox.shrink());
    }

    // Days of month
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDate = DateTime(
        _currentMonth.year,
        _currentMonth.month,
        i,
      );
      String dateStr = AttendanceService.formatDate(currentDate);
      AttendanceStatus status =
          _attendanceData[dateStr] ?? AttendanceStatus.none;

      Color bgColor;
      Color textColor = Colors.white;
      switch (status) {
        case AttendanceStatus.present:
          bgColor = Colors.green;
          break;
        case AttendanceStatus.absent:
          bgColor = Colors.red;
          break;
        case AttendanceStatus.holiday:
          bgColor = Colors.orange;
          break;
        case AttendanceStatus.none:
          bgColor = Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[200]!;
          textColor = Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87;
          break;
      }

      bool isToday = dateStr == AttendanceService.formatDate(DateTime.now());

      days.add(
        GestureDetector(
          onTap: () => _toggleDayStatus(currentDate),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                i.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(crossAxisCount: 7, children: days);
  }

  Widget _buildQuickCalcTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Calculate hypothetically to see how many classes you can safely skip.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _totalClassesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Classes Held',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _attendedClassesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Classes Attended',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateQuick,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Calculate', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 32),
          if (_calcPercentage > 0 || _calcMessage.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      '${_calcPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _calcPercentage >= 75
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _calcMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: _calcMessageColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_calcPercentage < 75 && _calcPercentage > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Note: Remember that every future class you attend increases BOTH your "Attended" and "Total" classes. That\'s why it takes more classes than you might expect to raise your average!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
