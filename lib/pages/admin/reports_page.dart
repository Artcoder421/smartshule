import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime selectedDate = DateTime.now();
  List<Route> routes = [];
  List<AttendanceRecord> attendanceRecords = [];
  List<Student> allStudents = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      routes = [];
      attendanceRecords = [];
      allStudents = [];
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await http
          .get(
            Uri.parse(
              'http://192.168.1.154/smartshulebus_api/reports.php?date=$formattedDate',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse routes
        final List<Route> parsedRoutes = [];
        for (var r in data['routes'] ?? []) {
          try {
            parsedRoutes.add(
              Route(
                id: _parseInt(r['id']),
                name: _parseString(r['name']),
                startPoint: _parseString(r['start_point']),
                endPoint: _parseString(r['end_point']),
                driverId: _parseInt(r['driver_id'], nullable: true),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing route: $e');
          }
        }

        // Parse attendance records
        final List<AttendanceRecord> parsedAttendance = [];
        for (var a in data['attendance'] ?? []) {
          try {
            parsedAttendance.add(
              AttendanceRecord(
                id: _parseInt(a['id']),
                studentId: _parseInt(a['student_id']),
                routeId: _parseInt(a['route_id']),
                date: _parseDate(a['date']),
                status: _parseString(a['status']),
                checkInTime:
                    a['check_in_time'] != null
                        ? _parseTime(a['check_in_time'].toString())
                        : null,
                checkOutTime:
                    a['check_out_time'] != null
                        ? _parseTime(a['check_out_time'].toString())
                        : null,
              ),
            );
          } catch (e) {
            debugPrint('Error parsing attendance record: $e');
          }
        }

        // Parse students
        final List<Student> parsedStudents = [];
        for (var s in data['absent_students'] ?? []) {
          try {
            parsedStudents.add(
              Student(
                id: _parseInt(s['id']),
                regNumber: _parseString(s['registration_number']),
                firstName: _parseString(s['first_name']),
                lastName: _parseString(s['last_name']),
                grade: _parseString(s['grade_level']),
                parentId: _parseInt(s['parent_id']),
                photoUrl: s['photo']?.toString(),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing student: $e');
          }
        }

        // Add present students not in absent list
        final List<Student> presentStudents = [];
        for (var a in data['attendance'] ?? []) {
          try {
            final studentId = _parseInt(a['student_id']);
            if (!parsedStudents.any((s) => s.id == studentId)) {
              presentStudents.add(
                Student(
                  id: studentId,
                  regNumber: _parseString(a['registration_number'] ?? 'N/A'),
                  firstName: _parseString(a['first_name']),
                  lastName: _parseString(a['last_name']),
                  grade: _parseString(a['grade'] ?? 'N/A'),
                  parentId: _parseInt(a['parent_id'] ?? -1),
                  photoUrl: a['photo']?.toString(),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error parsing present student: $e');
          }
        }

        setState(() {
          routes = parsedRoutes;
          attendanceRecords = parsedAttendance;
          allStudents = [...parsedStudents, ...presentStudents];
        });
      } else {
        throw HttpException(
          'Server responded with status ${response.statusCode}',
        );
      }
    } on SocketException {
      setState(() => errorMessage = 'No internet connection');
    } on TimeoutException {
      setState(() => errorMessage = 'Request timed out');
    } on FormatException catch (e) {
      setState(() => errorMessage = 'Data format error: ${e.message}');
    } on HttpException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = 'Unexpected error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Helper methods for safe parsing
  int _parseInt(dynamic value, {bool nullable = false}) {
    if (value == null)
      return nullable ? 0 : throw FormatException('Expected int but got null');
    if (value is int) return value;
    if (value is String)
      return int.tryParse(value) ??
          (nullable ? 0 : throw FormatException('Invalid int: $value'));
    if (value is double) return value.toInt();
    throw FormatException('Cannot parse $value as int');
  }

  String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  DateTime _parseDate(dynamic value) {
    try {
      if (value is String)
        return DateTime.parse(value.split(' ')[0]); // Handle datetime strings
      if (value is DateTime) return value;
      throw FormatException('Invalid date format');
    } catch (e) {
      throw FormatException('Failed to parse date: $value');
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      throw FormatException('Failed to parse time: $time');
    }
  }

  List<Student> _getAbsentStudents() {
    final presentStudentIds =
        attendanceRecords
            .where((record) => record.status == 'present')
            .map((record) => record.studentId)
            .toSet();

    return allStudents
        .where((student) => !presentStudentIds.contains(student.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          if (isLoading) const LinearProgressIndicator(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildReportTabs(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Text('Select Date:'),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
              onPressed: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTabs() {
    return DefaultTabController(
      length: routes.length + 1,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              ...routes.map((route) => Tab(text: route.name)),
              const Tab(text: 'Absent Students'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ...routes.map((route) => _buildRouteReport(route)),
                _buildAbsenteesReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteReport(Route route) {
    final routeAttendance =
        attendanceRecords.where((r) => r.routeId == route.id).toList();

    if (routeAttendance.isEmpty) {
      return const Center(child: Text('No attendance records for this route'));
    }

    return ListView.builder(
      itemCount: routeAttendance.length,
      itemBuilder: (context, index) {
        final record = routeAttendance[index];
        final student = allStudents.firstWhere(
          (s) => s.id == record.studentId,
          orElse:
              () => Student(
                id: -1,
                regNumber: 'Unknown',
                firstName: 'Deleted',
                lastName: 'Student',
                grade: 'N/A',
                parentId: -1,
              ),
        );

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
                Text('Grade: ${student.grade}'),
                if (record.checkInTime != null)
                  Text('In: ${record.checkInTime!.format(context)}'),
                if (record.checkOutTime != null)
                  Text('Out: ${record.checkOutTime!.format(context)}'),
              ],
            ),
            trailing: _buildStatusChip(record.status),
          ),
        );
      },
    );
  }

  Widget _buildAbsenteesReport() {
    final absentStudents = _getAbsentStudents();

    if (absentStudents.isEmpty) {
      return const Center(child: Text('No absent students today'));
    }

    return ListView.builder(
      itemCount: absentStudents.length,
      itemBuilder: (context, index) {
        final student = absentStudents[index];

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
            subtitle: Text('Grade: ${student.grade}'),
            trailing: const Chip(
              label: Text('ABSENT'),
              backgroundColor: Colors.redAccent,
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'present':
        color = Colors.green;
        break;
      case 'late':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      await _loadData();
    }
  }
}

// Model classes
class Route {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final int? driverId;

  Route({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    this.driverId,
  });
}

class Student {
  final int id;
  final String regNumber;
  final String firstName;
  final String lastName;
  final String grade;
  final int parentId;
  final String? photoUrl;

  Student({
    required this.id,
    required this.regNumber,
    required this.firstName,
    required this.lastName,
    required this.grade,
    required this.parentId,
    this.photoUrl,
  });
}

class AttendanceRecord {
  final int id;
  final int studentId;
  final int routeId;
  final DateTime date;
  final String status;
  final TimeOfDay? checkInTime;
  final TimeOfDay? checkOutTime;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.routeId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
