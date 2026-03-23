import 'package:flutter/material.dart';

enum AlertSeverity { low, medium, high, extreme }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final AlertSeverity severity;
  final double lat;
  final double lng;
  final String status;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.severity,
    this.lat = 0.0,
    this.lng = 0.0,
    this.status = 'pending',
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.green.shade300;
      case AlertSeverity.medium:
        return Colors.yellow.shade300;
      case AlertSeverity.high:
      case AlertSeverity.extreme:
        return Colors.red.shade300;
    }
  }
}
