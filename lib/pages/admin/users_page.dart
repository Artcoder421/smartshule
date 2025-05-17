import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/api_service.dart';
import 'add_user_page.dart';
import 'register_students.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _apiService.getUsers();
      setState(() {
        _users = users;
        _filterUsers();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers =
          _users.where((user) {
            return _searchQuery.isEmpty ||
                user.fullName.toLowerCase().contains(_searchQuery) ||
                (user.email.toLowerCase().contains(_searchQuery));
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _filterUsers();
                  },
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
                _filterUsers();
              },
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null) Center(child: Text(_errorMessage!)),
          if (!_isLoading && _errorMessage == null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(user.fullName[0])),
                      title: Text(user.fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(user.role), Text(user.email)],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditUserDialog(context, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteUser(user),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addUser',
            child: const Icon(Icons.person_add),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
                          appBar: AppBar(title: const Text('Add New User')),
                          body: const UserCreationForm(),
                        ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'registerStudents',
            child: const Icon(Icons.school),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Register Students'),
                          ),
                          body: const RegisterStudentsPage(),
                        ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, User user) async {
    // Implement edit dialog
  }

  Future<void> _confirmDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Delete ${user.fullName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteUser(user.userId);
        _loadUsers(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
