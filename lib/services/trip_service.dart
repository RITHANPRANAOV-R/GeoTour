import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripService extends ChangeNotifier {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Stream<List<TripModel>> get tripsStream {
    if (_currentUserId == null) return Stream.value([]);

    return _db
        .collection('trips')
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<TripModel>> get activeAndUpcomingTripsStream {
    return tripsStream.map(
      (trips) => trips.where((t) => t.status != TripStatus.completed).toList(),
    );
  }

  Stream<List<TripModel>> get completedTripsStream {
    return tripsStream.map(
      (trips) => trips.where((t) => t.status == TripStatus.completed).toList(),
    );
  }

  bool _hasActiveTrip = false;
  bool get hasActiveTrip => _hasActiveTrip;

  // Internal listener to update hasActiveTrip status
  void initStatusListener() {
    activeAndUpcomingTripsStream.listen((trips) {
      _hasActiveTrip = trips.any((t) => t.status == TripStatus.active);
      notifyListeners();
    });
  }

  Future<void> addTrip(TripModel trip) async {
    if (_currentUserId == null) return;
    await _db.collection('trips').add(trip.toFirestore());
  }

  Future<void> endTrip(String id) async {
    await _db.collection('trips').doc(id).update({
      'status': TripStatus.completed.name,
    });
  }

  Future<void> startTrip(String id) async {
    // Check if any trip is already active
    final activeSnapshot = await _db
        .collection('trips')
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: TripStatus.active.name)
        .get();

    if (activeSnapshot.docs.isNotEmpty) return;

    await _db.collection('trips').doc(id).update({
      'status': TripStatus.active.name,
    });
  }

  // Legacy static checks for screens that don't use streams yet
  Future<bool> checkActiveTrip() async {
    if (_currentUserId == null) return false;
    final snapshot = await _db
        .collection('trips')
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: TripStatus.active.name)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
