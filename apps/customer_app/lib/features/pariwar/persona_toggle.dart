// =============================================================================
// PersonaToggle — P2.2 Guest Mode persona toggle.
//
// AC #1: persistent button bottom-right, labeled with current persona
// AC #2: tapping opens sheet with persona options
// AC #3: selecting a persona changes the UI tier
// AC #4: current persona displayed in top bar
// AC #5: stored in SharedPreferences, survives restarts
// AC #6: updates DecisionCircle.currentActivePersona in Firestore
// AC #7: hidden when guestModeEnabled is false
// Edge #2: "Someone else" allows custom label (max 20 chars)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persona options — domain-grounded per P2.2 AC #2.
enum Persona {
  me('मैं'),
  mummyJi('मम्मी जी'),
  papaJi('पापा जी'),
  bhabhi('भाभी'),
  dadi('दादी'),
  chachaJi('चाचा जी'),
  other('कोई और');

  const Persona(this.label);
  final String label;

  /// Whether this persona triggers the elder UI tier (P2.3).
  bool get isElder => switch (this) {
        Persona.me => false,
        Persona.mummyJi => true,
        Persona.papaJi => true,
        Persona.bhabhi => false,
        Persona.dadi => true,
        Persona.chachaJi => true,
        Persona.other => false,
      };
}

/// Current persona state — stored in SharedPreferences.
class PersonaState {
  const PersonaState({
    required this.persona,
    this.customLabel,
  });

  final Persona persona;
  final String? customLabel;

  String get displayLabel =>
      persona == Persona.other && customLabel != null
          ? customLabel!
          : persona.label;

  bool get isElder => persona.isElder;
}

/// Provider for the current persona. Reads from SharedPreferences on init.
final personaProvider =
    StateNotifierProvider<PersonaNotifier, PersonaState>((ref) {
  return PersonaNotifier();
});

class PersonaNotifier extends StateNotifier<PersonaState> {
  PersonaNotifier() : super(const PersonaState(persona: Persona.me)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('persona_index') ?? 0;
    final customLabel = prefs.getString('persona_custom_label');
    if (index >= 0 && index < Persona.values.length) {
      state = PersonaState(
        persona: Persona.values[index],
        customLabel: customLabel,
      );
    }
  }

  Future<void> setPersona(Persona persona, {String? customLabel}) async {
    state = PersonaState(persona: persona, customLabel: customLabel);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('persona_index', persona.index);
    if (customLabel != null) {
      await prefs.setString('persona_custom_label', customLabel);
    } else {
      await prefs.remove('persona_custom_label');
    }
  }
}

/// P2.2 AC #1: floating persona toggle button.
/// Place this in a Stack at the bottom-right of every customer screen.
class PersonaToggleButton extends ConsumerWidget {
  const PersonaToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AC #7: hidden when guestModeEnabled is false.
    final guestModeEnabled = FirebaseRemoteConfig.instance.getBool('guest_mode_enabled');
    if (!guestModeEnabled) return const SizedBox.shrink();

    final personaState = ref.watch(personaProvider);

    return Positioned(
      right: YugmaSpacing.s4,
      bottom: YugmaSpacing.s4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPersonaSheet(context, ref),
          borderRadius: BorderRadius.circular(YugmaRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: YugmaSpacing.s3,
              vertical: YugmaSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: YugmaColors.surface,
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
              boxShadow: YugmaShadows.card,
              border: Border.all(
                color: personaState.isElder
                    ? YugmaColors.accent
                    : YugmaColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: YugmaColors.primary,
                ),
                const SizedBox(width: YugmaSpacing.s1),
                Text(
                  personaState.displayLabel,
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontSize: YugmaTypeScale.caption,
                    fontWeight: FontWeight.w600,
                    color: YugmaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPersonaSheet(BuildContext context, WidgetRef ref) {
    final customLabelController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YugmaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YugmaRadius.lg),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final current = ref.read(personaProvider);

          return Padding(
            padding: const EdgeInsets.all(YugmaSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YugmaColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s3),
                Text(
                  'कौन देख रहा है?',
                  style: TextStyle(
                    fontFamily: YugmaFonts.devaDisplay,
                    fontSize: YugmaTypeScale.h3,
                    fontWeight: FontWeight.w700,
                    color: YugmaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: YugmaSpacing.s3),
                // Persona options
                Wrap(
                  spacing: YugmaSpacing.s2,
                  runSpacing: YugmaSpacing.s2,
                  children: Persona.values.map((p) {
                    final isSelected = current.persona == p;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        p.label,
                        style: TextStyle(
                          fontFamily: YugmaFonts.devaBody,
                          fontSize: YugmaTypeScale.body,
                        ),
                      ),
                      selectedColor:
                          YugmaColors.primary.withValues(alpha: 0.15),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        if (p == Persona.other) {
                          // Edge #2: show custom label input
                          setSheetState(() {});
                        } else {
                          ref.read(personaProvider.notifier).setPersona(p);
                          Navigator.of(ctx).pop();
                        }
                      },
                    );
                  }).toList(),
                ),
                // Edge #2: custom label for "Someone else"
                if (current.persona == Persona.other ||
                    Persona.other ==
                        Persona.values[Persona.other.index]) ...[
                  const SizedBox(height: YugmaSpacing.s3),
                  TextField(
                    controller: customLabelController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: 'नाम लिखिए',
                      hintStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ref
                            .read(personaProvider.notifier)
                            .setPersona(Persona.other, customLabel: value.trim());
                        Navigator.of(ctx).pop();
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// P2.2 AC #4: persona indicator for the top bar.
class PersonaAppBarIndicator extends ConsumerWidget {
  const PersonaAppBarIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestModeEnabled = FirebaseRemoteConfig.instance.getBool('guest_mode_enabled');
    if (!guestModeEnabled) return const SizedBox.shrink();

    final personaState = ref.watch(personaProvider);
    if (personaState.persona == Persona.me) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s2,
        vertical: YugmaSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: YugmaColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
      ),
      child: Text(
        personaState.displayLabel,
        style: TextStyle(
          fontFamily: YugmaFonts.devaBody,
          fontSize: YugmaTypeScale.caption,
          fontWeight: FontWeight.w600,
          color: YugmaColors.textOnPrimary,
        ),
      ),
    );
  }
}
