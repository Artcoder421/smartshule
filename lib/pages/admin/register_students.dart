import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class RegisterStudentsPage extends StatefulWidget {
  const RegisterStudentsPage({Key? key}) : super(key: key);

  @override
  State<RegisterStudentsPage> createState() => _RegisterStudentsPageState();
}

class Parent {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String fullName;

  Parent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.fullName,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName:
          json['full_name'] as String? ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}',
    );
  }
}

class _RegisterStudentsPageState extends State<RegisterStudentsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrl = 'http://192.168.1.154/smartshulebus_api/';

  // Form fields
  String _registrationNumber = '';
  String _firstName = '';
  String _lastName = '';
  DateTime? _dateOfBirth;
  String _gender = 'male';
  String _gradeLevel = '';
  int? _parentId;
  String _address = '';
  String _medicalNotes = '';
  String _emergencyContact = '';
  File? _photo;
  List<Parent> _parents = [];
  Parent? _selectedParent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadParents();
  }

  Future<void> _loadParents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${_apiUrl}get_parents.php'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _parents = jsonData.map((data) => Parent.fromJson(data)).toList();
        });
      } else {
        throw Exception('Failed to load parents: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading parents: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiUrl}register_student.php'),
      );

      // Add regular form fields
      request.fields['registration_number'] = _registrationNumber;
      request.fields['first_name'] = _firstName;
      request.fields['last_name'] = _lastName;
      request.fields['date_of_birth'] = _dateOfBirth?.toIso8601String() ?? '';
      request.fields['gender'] = _gender;
      request.fields['grade_level'] = _gradeLevel;
      request.fields['parent_id'] = _parentId?.toString() ?? '';
      request.fields['address'] = _address;
      request.fields['medical_notes'] = _medicalNotes;
      request.fields['emergency_contact'] = _emergencyContact;

      // Add photo if selected
      if (_photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _photo!.path),
        );
      }

      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        if (jsonResponse['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Registration failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading && _parents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Section
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    _photo != null
                                        ? Image.file(_photo!, fit: BoxFit.cover)
                                        : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).primaryColor,
                                  border: Border.all(
                                    color:
                                        Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Student Information Section
                      Text(
                        'Student Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Registration Number*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Required field'
                                    : null,
                        onChanged: (value) => _registrationNumber = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'First Name*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Required field'
                                          : null,
                              onChanged: (value) => _firstName = value,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Last Name*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Required field'
                                          : null,
                              onChanged: (value) => _lastName = value,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dateOfBirth != null
                                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                      : 'Select date',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items:
                            ['male', 'female', 'other']
                                .map(
                                  (gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(
                                      gender[0].toUpperCase() +
                                          gender.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _gender = value!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Grade Level*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Required field'
                                    : null,
                        onChanged: (value) => _gradeLevel = value,
                      ),

                      // Parent Information Section
                      const SizedBox(height: 32),
                      Text(
                        'Parent Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 17),
                      DropdownButtonFormField<Parent>(
                        value: _selectedParent,
                        decoration: InputDecoration(
                          labelText: 'Select Parent*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null ? 'Please select a parent' : null,
                        items:
                            _parents.map((parent) {
                              return DropdownMenuItem<Parent>(
                                value: parent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(parent.fullName),
                                    if (parent.email.isNotEmpty)
                                      Text(
                                        parent.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (Parent? newValue) {
                          setState(() {
                            _selectedParent = newValue;
                            _parentId = newValue?.id;
                          });
                        },
                        isExpanded: true,
                        hint: const Text('Select a parent'),
                        dropdownColor: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) => _address = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Medical Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _medicalNotes = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required field';
                          if (value!.length < 10) return 'Invalid phone number';
                          return null;
                        },
                        onChanged: (value) => _emergencyContact = value,
                      ),

                      // Submit Button
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submitForm,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'REGISTER STUDENT',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
