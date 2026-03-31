import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/premium_toast.dart';

class PoliceProfileScreen extends StatefulWidget {
  const PoliceProfileScreen({super.key});

  @override
  State<PoliceProfileScreen> createState() => _PoliceProfileScreenState();
}

class _PoliceProfileScreenState extends State<PoliceProfileScreen> {
  bool isLoading = false;
  bool _isChanged = false;
  
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController badgeController = TextEditingController();
  final TextEditingController rankController = TextEditingController();
  final TextEditingController stationController = TextEditingController();
  final TextEditingController divisionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController stationAddressController = TextEditingController();
  final TextEditingController stationPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('police')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? user.displayName ?? "";
          badgeController.text = data['badgeNumber'] ?? "";
          rankController.text = data['rank'] ?? "";
          stationController.text = data['station'] ?? "";
          divisionController.text = data['division'] ?? "";
          phoneController.text = data['personalPhone'] ?? "";
          stationAddressController.text = data['stationAddress'] ?? "";
          stationPhoneController.text = data['stationPhone'] ?? "";
        });
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty || badgeController.text.isEmpty || stationController.text.isEmpty) {
      PremiumToast.show(
        context,
        title: "Required Fields Missing",
        message: "Name, Badge, and Station are required.",
        type: ToastType.warning,
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('police')
            .doc(user.uid)
            .set({
          'name': nameController.text.trim(),
          'badgeNumber': badgeController.text.trim(),
          'rank': rankController.text.trim(),
          'station': stationController.text.trim(),
          'division': divisionController.text.trim(),
          'personalPhone': phoneController.text.trim(),
          'stationAddress': stationAddressController.text.trim(),
          'stationPhone': stationPhoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Sync with base users collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': nameController.text.trim(),
        });

        if (mounted) {
          PremiumToast.show(
            context,
            title: "Officer Profile Saved",
            message: "Your credentials have been securely verified.",
            type: ToastType.success,
          );
          setState(() => _isChanged = false);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          PremiumToast.show(
            context,
            title: "Save Failed",
            message: "An error occurred. Please try again.",
            type: ToastType.error,
          );
        }
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF8F9FA), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        title: const Text(
          "Officer Profile",
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.w900, 
            fontSize: 24,
            letterSpacing: -1.0
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Officer Info Card
            _buildNativeSection("Officer Credentials", Icons.badge_outlined, [
              _buildNativeInput("Full Name", nameController, Icons.person_outline_rounded),
              _buildNativeInput("Badge Number", badgeController, Icons.military_tech_outlined),
              _buildNativeInput("Rank / Designation", rankController, Icons.stars_outlined),
              _buildNativeInput("Personal Phone", phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
            ]),
            const SizedBox(height: 20),

            // Station Information
            _buildNativeSection("Station Assignment", Icons.location_city_outlined, [
              _buildNativeInput("Police Station Name", stationController, Icons.account_balance_rounded),
              _buildNativeInput("Division / District", divisionController, Icons.map_outlined),
              _buildNativeInput("Station Phone", stationPhoneController, Icons.local_phone_rounded, keyboardType: TextInputType.phone),
              _buildNativeInput("Station Address", stationAddressController, Icons.location_on_rounded, maxLines: 2),
            ]),
            const SizedBox(height: 32),

            // Bottom Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isChanged ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "SAVE CHANGES",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F1F1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children.asMap().entries.map((entry) {
            int idx = entry.key;
            return Column(
              children: [
                entry.value,
                if (idx < children.length - 1) const Divider(height: 32, color: Color(0xFFF1F1F1)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNativeInput(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
              prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey.shade300),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() => _isChanged = true),
          ),
        ),
      ],
    );
  }
}
