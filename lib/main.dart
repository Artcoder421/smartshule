import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'pages/admin/dashboard_pages.dart';
import 'pages/teacher/teacher_dashboard.dart';
import 'pages/driver/driver_dashboard.dart';
import 'pages/matrons/matron_dashboard.dart';
import 'pages/parent/parent_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _driverId; // Consistently stored as String

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Bus Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: FutureBuilder(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return _buildInitialScreen(snapshot.data);
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin': (context) => const AdminDashboard(),
        '/teacher': (context) => const TeacherDashboard(),
        '/matron': (context) => const MatronDashboard(),
        '/parent': (context) => const ParentDashboard(),
        '/driver':
            (context) =>
                DriverDashboard(driverId: _driverId ?? '0', onLogout: () {}),
      },
    );
  }

  Future<String?> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');

    if (userData != null) {
      try {
        final userJson = jsonDecode(userData) as Map<String, dynamic>;
        final role = userJson['role']?.toString().toLowerCase() ?? '';
        final userId = userJson['id'];

        // Convert to String consistently
        if (role == 'driver') {
          _driverId = userId?.toString() ?? '0';
        }

        switch (role) {
          case 'admin':
            return '/admin';
          case 'teacher':
            return '/teacher';
          case 'driver':
            return '/driver';
          case 'matron':
            return '/matron';
          case 'parent':
            return '/parent';
          default:
            return '/login';
        }
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return '/login';
      }
    }
    return '/login';
  }

  Widget _buildInitialScreen(String? route) {
    switch (route) {
      case '/admin':
        return const AdminDashboard();
      case '/teacher':
        return const TeacherDashboard();
      case '/driver':
        return DriverDashboard(driverId: _driverId ?? '0', onLogout: () {});
      case '/matron':
        return const MatronDashboard();
      case '/parent':
        return const ParentDashboard();
      default:
        return const LoginPage();
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'School Bus Tracking',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
