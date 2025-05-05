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
  final List<dynamic> stops;
  final int? assignedBus;
  final String assignedDriver;
  final int? driverId;
  final String driverPhone;
  final String driverStatus;
  final String? ipAddress;
  final Map<String, double>? location;

  RouteModel({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    this.assignedBus,
    required this.assignedDriver,
    this.driverId,
    required this.driverPhone,
    required this.driverStatus,
    this.ipAddress,
    this.location,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      startPoint: json['start_point'],
      endPoint: json['end_point'],
      stops: json['stops'] ?? [],
      assignedBus: json['assigned_bus'],
      assignedDriver: json['assigned_driver'] ?? 'Not assigned',
      driverId: json['driver_id'],
      driverPhone: json['driver_phone'] ?? 'N/A',
      driverStatus: json['driver_status'] ?? 'offline',
      ipAddress: json['ip_address'],
      location:
          json['location'] != null
              ? Map<String, double>.from(json['location'])
              : null,
    );
  }
}

class TrackingService {
  static const String baseUrl =
      'http://192.168.1.154/smartshulebus_api/tracking_model.php';

  static Future<List<RouteModel>> fetchRoutes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => RouteModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load routes');
    }
  }
}

class TrackingPage extends StatefulWidget {
  const TrackingPage({Key? key}) : super(key: key);

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late Future<List<RouteModel>> futureRoutes;
  RouteModel? selectedRoute;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    futureRoutes = TrackingService.fetchRoutes();
    mapController = MapController();
  }

  void _onRouteSelected(RouteModel route) {
    setState(() {
      selectedRoute = route;
    });

    if (route.location != null) {
      final position = LatLng(
        route.location!['latitude']!,
        route.location!['longitude']!,
      );
      mapController.move(position, 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Bus Tracking ',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRouteSelector(),
                    const SizedBox(height: 16),
                    _buildMapView(),
                    const SizedBox(height: 16),
                    _buildRouteDetails(),
                  ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No routes available');
        }

        return DropdownButtonFormField<RouteModel>(
          value: selectedRoute ?? snapshot.data!.first,
          items:
              snapshot.data!.map((route) {
                return DropdownMenuItem<RouteModel>(
                  value: route,
                  child: Text(
                    '${route.name} - ${route.driverStatus == 'online' ? '🚌 Online' : '🔴 Offline'}',
                  ),
                );
              }).toList(),
          decoration: const InputDecoration(labelText: 'Select Route'),
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
    // Default to Dar es Salaam coordinates
    final darEsSalaamCenter = const LatLng(-6.7924, 39.2083);
    final location = selectedRoute?.location;
    final currentLocation =
        location != null
            ? LatLng(location['latitude']!, location['longitude']!)
            : darEsSalaamCenter;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: darEsSalaamCenter,
          initialZoom: 12.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          if (location != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.red,
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
      return const Text('Select a route to view details');
    }

    final route = selectedRoute!;
    final isOnline = route.driverStatus == 'online';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          route.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('From: ${route.startPoint}'),
        Text('To: ${route.endPoint}'),
        const SizedBox(height: 8),
        Text('Driver: ${route.assignedDriver}'),
        Text('Phone: ${route.driverPhone}'),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isOnline ? Colors.green : Colors.red,
        ),
        if (!isOnline)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Driver has not been active today',
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (isOnline && route.location != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Last location: ${route.location!['latitude']!.toStringAsFixed(4)}, '
              '${route.location!['longitude']!.toStringAsFixed(4)}',
            ),
          ),
      ],
    );
  }
}
