// =============================================================================
// DeactivationBanner — C3.12 AC #1 + #6: persistent Devanagari banner when
// shop lifecycle is deactivating or purge_scheduled.
//
// Renders above all other content. Text comes from AppStrings.
//
// AC #1: shopLifecycle "deactivating" → banner with retention days.
// AC #6: shopLifecycle "purge_scheduled" → updated banner with days to purge.
// AC #7: "डेटा export कीजिए" button links to B1.13 receipt generation.
// AC #5: FAQ screen accessible from the banner.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lib_core/lib_core.dart';

/// C3.12 — Shop deactivation banner.
///
/// Displayed when [shopLifecycle] is `deactivating` or `purgeScheduled`.
/// Hidden when `active` or `purged`.
class DeactivationBanner extends StatelessWidget {
  const DeactivationBanner({
    super.key,
    required this.shopLifecycle,
    required this.dpdpRetentionUntil,
    required this.strings,
    this.onFaqTap,
    this.onExportTap,
  });

  final ShopLifecycle shopLifecycle;
  final DateTime? dpdpRetentionUntil;
  final AppStrings strings;
  final VoidCallback? onFaqTap;
  final VoidCallback? onExportTap;

  @override
  Widget build(BuildContext context) {
    if (shopLifecycle == ShopLifecycle.active ||
        shopLifecycle == ShopLifecycle.purged) {
      return const SizedBox.shrink();
    }

    final theme = context.yugmaTheme;
    final now = DateTime.now();
    final retentionDays = dpdpRetentionUntil != null
        ? dpdpRetentionUntil!.difference(now).inDays.clamp(0, 999)
        : 180;

    final bannerText = shopLifecycle == ShopLifecycle.purgeScheduled
        ? strings.shopPurgeScheduledBanner(retentionDays)
        : strings.shopDeactivatingBanner(retentionDays);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s4,
        vertical: YugmaSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: theme.shopCommit.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: theme.shopCommit.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner text
          Text(
            bannerText,
            style: theme.bodyDeva.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.shopCommit,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          // Action row
          Row(
            children: [
              // FAQ link (AC #5)
              if (onFaqTap != null)
                InkWell(
                  onTap: onFaqTap,
                  child: Text(
                    strings.shopDeactivationFaqTitle,
                    style: theme.captionDeva.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.shopPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (onFaqTap != null && onExportTap != null)
                const SizedBox(width: YugmaSpacing.s4),
              // Data export CTA (AC #7)
              if (onExportTap != null)
                InkWell(
                  onTap: onExportTap,
                  child: Text(
                    strings.dataExportCta,
                    style: theme.captionDeva.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.shopPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// C3.12 AC #5: Simple FAQ screen accessible from the banner.
/// In-app Devanagari FAQ: what's happening, money/orders/udhaar status,
/// data retention, export option. No legal jargon; plain Hindi.
class DeactivationFaqScreen extends StatelessWidget {
  const DeactivationFaqScreen({
    super.key,
    required this.strings,
    required this.retentionDays,
    this.onExportTap,
  });

  final AppStrings strings;
  final int retentionDays;
  final VoidCallback? onExportTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopPrimary,
        foregroundColor: theme.shopTextOnPrimary,
        title: Text(
          strings.shopDeactivationFaqTitle,
          style: theme.h2Deva.copyWith(
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _faqItem(context,
              'दुकान क्यों बंद हो रही है?',
              'सुनील भैया ने दुकान बंद करने का फ़ैसला किया है। '
                  'यह उनका निजी फ़ैसला है।',
            ),
            _faqItem(context,
              'मेरे पैसे का क्या होगा?',
              'अगर आपने भुगतान किया है और ऑर्डर पूरा नहीं हुआ, '
                  'तो आपका पैसा वापस आ जाएगा।',
            ),
            _faqItem(context,
              'मेरे ऑर्डर का क्या होगा?',
              'चल रहे ऑर्डर रुक गए हैं। अगर सुनील भैया ने '
                  'पहले ही बना दिया है, तो डिलीवरी होगी।',
            ),
            _faqItem(context,
              'उधार खाता?',
              'आपका उधार खाता जैसा है वैसा रहेगा — रुका हुआ। '
                  'कोई नया भुगतान नहीं माँगा जाएगा।',
            ),
            _faqItem(context,
              'मेरा डेटा कब तक सुरक्षित है?',
              'आपका डेटा $retentionDays दिन तक सुरक्षित है। '
                  'उसके बाद हटा दिया जाएगा।',
            ),
            const SizedBox(height: YugmaSpacing.s4),
            if (onExportTap != null)
              SizedBox(
                width: double.infinity,
                height: YugmaSpacing.s12,
                child: ElevatedButton.icon(
                  onPressed: onExportTap,
                  icon: const Icon(Icons.download_outlined, size: 20),
                  label: Text(strings.dataExportCta),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.shopPrimary,
                    foregroundColor: theme.shopTextOnPrimary,
                    textStyle: theme.bodyDeva.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YugmaRadius.md),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    final theme = context.yugmaTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.bodyDeva.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.shopTextPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s1),
          Text(
            answer,
            style: theme.bodyDeva.copyWith(
              color: theme.shopTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
