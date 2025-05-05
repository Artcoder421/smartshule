import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/models.dart';
import '../../models/api_service.dart'; // Import the ApiService

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
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      startPoint: (json['start_point'] as String?) ?? '',
      endPoint: (json['end_point'] as String?) ?? '',
      stops: (json['stops']?.toString().split(',') ?? []),
      assignedBusId:
          json['bus_id'] != null
              ? int.tryParse(json['bus_id'].toString())
              : null,
      assignedDriverId:
          json['driver_id'] != null
              ? int.tryParse(json['driver_id'].toString())
              : null,
      assignedBus: json['assigned_bus'] as String?,
      assignedDriver: json['assigned_driver'] as String?,
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
      'driver_id': assignedDriverId,
      'bus_id': assignedBusId,
    };
  }
}

class RouteService {
  static const String _baseUrl = 'http://192.168.1.154/smartshulebus_api/';
  final http.Client client;
  final ApiService apiService; // Add ApiService dependency

  RouteService({required this.client, required this.apiService});

  Future<List<Route>> fetchRoutes() async {
    try {
      final response = await client.get(Uri.parse('$_baseUrl/get_routes.php'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) => Route.fromJson(item)).toList();
      }
      throw Exception('Failed to load routes: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch routes: $e');
    }
  }

  Future<List<User>> fetchDrivers() async {
    try {
      // Use ApiService to get users and filter for drivers
      final allUsers = await apiService.getUsers();
      return allUsers.where((user) => user.role == 'driver').toList();
    } catch (e) {
      throw Exception('Failed to fetch drivers: $e');
    }
  }

  Future<void> createRoute(Route route) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/modify_route.php'),
        body: json.encode(route.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  Future<void> updateRoute(Route route) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/modify_route.php'),
        body: json.encode(route.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update route: $e');
    }
  }

  Future<void> deleteRoute(int id) async {
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/modify_route.php'),
        body: json.encode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }
}

class RoutesPage extends StatefulWidget {
  const RoutesPage({Key? key}) : super(key: key);

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final RouteService _routeService = RouteService(
    client: http.Client(),
    apiService: ApiService(), // Initialize with ApiService
  );
  late Future<List<Route>> _routesFuture;
  late Future<List<User>> _driversFuture;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _stopsController = TextEditingController();
  int? _selectedDriverId;
  Route? _currentRoute;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _routesFuture = _routeService.fetchRoutes();
      _driversFuture = _routeService.fetchDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRouteForm(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: FutureBuilder<List<Route>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No routes found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final route = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(route.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${route.startPoint} to ${route.endPoint}'),
                      if (route.assignedDriver != null)
                        Text('Driver: ${route.assignedDriver}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editRoute(route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRoute(route.id),
                      ),
                    ],
                  ),
                  onTap: () => _showRouteDetails(route),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRouteForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<User>>(
          future: _driversFuture,
          builder: (context, driversSnapshot) {
            if (driversSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (driversSnapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(
                  'Failed to load drivers: ${driversSnapshot.error}',
                ),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            }

            final drivers = driversSnapshot.data ?? [];

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(_isEditing ? 'Edit Route' : 'Add New Route'),
                  content: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Route Name',
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Enter route name'
                                        : null,
                          ),
                          TextFormField(
                            controller: _startController,
                            decoration: const InputDecoration(
                              labelText: 'Start Point',
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Enter start point'
                                        : null,
                          ),
                          TextFormField(
                            controller: _endController,
                            decoration: const InputDecoration(
                              labelText: 'End Point',
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Enter end point'
                                        : null,
                          ),
                          TextFormField(
                            controller: _stopsController,
                            decoration: const InputDecoration(
                              labelText: 'Stops (comma separated)',
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty ?? true
                                        ? 'Enter at least one stop'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int?>(
                            value: _selectedDriverId,
                            decoration: const InputDecoration(
                              labelText: 'Assign Driver',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No driver assigned'),
                              ),
                              ...drivers.map((driver) {
                                return DropdownMenuItem<int?>(
                                  value: driver.userId,
                                  child: Text(driver.fullName),
                                );
                              }).toList(),
                            ],
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedDriverId = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        _clearForm();
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton(
                      child: Text(_isEditing ? 'Update' : 'Save'),
                      onPressed: () => _saveRoute(context),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveRoute(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final route = Route(
          id: _currentRoute?.id ?? 0,
          name: _nameController.text,
          startPoint: _startController.text,
          endPoint: _endController.text,
          stops: _stopsController.text.split(','),
          assignedDriverId: _selectedDriverId,
          assignedBusId: _currentRoute?.assignedBusId,
          assignedBus: _currentRoute?.assignedBus,
          assignedDriver: _currentRoute?.assignedDriver,
          createdAt: _currentRoute?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (_isEditing) {
          await _routeService.updateRoute(route);
        } else {
          await _routeService.createRoute(route);
        }

        _loadData();
        _clearForm();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _editRoute(Route route) {
    setState(() {
      _isEditing = true;
      _currentRoute = route;
      _nameController.text = route.name;
      _startController.text = route.startPoint;
      _endController.text = route.endPoint;
      _stopsController.text = route.stops.join(',');
      _selectedDriverId = route.assignedDriverId;
    });
    _showRouteForm(context);
  }

  Future<void> _deleteRoute(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this route?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deleteRoute(id);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete route: ${e.toString()}')),
        );
      }
    }
  }

  void _showRouteDetails(Route route) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(route.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From: ${route.startPoint}'),
                  Text('To: ${route.endPoint}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Stops:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...route.stops.map((stop) => Text('- $stop')).toList(),
                  const SizedBox(height: 16),
                  Text('Assigned Bus: ${route.assignedBus ?? 'None'}'),
                  Text('Assigned Driver: ${route.assignedDriver ?? 'None'}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _startController.clear();
    _endController.clear();
    _stopsController.clear();
    setState(() {
      _isEditing = false;
      _currentRoute = null;
      _selectedDriverId = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _stopsController.dispose();
    super.dispose();
  }
}
