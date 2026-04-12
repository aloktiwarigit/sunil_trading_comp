import 'package:cloud_firestore/cloud_firestore.dart';

/// Normalize Firestore Timestamp to ISO8601 string for Freezed JSON round-trip.
/// Duplicated copies existed in 7+ files — this is the canonical version.
Object? normalizeTimestamp(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  return value;
}
