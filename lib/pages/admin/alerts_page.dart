import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.154/smartshulebus_api/fetch_alerts.php?action=fetch',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alerts = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching alerts: $e')));
    }
  }

  Future<void> _createAlert({
    required String title,
    required String message,
    required String type,
    required String recipients,
    bool isEmergency = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.154/smartshulebus_api/fetch_alerts.php'),
        body: {
          'action': 'create',
          'title': title,
          'message': message,
          'type': type,
          'recipients': recipients,
          'is_emergency': isEmergency ? '1' : '0',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alert created successfully')),
          );
          _fetchAlerts();
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to create alert');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating alert: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emergency),
                    label: const Text('Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _handleEmergencyAlert(),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_alert),
                    label: const Text('New Alert'),
                    onPressed: () => _showCreateAlertDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAlertFilter(),
                  const SizedBox(height: 16),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAlertsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search alerts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: 'all',
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Alerts')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
            DropdownMenuItem(value: 'warning', child: Text('Warning')),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildAlertsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return ListTile(
          leading: Icon(
            alert['type'] == 'emergency' ? Icons.emergency : Icons.warning,
            color:
                alert['type'] == 'emergency'
                    ? Colors.red
                    : alert['type'] == 'urgent'
                    ? Colors.orange
                    : Colors.blue,
          ),
          title: Text(alert['title']),
          subtitle: Text(alert['message']),
          trailing: Chip(
            label: Text(
              alert['status'] == '1' ? 'Active' : 'Resolved',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor:
                alert['status'] == '1' ? Colors.green : Colors.grey,
          ),
          onTap: () {},
        );
      },
    );
  }

  void _showCreateAlertDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String alertType = 'warning';
    String recipients = 'all';

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
                    decoration: const InputDecoration(labelText: 'Alert Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Message',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: alertType,
                    items: const [
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('Warning'),
                      ),
                      DropdownMenuItem(
                        value: 'info',
                        child: Text('Information'),
                      ),
                    ],
                    decoration: const InputDecoration(labelText: 'Alert Type'),
                    onChanged: (value) {
                      if (value != null) {
                        alertType = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: recipients,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(
                        value: 'drivers',
                        child: Text('Drivers Only'),
                      ),
                      DropdownMenuItem(
                        value: 'parents',
                        child: Text('Parents Only'),
                      ),
                    ],
                    decoration: const InputDecoration(labelText: 'Recipients'),
                    onChanged: (value) {
                      if (value != null) {
                        recipients = value;
                      }
                    },
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
                    recipients: recipients,
                  );
                },
                child: const Text('Create Alert'),
              ),
            ],
          ),
    );
  }

  void _handleEmergencyAlert() {
    _createAlert(
      title: 'EMERGENCY ALERT!',
      message: 'This is an emergency situation requiring immediate attention!',
      type: 'emergency',
      recipients: 'all',
      isEmergency: true,
    );
  }
}
