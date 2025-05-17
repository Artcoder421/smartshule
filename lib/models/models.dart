// Models for School Bus System

class Bus {
  final int busId;
  final String busNumber;
  final String licensePlate;
  final int capacity;
  final int? driverId;
  final int? currentRouteId;
  final bool isActive;
  final DateTime? lastMaintenance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bus({
    required this.busId,
    required this.busNumber,
    required this.licensePlate,
    required this.capacity,
    this.driverId,
    this.currentRouteId,
    required this.isActive,
    this.lastMaintenance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      busId: json['bus_id'],
      busNumber: json['bus_number'],
      licensePlate: json['license_plate'],
      capacity: json['capacity'],
      driverId: json['driver_id'],
      currentRouteId: json['current_route_id'],
      isActive: json['is_active'] == 1,
      lastMaintenance:
          json['last_maintenance'] != null
              ? DateTime.parse(json['last_maintenance'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Alert {
  final int alertId;
  final String alertType;
  final String title;
  final String? message;
  final int createdBy;
  final bool isResolved;
  final int? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  Alert({
    required this.alertId,
    required this.alertType,
    required this.title,
    this.message,
    required this.createdBy,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      alertId: json['alert_id'],
      alertType: json['alert_type'],
      title: json['title'],
      message: json['message'],
      createdBy: json['created_by'],
      isResolved: json['is_resolved'] == 1,
      resolvedBy: json['resolved_by'],
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Notification {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['notification_id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Add this to your existing models.dart file

class User {
  final int userId;
  final String email;
  final String role; // admin, driver, parent, student
  final String phone;
  final String firstName;
  final String lastName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.email,
    required this.role,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get fullName => '$firstName $lastName';
}
