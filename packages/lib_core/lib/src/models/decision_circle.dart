// =============================================================================
// DecisionCircle — Freezed model for
//   /shops/{shopId}/decision_circles/{projectId}.
//
// Per SAD §5 DecisionCircle (optional schema) + ADR-009.
// Feature-flagged via `decisionCircleEnabled`.
//
// The DecisionCircle is the Pariwar pillar's core primitive — it tracks
// which family member is currently looking at the phone and maintains a
// participant history. It is OPTIONAL: deleting it does not affect the
// Project (per ADR-009 AC #5).
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'decision_circle.freezed.dart';
part 'decision_circle.g.dart';

/// A participant session in the decision circle.
@freezed
class DecisionCircleParticipant with _$DecisionCircleParticipant {
  const factory DecisionCircleParticipant({
    required String sessionId,
    required String personaLabel,
    String? deviceId,
    DateTime? lastSeenAt,
  }) = _DecisionCircleParticipant;

  factory DecisionCircleParticipant.fromJson(Map<String, dynamic> json) =>
      _$DecisionCircleParticipantFromJson(json);
}

/// The DecisionCircle document.
@freezed
class DecisionCircle with _$DecisionCircle {
  const factory DecisionCircle({
    required String projectId,
    required String shopId,
    required String primaryCustomerUid,

    /// Participant sessions — each one represents a persona who has
    /// looked at this project on this device.
    @Default(<DecisionCircleParticipant>[])
    List<DecisionCircleParticipant> participants,

    /// The currently active persona label — updated when the device-holder
    /// switches personas via P2.2 toggle. Shopkeeper sees this in the
    /// project detail to know who is currently looking.
    String? currentActivePersona,

    required DateTime createdAt,
  }) = _DecisionCircle;

  factory DecisionCircle.fromJson(Map<String, dynamic> json) =>
      _$DecisionCircleFromJson(json);
}
