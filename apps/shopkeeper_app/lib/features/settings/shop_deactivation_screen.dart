// =============================================================================
// ShopDeactivationScreen — S4.19: shopkeeper-triggered shop deactivation.
//
// Dignified 3-tap confirmation flow. Bhaiya only.
// AC #1: section in settings, AC #2: informational page, AC #3: reason dropdown,
// AC #4: final confirmation, AC #5: write Shop lifecycle, AC #8: reversibility.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

/// S4.19 — Shop deactivation flow.
class ShopDeactivationScreen extends ConsumerStatefulWidget {
  const ShopDeactivationScreen({super.key});

  @override
  ConsumerState<ShopDeactivationScreen> createState() =>
      _ShopDeactivationScreenState();
}

class _ShopDeactivationScreenState
    extends ConsumerState<ShopDeactivationScreen> {
  int _step = 0; // 0=info, 1=reason, 2=confirm
  String _selectedReason = '';
  bool _processing = false;

  static const _reasons = <String>[
    'रिटायर हो रहे हैं',
    'दुकान बंद हो रही है',
    'ऐप काम नहीं आ रहा',
    'और कारण',
  ];

  @override
  Widget build(BuildContext context) {
    final strings = const AppStringsHi();

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.commit,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.shopClosureSettingsOption,
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        child: switch (_step) {
          0 => _buildInfoStep(strings),
          1 => _buildReasonStep(),
          _ => _buildConfirmStep(strings),
        },
      ),
    );
  }

  // Step 0: AC #2 — informational page
  Widget _buildInfoStep(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: YugmaColors.commit, size: 48),
        const SizedBox(height: YugmaSpacing.s4),
        Text(
          'दुकान बंद करने का मतलब:',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.bodyLarge,
            fontWeight: FontWeight.w700,
            color: YugmaColors.textPrimary,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s3),
        _bulletPoint('सभी ग्राहकों को सूचना जाएगी'),
        _bulletPoint('चल रहे ऑर्डर रुक जाएंगे'),
        _bulletPoint('उधार खाते फ़्रीज़ हो जाएंगे'),
        _bulletPoint('डेटा 180 दिन तक सुरक्षित रहेगा'),
        const Spacer(),
        Text(
          strings.shopClosureReversibilityFooter,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: YugmaColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s4),
        SizedBox(
          width: double.infinity,
          height: YugmaSpacing.s12,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.commit,
              foregroundColor: YugmaColors.textOnPrimary,
              textStyle: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
              ),
            ),
            child: const Text('आगे बढ़िए'),
          ),
        ),
      ],
    );
  }

  // Step 1: AC #3 — reason selection
  Widget _buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'बंद करने की वजह?',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.bodyLarge,
            fontWeight: FontWeight.w700,
            color: YugmaColors.textPrimary,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s3),
        ..._reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
              child: InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(YugmaSpacing.s3),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedReason == reason
                          ? YugmaColors.commit
                          : YugmaColors.divider,
                      width: _selectedReason == reason ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                    color: _selectedReason == reason
                        ? YugmaColors.commit.withValues(alpha: 0.08)
                        : YugmaColors.surface,
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontFamily: YugmaFonts.devaBody,
                      fontSize: YugmaTypeScale.body,
                      color: YugmaColors.textPrimary,
                    ),
                  ),
                ),
              ),
            )),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: YugmaSpacing.s12,
          child: ElevatedButton(
            onPressed: _selectedReason.isNotEmpty
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.commit,
              foregroundColor: YugmaColors.textOnPrimary,
              disabledBackgroundColor: YugmaColors.divider,
              textStyle: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
              ),
            ),
            child: const Text('आगे बढ़िए'),
          ),
        ),
      ],
    );
  }

  // Step 2: AC #4 — final confirmation
  Widget _buildConfirmStep(AppStrings strings) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.power_settings_new, color: YugmaColors.commit, size: 64),
        const SizedBox(height: YugmaSpacing.s4),
        Text(
          'पक्का बंद कर रहे हैं?',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.h3,
            fontWeight: FontWeight.w700,
            color: YugmaColors.commit,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s2),
        Text(
          'वजह: $_selectedReason',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.body,
            color: YugmaColors.textSecondary,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s2),
        Text(
          strings.shopClosureReversibilityFooter,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: YugmaColors.textMuted,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s8),
        SizedBox(
          width: double.infinity,
          height: YugmaSpacing.s12,
          child: ElevatedButton(
            onPressed: _processing ? null : _executeDeactivation,
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.commit,
              foregroundColor: YugmaColors.textOnPrimary,
              textStyle: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
              ),
            ),
            child: _processing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: YugmaColors.textOnPrimary,
                    ),
                  )
                : const Text('हाँ, बंद कीजिए'),
          ),
        ),
        const SizedBox(height: YugmaSpacing.s3),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'नहीं, वापस जाइए',
            style: TextStyle(
              fontFamily: YugmaFonts.devaBody,
              color: YugmaColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: YugmaColors.commit, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
                color: YugmaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AC #5: write Shop lifecycle + AC #7: audit trail
  Future<void> _executeDeactivation() async {
    setState(() => _processing = true);
    final shopId = ref.read(shopIdProviderProvider).shopId;

    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .set(<String, dynamic>{
        'shopLifecycle': 'deactivating',
        'shopLifecycleChangedAt': FieldValue.serverTimestamp(),
        'shopLifecycleReason': _selectedReason,
        'dpdpRetentionUntil': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 180)),
        ),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('दुकान बंद होने की प्रक्रिया शुरू हुई')),
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
      if (mounted) setState(() => _processing = false);
    }
  }
}
