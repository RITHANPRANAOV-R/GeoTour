import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class IncidentLogsScreen extends StatefulWidget {
  const IncidentLogsScreen({super.key});

  @override
  State<IncidentLogsScreen> createState() => _IncidentLogsScreenState();
}

class _IncidentLogsScreenState extends State<IncidentLogsScreen> {
  final AdminAPIService _apiService = AdminAPIService();
  List<dynamic> _incidents = [];
  List<dynamic> _filteredIncidents = [];
  bool _isLoading = true;
  String _filter = "All";

  final List<String> _filterOptions = ["All", "Accident", "Threat", "Geo-Fence Violation", "Medical Alert"];

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
      _filteredIncidents = _incidents;
      _isLoading = false;
    });
  }

  void _applyFilter(String? value) {
    if (value == null) return;
    setState(() {
      _filter = value;
      if (_filter == "All") {
        _filteredIncidents = _incidents;
      } else {
        _filteredIncidents = _incidents.where((incident) => incident['type']?.toString().toLowerCase() == _filter.toLowerCase()).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incident Logs"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchIncidents),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Text("Filter Logs:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      items: _filterOptions.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: _applyFilter,
                      isExpanded: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIncidents.isEmpty
                    ? const Center(child: Text("No incidents logged."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredIncidents.length,
                        itemBuilder: (context, index) {
                          final log = _filteredIncidents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(log['type'] ?? 'default').withOpacity(0.1),
                                child: Icon(Icons.description_outlined, color: _getStatusColor(log['type'] ?? 'default')),
                              ),
                              title: Text("${log['type']} - ${log['user']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(log['timestamp'] ?? 'Recently'),
                              trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
      case 'accident': return Colors.orange;
      case 'threat': return Colors.red;
      case 'geo-fence violation': return Colors.purple;
      case 'medical alert': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
