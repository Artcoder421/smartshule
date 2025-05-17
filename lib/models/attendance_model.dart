import 'package:flutter/material.dart';

class User {
  final int id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool isActive;
  final String? lastLocation;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.isActive = false,
    this.lastLocation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      isActive: (json['is_active'] as int?) == 1,
      lastLocation: json['last_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'last_location': lastLocation,
    };
  }
}

class Routes {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final String stops;
  final int? driverId;
  final int? busId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driverName;

  Routes({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    this.driverId,
    this.busId,
    required this.createdAt,
    required this.updatedAt,
    this.driverName,
  });

  factory Routes.fromJson(Map<String, dynamic> json) {
    return Routes(
      id: json['id'] as int,
      name: json['name'] as String,
      startPoint: json['start_point'] as String,
      endPoint: json['end_point'] as String,
      stops: json['stops'] as String,
      driverId: json['driver_id'] as int?,
      busId: json['bus_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      driverName: json['driver_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_point': startPoint,
      'end_point': endPoint,
      'stops': stops,
      'driver_id': driverId,
      'bus_id': busId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Student {
  final int id;
  final String regNumber;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String gradeLevel;
  final int parentId;
  final String? address;
  final String? photoUrl;
  final String? medicalNotes;
  final String? emergencyContact;
  final bool isActive;

  Student({
    required this.id,
    required this.regNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.gradeLevel,
    required this.parentId,
    this.address,
    this.photoUrl,
    this.medicalNotes,
    this.emergencyContact,
    this.isActive = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      regNumber: json['registration_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      gradeLevel: json['grade_level'] as String,
      parentId: json['parent_id'] as int,
      address: json['address'] as String?,
      photoUrl: json['photo'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      isActive: (json['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': regNumber,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'grade_level': gradeLevel,
      'parent_id': parentId,
      'address': address,
      'photo': photoUrl,
      'medical_notes': medicalNotes,
      'emergency_contact': emergencyContact,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class AttendanceRecord {
  final int id;
  final int studentId;
  final int routeId;
  final DateTime date;
  final String status;
  final TimeOfDay? checkInTime;
  final TimeOfDay? checkOutTime;
  final int recordedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    this.id = 0,
    required this.studentId,
    required this.routeId,
    required this.date,
    this.status = 'absent',
    this.checkInTime,
    this.checkOutTime,
    this.recordedBy = 0, // Default to system user
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      routeId: json['route_id'] as int? ?? 0,
      date: DateTime.parse(
        json['date'] as String? ?? DateTime.now().toString(),
      ),
      status: json['status'] as String? ?? 'absent',
      checkInTime:
          json['check_in_time'] != null
              ? _parseTime(json['check_in_time'] as String)
              : null,
      checkOutTime:
          json['check_out_time'] != null
              ? _parseTime(json['check_out_time'] as String)
              : null,
      recordedBy: json['recorded_by'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  static TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'route_id': routeId,
      'date': date.toIso8601String(),
      'status': status,
      'check_in_time':
          checkInTime != null
              ? '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}'
              : null,
      'check_out_time':
          checkOutTime != null
              ? '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}'
              : null,
      'recorded_by': recordedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RouteTracking {
  final int id;
  final int routeId;
  final String status;
  final DateTime timestamp;

  RouteTracking({
    required this.id,
    required this.routeId,
    required this.status,
    required this.timestamp,
  });

  factory RouteTracking.fromJson(Map<String, dynamic> json) {
    return RouteTracking(
      id: json['id'] as int,
      routeId: json['route_id'] as int,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
