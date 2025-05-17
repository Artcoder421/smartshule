import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteModel {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final List<String> stops;
  final int? busId;
  final String? assignedDriver;
  final int? driverId;
  final String? driverPhone;
  final String driverStatus;
  final LocationData? location;

  RouteModel({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    this.busId,
    this.assignedDriver,
    this.driverId,
    this.driverPhone,
    required this.driverStatus,
    this.location,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as int,
      name: json['name'] as String,
      startPoint: json['start_point'] as String,
      endPoint: json['end_point'] as String,
      stops:
          json['stops'] is List
              ? List<String>.from(json['stops'].map((stop) => stop.toString()))
              : [],
      busId: json['bus_id'] as int?,
      assignedDriver: json['assigned_driver'] as String?,
      driverId: json['driver_id'] as int?,
      driverPhone: json['driver_phone'] as String?,
      driverStatus: (json['driver_status'] as String?) ?? 'offline',
      location:
          json['location'] != null
              ? LocationData.fromJson(json['location'])
              : null,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

class TrackingService {
  static const String baseUrl =
      'http://192.168.1.154/smartshulebus_api/tracking_model.php';

  static Future<List<RouteModel>> fetchRoutes() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RouteModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load routes. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class TrackingPage extends StatefulWidget {
  const TrackingPage({Key? key}) : super(key: key);

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late Future<List<RouteModel>> futureRoutes;
  RouteModel? selectedRoute;
  late MapController mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    futureRoutes = TrackingService.fetchRoutes();
    mapController = MapController();
  }

  void _onRouteSelected(RouteModel route) {
    setState(() {
      selectedRoute = route;
      if (route.location != null) {
        mapController.move(route.location!.toLatLng(), 15);
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final routes = await TrackingService.fetchRoutes();
      setState(() {
        futureRoutes = Future.value(routes);
        // Maintain selection if possible
        if (selectedRoute != null) {
          final updatedRoute = routes.firstWhere(
            (r) => r.id == selectedRoute!.id,
            orElse: () => routes.first,
          );
          _onRouteSelected(updatedRoute);
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(child: _buildMapView()),
                      const SizedBox(height: 16),
                      _buildRouteDetails(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSelector() {
    return FutureBuilder<List<RouteModel>>(
      future: futureRoutes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No routes available');
        }

        final routes = snapshot.data!;
        if (selectedRoute == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onRouteSelected(routes.first);
          });
        }

        return DropdownButtonFormField<RouteModel>(
          value: selectedRoute ?? routes.first,
          items:
              routes.map((route) {
                return DropdownMenuItem<RouteModel>(
                  value: route,
                  child: Row(
                    children: [
                      Text(route.name),
                      const SizedBox(width: 8),
                      Icon(
                        route.driverStatus == 'online'
                            ? Icons.circle
                            : Icons.circle_outlined,
                        color:
                            route.driverStatus == 'online'
                                ? Colors.green
                                : Colors.red,
                        size: 12,
                      ),
                    ],
                  ),
                );
              }).toList(),
          decoration: const InputDecoration(
            labelText: 'Select Route',
            border: OutlineInputBorder(),
          ),
          onChanged: (route) {
            if (route != null) {
              _onRouteSelected(route);
            }
          },
        );
      },
    );
  }

  Widget _buildMapView() {
    final defaultLocation = const LatLng(-6.7924, 39.2083); // Dar es Salaam
    final currentLocation =
        selectedRoute?.location?.toLatLng() ?? defaultLocation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(initialCenter: defaultLocation, initialZoom: 12.0),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.smartshulebus',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.directions_bus,
                  color:
                      selectedRoute?.driverStatus == 'online'
                          ? Colors.green
                          : Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetails() {
    if (selectedRoute == null) {
      return const SizedBox.shrink();
    }

    final route = selectedRoute!;
    final isOnline = route.driverStatus == 'online';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(route.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place, size: 16),
            const SizedBox(width: 4),
            Expanded(child: Text('From: ${route.startPoint}')),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.flag, size: 16),
            const SizedBox(width: 4),
            Expanded(child: Text('To: ${route.endPoint}')),
          ],
        ),
        const Divider(height: 24),
        if (route.assignedDriver != null) ...[
          Row(
            children: [
              const Icon(Icons.person, size: 16),
              const SizedBox(width: 4),
              Text('Driver: ${route.assignedDriver}'),
            ],
          ),
          if (route.driverPhone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text('Phone: ${route.driverPhone}'),
              ],
            ),
          ],
        ],
        const SizedBox(height: 8),
        Chip(
          label: Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isOnline ? Colors.green : Colors.red,
        ),
        if (route.location != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last updated: ${route.location!.timestamp}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Coordinates: ${route.location!.latitude.toStringAsFixed(6)}, '
            '${route.location!.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
