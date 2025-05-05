import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _gpsCoordinates = "0,0";
  bool _gpsPermissionGranted = false;
  String _gpsStatus = "Checking...";

  Future<void> _checkAndRequestPermissions() async {
    setState(() => _gpsStatus = "Checking permissions...");

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsStatus = "Location services disabled");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enable location services in your device settings",
          ),
          duration: Duration(seconds: 20),
        ),
      );
      return;
    }

    // Check location permission status
    PermissionStatus permissionStatus = await Permission.location.status;

    if (permissionStatus.isDenied) {
      permissionStatus = await Permission.location.request();
      if (permissionStatus.isPermanentlyDenied) {
        setState(() => _gpsStatus = "Permission permanently denied");
        _showPermissionSettingsDialog();
        return;
      }
    }

    if (permissionStatus.isGranted) {
      setState(() {
        _gpsPermissionGranted = true;
        _gpsStatus = "Ready to get location";
      });
      await _getGPSLocation();
    } else {
      setState(() => _gpsStatus = "Permission denied");
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Location permission is required for bus tracking. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  Future<void> _getGPSLocation() async {
    if (!_gpsPermissionGranted) {
      await _checkAndRequestPermissions();
      if (!_gpsPermissionGranted) return;
    }

    setState(() => _gpsStatus = "Getting location...");

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 1),
      );

      setState(() {
        _gpsCoordinates = "${position.latitude},${position.longitude}";
        _gpsStatus = "Location acquired";
      });
    } catch (e) {}
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_gpsPermissionGranted) {
      await _checkAndRequestPermissions();
      if (!_gpsPermissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot proceed without location permission"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    if (_gpsCoordinates == "0,0") {
      await _getGPSLocation();
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.154/smartshulebus_api/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'ip_address': _gpsCoordinates,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(data['user']));
        await prefs.setString('lastKnownLocation', _gpsCoordinates);

        _navigateBasedOnRole(data['user']['role']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login failed'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      case 'teacher':
        Navigator.pushReplacementNamed(context, '/teacher');
        break;
      case 'driver':
        Navigator.pushReplacementNamed(context, '/driver');
        break;
      case 'matron':
        Navigator.pushReplacementNamed(context, '/matron');
        break;
      case 'parent':
      case 'guardian':
        Navigator.pushReplacementNamed(context, '/parent');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'School Bus Tracking',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('SIGN IN'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Navigate to forgot password
                        },
                        child: const Text('Forgot Password?'),
                      ),
                      // GPS status panel
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.gps_fixed,
                                  color:
                                      _gpsPermissionGranted
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'GPS Status:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _gpsPermissionGranted
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_gpsStatus, textAlign: TextAlign.center),
                            if (_gpsCoordinates != "0,0")
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Coordinates: $_gpsCoordinates',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            TextButton(
                              onPressed: _checkAndRequestPermissions,
                              child: const Text('Refresh GPS Status'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
