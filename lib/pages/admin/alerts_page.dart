import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Alert {
  final int id;
  final String userId;
  final String? userName;
  final String title;
  final String message;
  final String type;
  final int status;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  Alert({
    required this.id,
    required this.userId,
    this.userName,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      userId: json['user_id'].toString(),
      userName: json['user_name']?.toString(),
      title: json['title'].toString(),
      message: json['message'].toString(),
      type: json['type'].toString(),
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'].toString()),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'title': title,
    'message': message,
    'type': type,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'location_name': locationName,
  };

  bool get isActive => status == 1;
}

class AlertService {
  static const String _baseUrl =
      'http://192.168.1.154/smartshulebus_api/admin_alerts.php';

  static Future<List<Alert>> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=fetch'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((json) => Alert.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load alerts');
        }
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  static Future<int> createAlert({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'create',
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return data['data']['alert_id'] as int;
      } else {
        throw Exception(data['message'] ?? 'Failed to create alert');
      }
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  static Future<void> updateAlertStatus({
    required int alertId,
    required int status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'update',
          'alert_id': alertId,
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      if (!(response.statusCode == 200 && data['success'] == true)) {
        throw Exception(data['message'] ?? 'Failed to update alert');
      }
    } catch (e) {
      throw Exception('Failed to update alert: $e');
    }
  }

  static Future<void> deleteAlert(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'delete', 'alert_id': alertId}),
      );

      final data = json.decode(response.body);
      if (!(response.statusCode == 200 && data['success'] == true)) {
        throw Exception(data['message'] ?? 'Failed to delete alert');
      }
    } catch (e) {
      throw Exception('Failed to delete alert: $e');
    }
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Alert> alerts = [];
  bool isLoading = true;
  String filterType = 'all';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => isLoading = true);
    try {
      final fetchedAlerts = await AlertService.fetchAlerts();
      setState(() {
        alerts = fetchedAlerts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading alerts: $e')));
    }
  }

  Future<void> _createAlert({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final alertId = await AlertService.createAlert(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );
      await _loadAlerts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alert created (ID: $alertId)')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating alert: $e')));
    }
  }

  Future<void> _toggleAlertStatus(Alert alert) async {
    try {
      await AlertService.updateAlertStatus(
        alertId: alert.id,
        status: alert.isActive ? 0 : 1,
      );
      await _loadAlerts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert status updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating alert: $e')));
    }
  }

  Future<void> _deleteAlert(int alertId) async {
    try {
      await AlertService.deleteAlert(alertId);
      await _loadAlerts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting alert: $e')));
    }
  }

  Future<String> _getCurrentUserId() async {
    // Implement your actual user ID retrieval logic here
    return '1'; // Example user ID
  }

  List<Alert> get _filteredAlerts {
    return alerts.where((alert) {
      final matchesSearch =
          alert.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          alert.message.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter =
          filterType == 'all' ||
          alert.type == filterType ||
          (filterType == 'active' && alert.isActive) ||
          (filterType == 'inactive' && !alert.isActive);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts Management')),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAlertsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search alerts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Inactive', 'inactive'),
                _buildFilterChip('Emergency', 'emergency'),
                _buildFilterChip('Warning', 'warning'),
                _buildFilterChip('Info', 'info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: filterType == value,
        onSelected: (_) => setState(() => filterType = value),
      ),
    );
  }

  Widget _buildAlertsList() {
    final filteredAlerts = _filteredAlerts;

    if (filteredAlerts.isEmpty) {
      return const Center(
        child: Text('No alerts found', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        itemCount: filteredAlerts.length,
        itemBuilder: (context, index) {
          final alert = filteredAlerts[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(
                alert.type == 'emergency'
                    ? Icons.emergency
                    : alert.type == 'warning'
                    ? Icons.warning
                    : Icons.info,
                color:
                    alert.type == 'emergency'
                        ? Colors.red
                        : alert.type == 'warning'
                        ? Colors.orange
                        : Colors.blue,
              ),
              title: Text(alert.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.message),
                  if (alert.locationName != null)
                    Text('Location: ${alert.locationName}'),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.userName ?? 'Unknown'} • ${DateFormat('MMM d, y - h:mm a').format(alert.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      alert.isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: alert.isActive ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleAlertStatus(alert),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(alert.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateAlertDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String alertType = 'warning';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Alert'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: alertType,
                    items: const [
                      DropdownMenuItem(
                        value: 'emergency',
                        child: Text('Emergency'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('Warning'),
                      ),
                      DropdownMenuItem(
                        value: 'info',
                        child: Text('Information'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Alert Type',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => alertType = value ?? 'warning',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createAlert(
                    title: titleController.text,
                    message: messageController.text,
                    type: alertType,
                  );
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(int alertId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Alert'),
            content: const Text('Are you sure you want to delete this alert?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAlert(alertId);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
