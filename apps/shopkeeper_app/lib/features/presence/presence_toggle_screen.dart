// =============================================================================
// PresenceToggleScreen — B1.9 AC #3: shopkeeper toggles presence status.
//
// 4 states: available / away / busy_with_customer / at_event
// Each has a Devanagari message + optional return time.
// B1.10 AC #4: record away voice note from here.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// Presence status options per B1.9 AC #1.
enum PresenceStatus {
  available('दुकान पर हैं', Icons.storefront),
  away('बाहर हैं', Icons.directions_walk),
  busyWithCustomer('ग्राहक के साथ', Icons.people),
  atEvent('शादी / कार्यक्रम में', Icons.celebration);

  const PresenceStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// B1.9 — Presence status toggle screen.
class PresenceToggleScreen extends ConsumerStatefulWidget {
  const PresenceToggleScreen({super.key});

  @override
  ConsumerState<PresenceToggleScreen> createState() =>
      _PresenceToggleScreenState();
}

class _PresenceToggleScreenState extends ConsumerState<PresenceToggleScreen> {
  PresenceStatus _selected = PresenceStatus.available;
  final _returnTimeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _returnTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          'मेरी उपलब्धता',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status options
            ...PresenceStatus.values.map((status) {
              final isSelected = _selected == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
                child: InkWell(
                  onTap: () => setState(() => _selected = status),
                  borderRadius: BorderRadius.circular(YugmaRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(YugmaSpacing.s4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? YugmaColors.primary.withValues(alpha: 0.08)
                          : YugmaColors.surface,
                      borderRadius: BorderRadius.circular(YugmaRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? YugmaColors.primary
                            : YugmaColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(status.icon, color: YugmaColors.primary, size: 24),
                        const SizedBox(width: YugmaSpacing.s3),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontFamily: YugmaFonts.devaBody,
                            fontSize: YugmaTypeScale.body,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: YugmaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Return time (for away/atEvent)
            if (_selected != PresenceStatus.available) ...[
              const SizedBox(height: YugmaSpacing.s2),
              TextField(
                controller: _returnTimeController,
                decoration: InputDecoration(
                  labelText: 'कितने बजे तक वापस?',
                  labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
                  hintText: '6 बजे',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                ),
              ),
            ],

            const Spacer(),

            // Save button
            SizedBox(
              width: double.infinity,
              height: YugmaSpacing.s12,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YugmaColors.primary,
                  foregroundColor: YugmaColors.textOnPrimary,
                  textStyle: TextStyle(
                    fontFamily: YugmaFonts.devaBody,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: YugmaColors.textOnPrimary,
                        ),
                      )
                    : const Text('अपडेट कीजिए'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final shopId = ref.read(shopIdProviderProvider).shopId;

    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .set(<String, dynamic>{
        'presenceStatus': _selected.name,
        'presenceMessage': _selected.label,
        'presenceReturnTime': _returnTimeController.text.trim(),
        'presenceUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('उपलब्धता अपडेट हुई')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
