import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// ==================== MODELS ====================
class Route {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final List<String> stops;
  final int? assignedBusId;
  final int? assignedDriverId;
  final String? assignedBus;
  final String? assignedDriver;
  final DateTime createdAt;
  final DateTime updatedAt;

  Route({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    this.assignedBusId,
    this.assignedDriverId,
    this.assignedBus,
    this.assignedDriver,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      startPoint: json['start_point'] as String? ?? '',
      endPoint: json['end_point'] as String? ?? '',
      stops: json['stops']?.toString().split(',') ?? [],
      assignedBusId:
          json['bus_id'] != null
              ? int.tryParse(json['bus_id'].toString())
              : null,
      assignedDriverId:
          json['driver_id'] != null
              ? int.tryParse(json['assignedDriverId'].toString())
              : null,
      assignedBus: json['assigned_bus'] as String?,
      assignedDriver: json['assignedDriver'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_point': startPoint,
      'end_point': endPoint,
      'stops': stops.join(','),
      'assignedDriverId': assignedDriverId,
      'bus_id': assignedBusId,
    };
  }
}

class User {
  final int userId;
  final String firstName;
  final String lastName;
  final String role;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String regNumber;
  final String gradeLevel;
  final String? photoUrl;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.regNumber,
    required this.gradeLevel,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      regNumber: json['registration_number'] as String? ?? '',
      gradeLevel: json['grade_level'] as String? ?? '',
      photoUrl: json['photo'] as String?,
    );
  }
}

class AttendanceRecord {
  final int id;
  final int studentId;
  final int routeId;
  final DateTime date;
  final String status;
  final TimeOfDay? checkInTime;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.routeId,
    required this.date,
    required this.status,
    this.checkInTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      routeId: json['route_id'] as int? ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'absent',
      checkInTime:
          json['check_in_time'] != null
              ? TimeOfDay.fromDateTime(DateTime.parse(json['check_in_time']))
              : null,
    );
  }
}

enum RouteStatus { notStarted, started, inProgress, ended }

// ==================== SERVICES ====================
class ApiService {
  final http.Client client;

  ApiService({required this.client});

  Future<List<User>> getUsers() async {
    final response = await client.get(
      Uri.parse('http://192.168.1.154/smartshulebus_api/get_drivers.php'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => User.fromJson(item)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<User> getUser(int id) async {
    final response = await client.get(
      Uri.parse(
        'http://192.168.1.154/smartshulebus_api/attendance.php/get_user?id=$id',
      ),
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load user');
  }
}

class RouteService {
  static const String _baseUrl = 'http://192.168.1.154/smartshulebus_api/';
  final http.Client client;
  final ApiService apiService;

  RouteService({required this.client, required this.apiService});

  Future<List<Route>> fetchRoutes() async {
    final response = await client.get(Uri.parse('${_baseUrl}get_routes.php'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Route.fromJson(item)).toList();
    }
    throw Exception('Failed to load routes');
  }

  Future<List<User>> fetchDrivers() async {
    try {
      final response = await client.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/get_drivers.php',
        ), // Add specific endpoint in PHP
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) => User.fromJson(item)).toList();
      }
      throw Exception('Failed to load drivers: ${response.statusCode}');
    } catch (e) {
      throw Exception('Driver fetch error: $e');
    }
  }

