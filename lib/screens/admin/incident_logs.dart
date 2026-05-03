import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'incident_details.dart';

class IncidentLogsScreen extends StatefulWidget {
  const IncidentLogsScreen({super.key});

  @override
  State<IncidentLogsScreen> createState() => _IncidentLogsScreenState();
}

class _IncidentLogsScreenState extends State<IncidentLogsScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getIncidents();
    setState(() {
      _incidents = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncidents = _incidents.where((log) {
      final filter = _selectedFilter.toLowerCase();
      if (filter == 'all') return true;

      final role = (log['responderRole'] ?? '').toString().toLowerCase();
      final type = (log['type'] ?? '').toString().toLowerCase();
      final details = (log['details'] ?? log['summary'] ?? '').toString().toLowerCase();

      // Final classification helper
      bool isMedical = role == 'medical' || 
                        type.contains('medical') || 
                        type.contains('hospital') ||
                        details.contains('medical') || 
                        details.contains('hospital') ||
                        details.contains('ambulance');
      
      bool isGeoFence = type.contains('geo-fence') || 
                         type.contains('violation') || 
                         details.contains('geo-fence');

      if (filter == 'medical') return isMedical;
      if (filter == 'geo-fence violation') return isGeoFence;
      if (filter == 'police') {
        // Police is anything NOT medical and NOT geofence
        return !isMedical && !isGeoFence;
      }

      return true;
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
          "Incident Logs",
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _fetchIncidents,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children:
                  [
                    {'key': 'all', 'label': 'All'},
                    {'key': 'police', 'label': 'Police (Threats/Accidents)'},
                    {'key': 'medical', 'label': 'Medical'},
                    {'key': 'geo-fence violation', 'label': 'Geo-Fence'},
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter['key'];
                    Color filterColor = Colors.black;
                    if (filter['key'] == 'police') filterColor = Colors.red;
                    if (filter['key'] == 'medical') filterColor = Colors.blue;
                    if (filter['key'] == 'geo-fence violation')
                      filterColor = Colors.purple;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : filterColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter['key']!);
                        },
                        backgroundColor: filterColor.withValues(alpha: 0.05),
                        selectedColor: filterColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? filterColor
                                : filterColor.withValues(alpha: 0.2),
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIncidents.isEmpty
                ? const Center(child: Text("No incidents logged."))
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredIncidents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = filteredIncidents[index];
                      final typeColor = _getStatusColor(
                        log['type'] ?? 'default',
                      );
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFAFAFA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F1F1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    IncidentDetailsScreen(incident: log),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              color: typeColor,
                            ),
                          ),
                          title: Text(
                            "${log['type']} - ${log['user']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              log['timestamp'] ?? 'Recently',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Colors.orange;
      case 'threat':
        return Colors.red;
      case 'geo-fence violation':
        return Colors.purple;
      case 'medical alert':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
