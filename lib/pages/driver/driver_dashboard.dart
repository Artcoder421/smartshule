import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DriverDashboard extends StatefulWidget {
  final String driverId;
  final VoidCallback onLogout;

  const DriverDashboard({
    Key? key,
    required this.driverId,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  // Route Management
  List<Route> _routes = [];
  List<Route> _pendingRoutes = [];
  List<Route> _activeRoutes = [];

  // Location Tracking
  Position? _currentPosition;
  String _locationMessage = "Getting location...";
  Timer? _locationTimer;

  // UI State
  bool _isLoading = true;
  bool _isPanicActive = false;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    await _checkLocationPermission();
    await _fetchRoutes();
    _startLocationUpdates();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/get_routes?driver_id=${widget.driverId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _routes = data.map((r) => Route.fromJson(r)).toList();
            _pendingRoutes =
                _routes.where((r) => r.status?.isEmpty ?? true).toList();
            _activeRoutes =
                _routes.where((r) => r.status?.isNotEmpty ?? false).toList();
          });
        } else if (data['success'] == true) {
          setState(() {
            _routes =
                (data['routes'] as List).map((r) => Route.fromJson(r)).toList();
            _pendingRoutes =
                _routes.where((r) => r.status?.isEmpty ?? true).toList();
            _activeRoutes =
                _routes.where((r) => r.status?.isNotEmpty ?? false).toList();
          });
        } else {
          _showError(data['message'] ?? 'Failed to load routes');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRouteStatus(int routeId, String status) async {
    try {
      // First update location
      await _sendCurrentLocationToServer();

      // Then update route status
      final response = await http.post(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/update_route_status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'route_id': routeId,
          'driver_id': widget.driverId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _fetchRoutes();
          _showSuccess('Route status updated');
        } else {
          _showError(data['message'] ?? 'Failed to update route');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to update route: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = "Enable location services");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationMessage = "Enable location in settings");
    }
  }

  void _startLocationUpdates() {
    _getCurrentLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _getCurrentLocation(),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _currentPosition = position;
        _locationMessage =
            "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });

      await _sendCurrentLocationToServer();
    } catch (e) {
      setState(() => _locationMessage = "Location error: ${e.toString()}");
    }
  }

  Future<void> _sendCurrentLocationToServer() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.154/smartshulebus_api/update_location.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': widget.driverId,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!(data['success'] ?? false)) {
          print('Location update failed: ${data['message']}');
        }
      } else {
        print('Location update failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Location update error: $e');
    }
  }

  Future<void> _openMap() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        _showError('Location not available');
        return;
      }
    }

    setState(() {
      _showMap = true;
    });
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Getting current location...'),
            TextButton(
              onPressed: _getCurrentLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.smartshule',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      _locationTimer?.cancel();
      widget.onLogout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _sendPanicAlert() async {
    try {
      // Ensure we have current location
      if (_currentPosition == null) {
        await _getCurrentLocation();
        if (_currentPosition == null) {
          _showError('Location not available for panic alert');
          return;
        }
      }

      setState(() => _isPanicActive = true);

      // First update location to ensure it's current
      await _sendCurrentLocationToServer();

      final response = await http.post(
        Uri.parse('http://192.168.1.154/smartshulebus_api/fetch_alerts.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'create',
          'user_id': widget.driverId,
          'title': 'EMERGENCY ALERT',
          'message': 'Driver has triggered panic button',
          'type': 'emergency',
          'recipients': 'all',
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccess('Emergency alert sent');
        } else {
          _showError(data['message'] ?? 'Failed to send alert');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to send alert: $e');
    } finally {
      if (mounted) {
        Future.delayed(const Duration(minutes: 1), () {
          setState(() => _isPanicActive = false);
        });
      }
    }
  }

  Widget _buildRouteCard(Route route) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RouteDetailsPage(
                    route: route,
                    driverId: widget.driverId,
                    currentPosition: _currentPosition,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('${route.startPoint} → ${route.endPoint}'),
              const SizedBox(height: 12),
              if (route.status == null || route.status == '')
                _buildActionButton(
                  'Start Route',
                  Colors.blue,
                  () => _updateRouteStatus(route.id, 'Started'),
                ),
              if (route.status == 'Started')
                Column(
                  children: [
                    _buildActionButton(
                      'Mark In Progress',
                      Colors.orange,
                      () => _updateRouteStatus(route.id, 'InProgress'),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      'End Route',
                      Colors.red,
                      () => _updateRouteStatus(route.id, 'Ended'),
                    ),
                  ],
                ),
              if (route.status == 'InProgress')
                _buildActionButton(
                  'End Route',
                  Colors.red,
                  () => _updateRouteStatus(route.id, 'Ended'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              if (_showMap) {
                setState(() => _showMap = false);
              } else {
                _openMap();
              }
            },
            tooltip: _showMap ? 'Show List' : 'Show Map',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getCurrentLocation(); // Refresh location
              _fetchRoutes(); // Refresh routes
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _showMap
              ? _buildMapView()
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            size: 40,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Driver',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(_locationMessage),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_pendingRoutes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Pending Routes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._pendingRoutes.map((r) => _buildRouteCard(r)).toList(),
                    ],
                    if (_activeRoutes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Active Routes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._activeRoutes.map((r) => _buildRouteCard(r)).toList(),
                    ],
                    if (_pendingRoutes.isEmpty && _activeRoutes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No routes assigned today',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'panic',
            onPressed: _isPanicActive ? null : _sendPanicAlert,
            backgroundColor: _isPanicActive ? Colors.grey : Colors.red,
            child: const Icon(Icons.warning),
            tooltip: 'Emergency',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location',
            onPressed: () {
              _getCurrentLocation(); // Refresh location
              _sendCurrentLocationToServer(); // Force send to server
            },
            child: const Icon(Icons.my_location),
            tooltip: 'Refresh Location',
          ),
        ],
      ),
    );
  }
}

