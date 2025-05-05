import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class DashboardStats {
  final int totalUsers;
  final int totalBuses;
  final int totalRoutes;
  final int todayAlerts;
  final List<RecentActivity> recentActivities;

  DashboardStats({
    required this.totalUsers,
    required this.totalBuses,
    required this.totalRoutes,
    required this.todayAlerts,
    required this.recentActivities,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    var activities = json['recent_activities'] as List;
    return DashboardStats(
      totalUsers: json['total_users'],
      totalBuses: json['total_buses'],
      totalRoutes: json['total_routes'],
      todayAlerts: json['today_alerts'],
      recentActivities:
          activities.map((a) => RecentActivity.fromJson(a)).toList(),
    );
  }
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;
  final String? routeName;
  final String? userName;

  RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
    this.routeName,
    this.userName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      routeName: json['route_name'],
      userName: json['user_name'],
    );
  }
}

class AdminDashboardService {
  static const String _baseUrl =
      'http://192.168.1.154/smartshulebus_api/get_statistics.php';

  Future<DashboardStats> fetchDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_stats.php'));

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      throw Exception('Failed to connect to server');
    }
  }
}
