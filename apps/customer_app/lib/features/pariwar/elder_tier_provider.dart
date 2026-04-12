// =============================================================================
// ElderTierProvider — P2.3: derives elder UI tier from persona state.
//
// AC #1: when currentActivePersona is elder, rebuild ThemeData with:
//   - 1.4× text, 1.5× animation, larger photos, louder volume, 56dp tap targets
// AC #2: smooth 300ms animated transition
// AC #3: return to default reverses changes
// AC #4: font weight stays consistent
//
// The provider simply reads the persona state and returns a bool.
// The actual theme construction reads this bool to set isElderTier on
// YugmaThemeExtension.fromTokens().
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'persona_toggle.dart';

/// Whether the elder UI tier should be active.
/// Derived from the current persona — elder personas trigger the tier.
final isElderTierProvider = Provider<bool>((ref) {
  final personaState = ref.watch(personaProvider);
  return personaState.isElder;
});
