import 'package:flutter/material.dart';
import '../../../models/hospital_model.dart';
import '../../../services/hospital_service.dart';

class TransferDialog extends StatefulWidget {
  final String currentHospitalId;
  const TransferDialog({super.key, required this.currentHospitalId});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final HospitalService _hospitalService = HospitalService();
  HospitalModel? _selectedHospital;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Transfer Case",
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select an active hospital to transfer this case to:",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<HospitalModel>>(
              stream: _hospitalService.getActiveHospitalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hospitals = snapshot.data
                        ?.where((h) => h.uid != widget.currentHospitalId)
                        .toList() ??
                    [];

                if (hospitals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No other active hospitals found.",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    bool isSelected = _selectedHospital?.uid == hospital.uid;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.red : Colors.grey.shade100,
                        child: Icon(
                          Icons.local_hospital_rounded,
                          color: isSelected ? Colors.white : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        hospital.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        hospital.category,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedHospital = hospital;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _selectedHospital == null
              ? null
              : () => Navigator.pop(context, _selectedHospital),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: const Text("Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
