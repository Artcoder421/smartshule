import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartshule/pages/admin/alerts_page.dart';
import 'package:smartshule/pages/admin/reports_page.dart';
import 'package:smartshule/pages/admin/routes_page.dart';
import 'package:smartshule/pages/admin/settings_page.dart';
import 'package:smartshule/pages/admin/tracking_page.dart';
import 'package:smartshule/pages/admin/users_page.dart';
import '../../services/admin_dashboard_service.dart';
import '../../components/nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final AdminDashboardService _dashboardService;

  final List<Widget> _pages = [
    const DashboardContent(),
    const UsersPage(),
    const RoutesPage(),
    const AlertsPage(),
    const ReportsPage(),
    const TrackingPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _dashboardService = AdminDashboardService();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _dashboardService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(_getAppBarTitle(_currentIndex)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[800],
          elevation: 1,
          actions: [
            if (_currentIndex == 0)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshDashboard,
              ),
          ],
        ),
        body:
            _currentIndex == 0
                ? RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: _pages[_currentIndex],
                )
                : _pages[_currentIndex],
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {}); // Trigger rebuild
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Users';
      case 2:
        return 'Routes';
      case 3:
        return 'Alerts';
      case 4:
        return 'Reports';
      case 5:
        return 'Tracking';
      case 6:
        return 'Settings';
      default:
        return 'Admin Dashboard';
    }
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AdminDashboardService>(context);

    return FutureBuilder<DashboardStats>(
      future: service.fetchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => service.fetchDashboardStats(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        return _buildDashboardUI(context, stats);
      },
    );
  }

  Widget _buildDashboardUI(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Users',
                stats.totalUsers,
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Active Buses',
                stats.totalBuses,
                Icons.directions_bus,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Routes',
                stats.totalRoutes,
                Icons.route,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context,
                'Today\'s Alerts',
                stats.todayAlerts,
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Activities
          Text(
            'Recent Activities',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children:
                    stats.recentActivities.isEmpty
                        ? [const Text('No recent activities')]
                        : stats.recentActivities
                            .map(
                              (activity) =>
                                  _buildActivityItem(context, activity),
                            )
                            .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, RecentActivity activity) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          title: Text(
            activity.description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${_formatDate(activity.timestamp)}'
            '${activity.routeName != null ? ' • ${activity.routeName}' : ''}'
            '${activity.userName != null ? ' • ${activity.userName}' : ''}',
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return Icons.warning;
      case 'route':
        return Icons.route;
      case 'user':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'alert':
        return Colors.orange;
      case 'route':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
