import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class UserAccessControlScreen extends StatefulWidget {
  const UserAccessControlScreen({super.key});

  @override
  State<UserAccessControlScreen> createState() => _UserAccessControlScreenState();
}

class _UserAccessControlScreenState extends State<UserAccessControlScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getUsers();
    setState(() {
      _users = data;
      _isLoading = false;
    });
  }

  void _showUserForm({Map<String, dynamic>? user}) {
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController(text: '');
    final roleController = TextEditingController(text: user?['role'] ?? 'tourist');
    final bool isEdit = user != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit User Access" : "Add New User Access"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email Address")),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              TextField(controller: roleController, decoration: const InputDecoration(labelText: "Role (admin, police, tourist, medical)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> userData = {
                "name": nameController.text,
                "email": emailController.text,
                "role": roleController.text,
              };
              if (passwordController.text.isNotEmpty) {
                userData["password"] = passwordController.text;
              }
              
              bool success;
              if (isEdit) {
                success = await _apiService.editUser(user['id'].toString(), userData);
              } else {
                success = await _apiService.addUser(userData);
              }
              if (success && mounted) {
                Navigator.pop(context);
                _fetchUsers();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoUsers() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> demoUsers = [
      {"name": "Master Admin", "email": "admin@geotour.ac.in", "role": "admin", "password": "admin@1234"},
      {"name": "Officer Kumar", "email": "police@geotour.ac.in", "role": "police", "password": "police@1234"},
      {"name": "Dr. Sarah", "email": "medical@geotour.ac.in", "role": "medical", "password": "medical@1234"},
      {"name": "Alex Explorer", "email": "tourist@geotour.ac.in", "role": "tourist", "password": "tourist@1234"},
    ];

    for (var user in demoUsers) {
      await _apiService.addUser(user);
    }
    
    _fetchUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demo users seeded successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User & Access Control"),
        actions: [
          IconButton(
            tooltip: "Seed Demo Users",
            icon: const Icon(Icons.group_add_rounded),
            onPressed: _seedDemoUsers,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("No users found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.blueGrey),
                        ),
                        title: Text(user['name'] ?? 'Guest User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Role: ${user['role']}\nEmail: ${user['email'] ?? 'N/A'}"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _showUserForm(user: user), icon: const Icon(Icons.edit_rounded, color: Colors.blue)),
                            IconButton(
                              onPressed: () async {
                                bool success = await _apiService.deleteUser(user['id'].toString());
                                if (success && mounted) _fetchUsers();
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text("Add User"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}
