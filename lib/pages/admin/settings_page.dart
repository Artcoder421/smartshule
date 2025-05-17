import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // Clear any stored user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your actual login route
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
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
                  _buildSettingsSection('General Settings', [
                    _buildSettingsSwitch('Enable Notifications', true),
                    _buildSettingsSwitch('Dark Mode', false),
                    _buildSettingsDropdown('Language', [
                      'English',
                      'Spanish',
                      'French',
                    ]),
                  ]),
                  const Divider(),
                  _buildSettingsSection('Security', [
                    _buildSettingsSwitch('Two-Factor Auth', false),
                    _buildSettingsButton('Change Password'),
                    _buildSettingsButton('Manage Devices'),
                  ]),
                  const Divider(),
                  _buildSettingsSection('System', [
                    _buildSettingsButton('Check for Updates'),
                    _buildSettingsButton('Backup Data'),
                    _buildSettingsButton('Reset Settings'),
                  ]),
                  const Divider(),
                  _buildSettingsSection('Account', [
                    _buildLogoutButton(context),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSettingsSwitch(String title, bool value) {
    return ListTile(
      title: Text(title),
      trailing: Switch(value: value, onChanged: (val) {}),
    );
  }

  Widget _buildSettingsDropdown(String title, List<String> options) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: options.first,
        items:
            options.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildSettingsButton(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      title: const Text(
        'Logout',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      leading: const Icon(Icons.logout, color: Colors.red),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout(context);
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