class RouteDetailsPage extends StatefulWidget {
  final Route route;
  final String driverId;
  final Position? currentPosition;

  const RouteDetailsPage({
    Key? key,
    required this.route,
    required this.driverId,
    required this.currentPosition,
  }) : super(key: key);

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  List<Student> _students = [];
  bool _isLoading = true;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.route.status ?? '';
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/get_available_students?route_id=${widget.route.id}&date=${DateTime.now().toIso8601String().split('T')[0]}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _students = (data as List).map((s) => Student.fromJson(s)).toList();
        });
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRouteStatus(String status) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/update_route_status',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'route_id': widget.route.id,
          'driver_id': widget.driverId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => _currentStatus = status);
          _showSuccess('Route status updated to $status');
        } else {
          _showError(data['message'] ?? 'Failed to update route');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to update route: $e');
    }
  }

  Future<void> _markAttendance(int studentId, String status) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/attendance.php/mark_attendance',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'route_id': widget.route.id,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _fetchStudents();
          _showSuccess('Attendance marked as $status');
        } else {
          _showError(data['message'] ?? 'Failed to mark attendance');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to mark attendance: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudents,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.route.startPoint} → ${widget.route.endPoint}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${_currentStatus.isEmpty ? 'Not Started' : _currentStatus}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_currentStatus),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_currentStatus.isEmpty)
                          _buildActionButton(
                            'Start Route',
                            Colors.blue,
                            () => _updateRouteStatus('Started'),
                          ),
                        if (_currentStatus == 'Started')
                          Column(
                            children: [
                              _buildActionButton(
                                'Mark In Progress',
                                Colors.orange,
                                () => _updateRouteStatus('InProgress'),
                              ),
                              const SizedBox(height: 8),
                              _buildActionButton(
                                'End Route',
                                Colors.red,
                                () => _updateRouteStatus('Ended'),
                              ),
                            ],
                          ),
                        if (_currentStatus == 'InProgress')
                          _buildActionButton(
                            'End Route',
                            Colors.red,
                            () => _updateRouteStatus('Ended'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child:
                        _students.isEmpty
                            ? const Center(
                              child: Text('No students assigned to this route'),
                            )
                            : ListView.builder(
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        student.photoUrl != null
                                            ? NetworkImage(student.photoUrl!)
                                            : null,
                                    child:
                                        student.photoUrl == null
                                            ? Text(student.firstName[0])
                                            : null,
                                  ),
                                  title: Text(
                                    '${student.firstName} ${student.lastName}',
                                  ),
                                  subtitle: Text(
                                    '${student.regNumber} • ${student.gradeLevel}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed:
                                            () => _markAttendance(
                                              student.id,
                                              'Present',
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _markAttendance(
                                              student.id,
                                              'Absent',
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Started':
        return Colors.blue;
      case 'InProgress':
        return Colors.orange;
      case 'Ended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Route {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final String? status;
  final List<String> stops;
  final int assignedDriverId;
  final int assignedBusId;
  final String? assignedDriver;
  final String? assignedBus;
  final String createdAt;
  final String updatedAt;

  Route({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    this.status,
    required this.stops,
    required this.assignedDriverId,
    required this.assignedBusId,
    this.assignedDriver,
    this.assignedBus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      startPoint: json['start_point'] ?? json['startPoint'] ?? '',
      endPoint: json['end_point'] ?? json['endPoint'] ?? '',
      status: json['status'],
      stops:
          (json['stops'] is String)
              ? List<String>.from(jsonDecode(json['stops']))
              : List<String>.from(json['stops'] ?? []),
      assignedDriverId:
          json['assigned_driver_id'] is int
              ? json['assigned_driver_id']
              : int.tryParse(json['assigned_driver_id'].toString()) ?? 0,
      assignedBusId:
          json['assigned_bus_id'] is int
              ? json['assigned_bus_id']
              : int.tryParse(json['assigned_bus_id'].toString()) ?? 0,
      assignedDriver: json['assigned_driver'],
      assignedBus: json['assigned_bus'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      regNumber: json['reg_number'] ?? json['registration_number'] ?? '',
      gradeLevel: json['grade_level'] ?? '',
      photoUrl: json['photo_url'] ?? json['photo'],
    );
  }
}
