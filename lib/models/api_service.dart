// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.154/smartshulebus_api/fetching_model.php';

  // User-related methods
  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    return _handleResponse<List<User>>(response, (data) {
      return (data as List).map((e) => User.fromJson(e)).toList();
    });
  }

  Future<User> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    return _handleResponse<User>(response, (data) => User.fromJson(data));
  }

  Future<User> createUser({
    required String email,
    required String role,
    required String firstName,
    String? lastName,
    String? phone,
    bool isActive = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'is_active': isActive,
      }),
    );
    return _handleResponse<User>(response, (data) => User.fromJson(data));
  }

  Future<User> updateUser(User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/${user.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': user.email,
        'role': user.role,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone': user.phone,
        'is_active': user.isActive,
      }),
    );
    return _handleResponse<User>(response, (data) => User.fromJson(data));
  }

  Future<void> updateUserStatus(int userId, bool isActive) async {
    await http.patch(
      Uri.parse('$baseUrl/users/$userId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'is_active': isActive}),
    );
  }

  Future<void> updateUserRole(int userId, String role) async {
    await http.patch(
      Uri.parse('$baseUrl/users/$userId/role'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'role': role}),
    );
  }

  Future<void> deleteUser(int userId) async {
    await http.delete(Uri.parse('$baseUrl/users/$userId'));
  }

  // Existing methods for other models
  Future<List<Student>> getStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'));
    return _handleResponse<List<Student>>(response, (data) {
      return (data as List).map((e) => Student.fromJson(e)).toList();
    });
  }

  Future<List<Bus>> getBuses() async {
    final response = await http.get(Uri.parse('$baseUrl/buses'));
    return _handleResponse<List<Bus>>(response, (data) {
      return (data as List).map((e) => Bus.fromJson(e)).toList();
    });
  }

  Future<List<Route>> getRoutes() async {
    final response = await http.get(Uri.parse('$baseUrl/routes'));
    return _handleResponse<List<Route>>(response, (data) {
      return (data as List).map((e) => Route.fromJson(e)).toList();
    });
  }

  Future<List<Alert>> getAlerts() async {
    final response = await http.get(Uri.parse('$baseUrl/alerts'));
    return _handleResponse<List<Alert>>(response, (data) {
      return (data as List).map((e) => Alert.fromJson(e)).toList();
    });
  }

  Future<List<Attendance>> getAttendance() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance'));
    return _handleResponse<List<Attendance>>(response, (data) {
      return (data as List).map((e) => Attendance.fromJson(e)).toList();
    });
  }

  Future<List<RouteChecking>> getRouteCheckings() async {
    final response = await http.get(Uri.parse('$baseUrl/route-checkings'));
    return _handleResponse<List<RouteChecking>>(response, (data) {
      return (data as List).map((e) => RouteChecking.fromJson(e)).toList();
    });
  }

  Future<List<Notification>> getNotifications({int? userId}) async {
    final url =
        userId != null
            ? Uri.parse('$baseUrl/notifications?user_id=$userId')
            : Uri.parse('$baseUrl/notifications');
    final response = await http.get(url);
    return _handleResponse<List<Notification>>(response, (data) {
      return (data as List).map((e) => Notification.fromJson(e)).toList();
    });
  }

  T _handleResponse<T>(http.Response response, T Function(dynamic) mapper) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return mapper(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
