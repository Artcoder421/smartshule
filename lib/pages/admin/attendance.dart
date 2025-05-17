import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:smartshule/models/attendance_model.dart';
import 'dart:convert';

class AttendanceTakingPage extends StatefulWidget {
  final Routes route;
  const AttendanceTakingPage({required this.route, Key? key}) : super(key: key);

  @override
  _AttendanceTakingPageState createState() => _AttendanceTakingPageState();
}

class _AttendanceTakingPageState extends State<AttendanceTakingPage> {
  late RouteStatus _routeStatus = RouteStatus.notStarted;
  List<Student> _availableStudents = [];
  List<AttendanceRecord> _todayAttendance = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  String? _driverName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Load driver info if route has driver assigned
      if (widget.route.driverId != null) {
        final driverResponse = await http.get(
          Uri.parse(
            'http://192.168.1.154/smartshulebus_api/get_routes.php/get_user?id=${widget.route.driverId}',
          ),
        );

        if (driverResponse.statusCode == 200) {
          final driverData = json.decode(driverResponse.body);
          setState(() {
            _driverName =
                '${driverData['first_name']} ${driverData['last_name']}';
          });
        }
      }

      // 2. Get current route status
      final statusResponse = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/get_routes.php/get_route_status?route_id=${widget.route.id}',
        ),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = json.decode(statusResponse.body);
        setState(() {
          _routeStatus = _parseRouteStatus(statusData['status']);
        });
      }

      // 3. Load today's attendance records
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceResponse = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/get_routes.php/get_attendance?date=$formattedDate',
        ),
      );

      if (attendanceResponse.statusCode == 200) {
        setState(() {
          _todayAttendance =
              (json.decode(attendanceResponse.body) as List)
                  .map((a) => AttendanceRecord.fromJson(a))
                  .toList();
        });
      }

      // 4. Load students available for attendance
      final studentsResponse = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/get_routes.php/get_available_students?date=$formattedDate&route_id=${widget.route.id}',
        ),
      );

      if (studentsResponse.statusCode == 200) {
        setState(() {
          _availableStudents =
              (json.decode(studentsResponse.body) as List)
                  .map((s) => Student.fromJson(s))
                  .toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRouteStatus(RouteStatus newStatus) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/update_route_status',
        ),
        body: json.encode({
          'route_id': widget.route.id,
          'status': newStatus.toString().split('.').last,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _routeStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route status updated successfully')),
        );
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAttendance(int studentId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.154/smartshulebus_api/mark_attendance.php'),
        body: json.encode({
          'student_id': studentId,
          'route_id': widget.route.id,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'status': status,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _loadInitialData(); // Refresh data
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Attendance marked as $status')));
      } else {
        throw Exception('Failed to mark attendance');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: ${e.toString()}')),
      );
    }
  }

  List<Student> _getFilteredStudents() {
    final searchTerm = _searchController.text.toLowerCase();
    return _availableStudents
        .where(
          (student) =>
              student.firstName.toLowerCase().contains(searchTerm) ||
              student.lastName.toLowerCase().contains(searchTerm) ||
              student.regNumber.toLowerCase().contains(searchTerm),
        )
        .toList();
  }

  RouteStatus _parseRouteStatus(String status) {
    switch (status.toLowerCase()) {
      case 'started':
        return RouteStatus.started;
      case 'ended':
        return RouteStatus.ended;
      case 'in_progress':
        return RouteStatus.inProgress;
      default:
        return RouteStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.route.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                children: [
                  _buildRouteHeader(),
                  _buildRouteStatusHeader(),
                  _buildSearchBar(),
                  Expanded(child: _buildStudentList()),
                ],
              ),
    );
  }

  Widget _buildRouteHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route: ${widget.route.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'From: ${widget.route.startPoint} to ${widget.route.endPoint}',
            ),
            if (_driverName != null) ...[
              const SizedBox(height: 4),
              Text('Driver: $_driverName'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStatusHeader() {
    Color statusColor;
    String statusText;
    String statusDescription;

    switch (_routeStatus) {
      case RouteStatus.notStarted:
        statusColor = Colors.grey;
        statusText = 'NOT STARTED';
        statusDescription = 'You can take attendance before starting the route';
        break;
      case RouteStatus.started:
        statusColor = Colors.blue;
        statusText = 'STARTED';
        statusDescription = 'Attendance cannot be changed after route start';
        break;
      case RouteStatus.inProgress:
        statusColor = Colors.orange;
        statusText = 'IN PROGRESS';
        statusDescription = 'Route is currently ongoing';
        break;
      case RouteStatus.ended:
        statusColor = Colors.red;
        statusText = 'ENDED';
        statusDescription = 'Route has been completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: statusColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              if (_routeStatus == RouteStatus.notStarted)
                _buildStatusButton('Start Route', RouteStatus.started),
              if (_routeStatus == RouteStatus.started)
                _buildStatusButton('Mark In Progress', RouteStatus.inProgress),
              if (_routeStatus == RouteStatus.inProgress)
                _buildStatusButton('End Route', RouteStatus.ended),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusDescription, style: TextStyle(color: statusColor)),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String text, RouteStatus newStatus) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(text),
      onPressed: () => _showStatusConfirmationDialog(text, newStatus),
    );
  }

  void _showStatusConfirmationDialog(String action, RouteStatus newStatus) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(action),
                onPressed: () {
                  Navigator.pop(context);
                  _updateRouteStatus(newStatus);
                },
              ),
            ],
          ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildStudentList() {
    final students = _getFilteredStudents();

    if (students.isEmpty) {
      return const Center(
        child: Text(
          'No students available for attendance',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final attendanceRecord = _todayAttendance.firstWhere(
          (a) => a.studentId == student.id && a.routeId == widget.route.id,
          orElse:
              () => AttendanceRecord(
                id: 0,
                studentId: student.id,
                routeId: widget.route.id,
                date: _selectedDate,
                status: 'absent',
              ),
        );

        return _buildStudentCard(student, attendanceRecord);
      },
    );
  }

  Widget _buildStudentCard(Student student, AttendanceRecord record) {
    final isPresent = record.status == 'present';
    final canCheckIn = _routeStatus == RouteStatus.notStarted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : const AssetImage('assets/default_student.png')
                      as ImageProvider,
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade: ${student.gradeLevel}'),
            if (record.checkInTime != null)
              Text('Checked in: ${record.checkInTime!.format(context)}'),
          ],
        ),
        trailing:
            canCheckIn
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: isPresent ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _markAttendance(student.id, 'present'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: !isPresent ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _markAttendance(student.id, 'absent'),
                    ),
                  ],
                )
                : Chip(
                  label: Text(isPresent ? 'PRESENT' : 'ABSENT'),
                  backgroundColor:
                      isPresent
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                ),
      ),
    );
  }
}

enum RouteStatus { notStarted, started, inProgress, ended }