  Future<void> saveRoute(Route route) async {
    final response = await client.post(
      Uri.parse('${_baseUrl}modify_route.php'),
      body: json.encode(route.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save route');
    }
  }

  Future<void> deleteRoute(int id) async {
    final response = await client.post(
      Uri.parse('${_baseUrl}modify_route.php'),
      body: json.encode({'id': id}),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete route');
    }
  }

  Future<List<Student>> getAvailableStudents(int routeId, String date) async {
    final response = await client.get(
      Uri.parse(
        '${_baseUrl}attendance.php/get_available_students?route_id=$routeId&date=$date',
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Student.fromJson(item)).toList();
    }
    throw Exception('Failed to load students');
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(String date) async {
    final response = await client.get(
      Uri.parse('${_baseUrl}attendance.php/get_attendance_report?date=$date'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();
    }
    throw Exception('Failed to load attendance');
  }

  Future<void> markAttendance({
    required int studentId,
    required int routeId,
    required String date,
    required String status,
  }) async {
    final response = await client.post(
      Uri.parse('${_baseUrl}attendance.php/mark_attendance'),
      body: json.encode({
        'student_id': studentId,
        'route_id': routeId,
        'date': date,
        'status': status,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark attendance');
    }
  }

  Future<void> updateRouteStatus({
    required int routeId,
    required RouteStatus status,
  }) async {
    final response = await client.post(
      Uri.parse('${_baseUrl}attendance.php/update_route_status'),
      body: json.encode({
        'route_id': routeId,
        'status': status.toString().split('.').last,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update route status');
    }
  }
}

// ==================== PAGES ====================
class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final RouteService _routeService = RouteService(
    client: http.Client(),
    apiService: ApiService(client: http.Client()),
  );
  late Future<List<Route>> _routesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _routesFuture = _routeService.fetchRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRouteForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              onChanged:
                  (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Route>>(
              future: _routesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No routes available'));
                }

                final filteredRoutes =
                    snapshot.data!.where((route) {
                      return route.name.toLowerCase().contains(_searchQuery) ||
                          route.startPoint.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          route.endPoint.toLowerCase().contains(_searchQuery) ||
                          (route.assignedDriver?.toLowerCase().contains(
                                _searchQuery,
                              ) ??
                              false);
                    }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final route = filteredRoutes[index];
                    return _buildRouteCard(route, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Route route, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceTakingPage(route: route),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    route.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Route'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Route',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditRouteDialog(context, route);
                      } else if (value == 'delete') {
                        _confirmDeleteRoute(context, route.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${route.startPoint} to ${route.endPoint}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (route.assignedDriver != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Driver: ${route.assignedDriver}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (route.stops.isNotEmpty) ...[
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      route.stops
                          .map(
                            (stop) => Chip(
                              label: Text(stop.trim()),
                              backgroundColor: Colors.grey[200],
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteForm(BuildContext context, {Route? routeToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: routeToEdit?.name ?? '');
    final startController = TextEditingController(
      text: routeToEdit?.startPoint ?? '',
    );
    final endController = TextEditingController(
      text: routeToEdit?.endPoint ?? '',
    );
    final stopsController = TextEditingController(
      text: routeToEdit?.stops.join(',') ?? '',
    );
    int? selectedDriverId = routeToEdit?.assignedDriverId;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<User>>(
          future: _routeService.fetchDrivers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load drivers: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final drivers = snapshot.data ?? [];

            return AlertDialog(
              title: Text(routeToEdit != null ? 'Edit Route' : 'Add Route'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Route Name',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: startController,
                        decoration: const InputDecoration(
                          labelText: 'Start Point',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: endController,
                        decoration: const InputDecoration(
                          labelText: 'End Point',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: stopsController,
                        decoration: const InputDecoration(
                          labelText: 'Stops',
                          hintText: 'Comma separated list',
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Assign Driver',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No driver assigned'),
                          ),
                          ...drivers.map(
                            (driver) => DropdownMenuItem(
                              value: driver.userId,
                              child: Text(driver.fullName),
                            ),
                          ),
                        ],
                        onChanged: (value) => selectedDriverId = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      try {
                        final route = Route(
                          id: routeToEdit?.id ?? 0,
                          name: nameController.text,
                          startPoint: startController.text,
                          endPoint: endController.text,
                          stops: stopsController.text.split(','),
                          assignedDriverId: selectedDriverId,
                          assignedBusId: routeToEdit?.assignedBusId,
                          assignedBus: routeToEdit?.assignedBus,
                          assignedDriver: routeToEdit?.assignedDriver,
                          createdAt: routeToEdit?.createdAt ?? DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await _routeService.saveRoute(route);
                        _loadData();
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditRouteDialog(BuildContext context, Route route) {
    _showRouteForm(context, routeToEdit: route);
  }

  Future<void> _confirmDeleteRoute(BuildContext context, int routeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this route?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deleteRoute(routeId);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete route: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AttendanceTakingPage extends StatefulWidget {
  final Route route;

  const AttendanceTakingPage({required this.route, Key? key}) : super(key: key);

  @override
  State<AttendanceTakingPage> createState() => _AttendanceTakingPageState();
}

class _AttendanceTakingPageState extends State<AttendanceTakingPage> {
  final RouteService _routeService = RouteService(
    client: http.Client(),
    apiService: ApiService(client: http.Client()),
  );
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
      // Load driver info if route has driver assigned
      if (widget.route.assignedDriverId != null) {
        final driver = await _routeService.apiService.getUser(
          widget.route.assignedDriverId!,
        );
        setState(() {
          _driverName = driver.fullName;
        });
      }

      // Load today's attendance records
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final [students, attendance] = await Future.wait([
        _routeService.getAvailableStudents(widget.route.id, formattedDate),
        _routeService.getAttendanceRecords(formattedDate),
      ]);

      setState(() {
        _availableStudents = students.cast<Student>();
        _todayAttendance = attendance.cast<AttendanceRecord>();
      });
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
      await _routeService.updateRouteStatus(
        routeId: widget.route.id,
        status: newStatus,
      );
      setState(() {
        _routeStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAttendance(int studentId, String status) async {
    try {
      await _routeService.markAttendance(
        studentId: studentId,
        routeId: widget.route.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: status,
      );
      await _loadInitialData(); // Refresh data
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attendance marked as $status')));
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
