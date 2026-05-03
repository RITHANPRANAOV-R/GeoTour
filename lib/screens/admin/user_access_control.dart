import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../services/user_service.dart';
import '../../widgets/premium_toast.dart';

class UserAccessControlScreen extends StatefulWidget {
  const UserAccessControlScreen({super.key});

  @override
  State<UserAccessControlScreen> createState() =>
      _UserAccessControlScreenState();
}

class _UserAccessControlScreenState extends State<UserAccessControlScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'police':
        return Colors.blue;
      case 'medical':
      case 'hospital':
        return Colors.teal;
      case 'tourist':
      default:
        return Colors.orange;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

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
    String selectedRole = user?['role'] ?? 'tourist';
    final bool isEdit = user != null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isEdit
                                          ? Icons.edit_note_rounded
                                          : Icons.person_add_rounded,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    isEdit ? "Edit Access" : "Grant Access",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: -0.5,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildDialogField(
                                nameController,
                                "Full Name",
                                Icons.person_outline_rounded,
                              ),
                              _buildDialogField(
                                emailController,
                                "Email Address",
                                Icons.email_outlined,
                              ),
                              _buildDialogField(
                                passwordController,
                                "Password",
                                Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              const Text(
                                "User Role",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      'admin',
                                      'police',
                                      'medical',
                                      'tourist'
                                    ].map((r) {
                                      final isSelected = selectedRole == r;
                                      final rColor = _getRoleColor(r);
                                      return GestureDetector(
                                        onTap: () => setDialogState(
                                            () => selectedRole = r),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? rColor
                                                : rColor.withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? rColor
                                                  : rColor.withValues(
                                                      alpha: 0.2),
                                            ),
                                          ),
                                          child: Text(
                                            r.toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : rColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.black38,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final nav = Navigator.of(context);
                                        Map<String, dynamic> userData = {
                                          "name": nameController.text,
                                          "email": emailController.text,
                                          "role": selectedRole,
                                        };
                                        if (passwordController
                                            .text
                                            .isNotEmpty) {
                                          userData["password"] =
                                              passwordController.text;
                                        }

                                        bool success;
                                        if (isEdit) {
                                          success = await _apiService.editUser(
                                            user['id'].toString(),
                                            userData,
                                          );
                                        } else {
                                          success = await _apiService.addUser(
                                            userData,
                                          );
                                        }
                                        if (success && mounted) {
                                          nav.pop();
                                          _fetchUsers();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Save",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.black54),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _seedDemoUsers() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> demoUsers = [
      {
        "name": "Master Admin",
        "email": "admin@geotour.ac.in",
        "role": "admin",
        "password": "admin@1234",
      },
      {
        "name": "Officer Kumar",
        "email": "police@geotour.ac.in",
        "role": "police",
        "password": "police@1234",
      },
      {
        "name": "Dr. Sarah",
        "email": "medical@geotour.ac.in",
        "role": "medical",
        "password": "medical@1234",
      },
      {
        "name": "Alex Explorer",
        "email": "tourist@geotour.ac.in",
        "role": "tourist",
        "password": "tourist@1234",
      },
    ];

    for (var user in demoUsers) {
      await _apiService.addUser(user);
    }

    _fetchUsers();
    if (mounted) {
      PremiumToast.show(
        context,
        title: "Database Seeded",
        message: "Demo users have been successfully added to the system.",
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      if (_selectedFilter == 'all') return true;
      final role = user['role']?.toString().toLowerCase() ?? 'tourist';
      return role == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "User & Access Control",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Seed Demo Users",
            icon: const Icon(Icons.group_add_rounded, color: Colors.blue),
            onPressed: _seedDemoUsers,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['all', 'admin', 'police', 'medical', 'tourist'].map((filter) {
                final isSelected = _selectedFilter == filter;
                final filterColor = filter == 'all' ? Colors.black : _getRoleColor(filter);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : filterColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: filterColor.withValues(alpha: 0.05),
                    selectedColor: filterColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? filterColor : filterColor.withValues(alpha: 0.2),
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          "No users found.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                final role = user['role']?.toString().toLowerCase() ?? 'tourist';
                final roleColor = _getRoleColor(role);
                final isBlocked = user['isBlocked'] ?? false;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isBlocked ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFF1F1F1),
                      width: isBlocked ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: isBlocked ? 0.6 : 1.0,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: roleColor.withValues(alpha: 0.1),
                          child: Text(
                            _getInitials(user['name'] ?? user['email'] ?? '?'),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['name'] ?? 'Guest User',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: -0.5,
                                        decoration: isBlocked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  if (isBlocked)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "BLOCKED",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user['email'] ?? 'N/A',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionIcon(
                            icon: isBlocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: isBlocked ? Colors.red : Colors.green,
                            onTap: () async {
                              await UserService().toggleUserBlock(user['id'].toString(), !isBlocked);
                              if (mounted) {
                                PremiumToast.show(
                                  context,
                                  title: isBlocked ? "User Unblocked" : "User Blocked",
                                  message: "The user has been successfully ${isBlocked ? 'unblocked' : 'blocked'}.",
                                  type: isBlocked ? ToastType.success : ToastType.warning,
                                );
                                _fetchUsers();
                              }
                            },
                            tooltip: isBlocked ? "Unblock" : "Block",
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.edit_note_rounded,
                            color: Colors.blue,
                            onTap: () => _showUserForm(user: user),
                            tooltip: "Edit",
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            onTap: () async {
                              bool success = await _apiService.deleteUser(user['id'].toString());
                              if (success && mounted) _fetchUsers();
                            },
                            tooltip: "Delete",
                          ),
                        ],
                      ),
                    ], // Closes main Row children
                  ), // Closes main Row
                ), // Closes Opacity
              ); // Closes AnimatedContainer
            },
          ), // Closes ListView.separated
        ), // Closes Expanded
      ],
    ), // Closes Column
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          "New User",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const StadiumBorder(),
      ),
    );
  }
}
