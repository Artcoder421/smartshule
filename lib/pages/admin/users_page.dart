// lib/pages/admin/users_page.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/api_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String _searchQuery = '';
  String _roleFilter = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final users = await _apiService.getUsers().timeout(
        const Duration(seconds: 30),
        onTimeout:
            () =>
                throw TimeoutException(
                  'Request timed out. Please check your internet connection.',
                ),
      );

      setState(() {
        _users = users;
        _filterUsers();
      });
    } on TimeoutException catch (e) {
      _handleError('Network timeout: ${e.message}');
    } on HttpException catch (e) {
      _handleError('Server error: ${e.message}');
    } on FormatException catch (e) {
      _handleError('Data format error: ${e.message}\nSource: ${e.source}');
    } on SocketException catch (_) {
      _handleError(
        'Network error: Unable to connect to server. Please check your internet connection.',
      );
    } catch (e) {
      _handleError('Unexpected error: ${_parseErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _users = [];
        _filteredUsers = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _parseErrorMessage(dynamic error) {
    try {
      if (error is Map<String, dynamic>) {
        return error['message'] ?? error['error'] ?? error.toString();
      }
      return error.toString().replaceAll('Exception:', '').trim();
    } catch (e) {
      return 'An unknown error occurred';
    }
  }

  void _filterUsers() {
    try {
      _filteredUsers =
          _users.where((user) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                user.fullName.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery);
            final matchesRole =
                _roleFilter == 'All' ||
                user.role.toLowerCase() == _roleFilter.toLowerCase();
            return matchesSearch && matchesRole;
          }).toList();
    } catch (e) {
      _handleError('Error filtering users: ${_parseErrorMessage(e)}');
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
                'User Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                onPressed: () => _showAddUserDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildRoleFilterChips(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) _buildErrorWidget(),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_isLoading && _errorMessage == null) _buildUserTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search users...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
          _filterUsers();
        });
      },
    );
  }

  Widget _buildRoleFilterChips() {
    return Wrap(
      spacing: 8,
      children:
          ['All', 'Admin', 'Driver', 'Parent', 'Teacher'].map((role) {
            return ChoiceChip(
              label: Text(role),
              selected: _roleFilter == role,
              onSelected: (selected) {
                setState(() {
                  _roleFilter = selected ? role : 'All';
                  _filterUsers();
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildUserTable() {
    if (_filteredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            _filteredUsers.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.fullName)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.role)),
                  DataCell(
                    Chip(
                      label: Text(user.isActive ? 'Active' : 'Inactive'),
                      backgroundColor:
                          user.isActive ? Colors.green[100] : Colors.red[100],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditUserDialog(context, user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDeleteUser(user),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    try {
      // Implement your add user dialog
      // After adding, call _loadUsers() to refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error showing add user dialog: ${_parseErrorMessage(e)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditUserDialog(BuildContext context, User user) async {
    try {
      // Implement your edit user dialog
      // After editing, call _loadUsers() to refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error showing edit dialog: ${_parseErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete ${user.fullName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteUser(user.userId);
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      setState(() => _isLoading = true);

      await _apiService
          .deleteUser(userId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout:
                () => throw TimeoutException('Delete operation timed out'),
          );

      setState(() {
        _users.removeWhere((user) => user.userId == userId);
        _filterUsers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on TimeoutException catch (e) {
      _handleError('Delete timeout: ${e.message}');
    } on FormatException catch (e) {
      // Replace with a valid exception type
      _handleError('Delete failed: ${e.message}');
    } catch (e) {
      _handleError('Delete error: ${_parseErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
