import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'geo_service.dart';

class LocationSuggestion {
  final String displayName;
  final LatLng point;

  LocationSuggestion({required this.displayName, required this.point});

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      point: LatLng(
        double.parse(json['lat'] ?? '0.0'),
        double.parse(json['lon'] ?? '0.0'),
      ),
    );
  }
}

class LocationService {
  static Future<List<LocationSuggestion>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    final currentPos = GeoService().currentPosition;
    String locationBias = "";

    if (currentPos != null) {
      double lat = currentPos.latitude;
      double lon = currentPos.longitude;
      double delta =
          1.0; // Increased to ~100km for wider city-wide landmark search
      locationBias =
          "&viewbox=${lon - delta},${lat + delta},${lon + delta},${lat - delta}&bounded=0";
    }

    // Increased limit to 50
    // Simplified params to avoid over-filtering
    // Prioritizing local names and landmarks
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=50'
      '&addressdetails=1'
      '&namedetails=1'
      '&countrycodes=in' // Focus on India
      '$locationBias',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'GeoTour-Location-Search-v2', // Updated contact-safe UA
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationSuggestion.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Location Search Error: $e');
    }
    return [];
  }
}
