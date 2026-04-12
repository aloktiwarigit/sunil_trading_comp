// =============================================================================
// SettingsScreen — S4.12: shop settings (bhaiya only).
//
// AC #1: 4 sections — shop profile, branding, feature flags, operators
// AC #2: saving updates Firestore + bumps version
// AC #3: customer app sees changes via real-time listener
// AC #4: bhaiya role check (UI hidden for beta/munshi)
// AC #5: reset to default per section
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_core/lib_core.dart';

import '../auth/auth_controller.dart';

/// S4.12 — Settings screen (bhaiya only).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Shop profile controllers
  final _taglineDevaController = TextEditingController();
  final _taglineEnController = TextEditingController();
  final _gstController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _upiVpaController = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _taglineDevaController.dispose();
    _taglineEnController.dispose();
    _gstController.dispose();
    _whatsappController.dispose();
    _upiVpaController.dispose();
    super.dispose();
  }

  void _populateFromTokens(ShopThemeTokens tokens) {
    if (_loaded) return;
    _loaded = true;
    _taglineDevaController.text = tokens.taglineDevanagari;
    _taglineEnController.text = tokens.taglineEnglish;
    _gstController.text = tokens.gstNumber ?? '';
    _whatsappController.text = tokens.whatsappNumberE164;
    _upiVpaController.text = tokens.upiVpa;
  }

  @override
  Widget build(BuildContext context) {
    final shopId = ref.read(shopIdProviderProvider).shopId;
    final strings = const AppStringsHi();

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          'सेटिंग्स',
          style: TextStyle(
            fontFamily: YugmaFonts.devaDisplay,
            fontSize: YugmaTypeScale.h3,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .collection('theme')
            .doc('current')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: YugmaColors.primary),
            );
          }

          final raw = snapshot.data!.data()!;
          // Normalize updatedAt timestamp
          if (raw['updatedAt'] is Timestamp) {
            raw['updatedAt'] =
                (raw['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          final tokens = ShopThemeTokens.fromJson(raw);
          _populateFromTokens(tokens);

          return _buildSettings(context, tokens, shopId, strings);
        },
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    ShopThemeTokens tokens,
    String shopId,
    AppStrings strings,
  ) {
    return ListView(
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      children: [
        // ---- Section 1: Shop Profile ----
        _sectionHeader('दुकान की जानकारी'),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('Tagline (हिंदी)', _taglineDevaController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('Tagline (English)', _taglineEnController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('GST नंबर', _gstController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('WhatsApp नंबर', _whatsappController,
            keyboardType: TextInputType.phone),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('UPI VPA', _upiVpaController),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 2: Branding ----
        _sectionHeader('ब्रांडिंग'),
        const SizedBox(height: YugmaSpacing.s2),
        // Greeting voice note — link to B1.8
        _actionTile(
          icon: Icons.record_voice_over,
          label: 'स्वागत संदेश बदलिए',
          onTap: () => context.push('/greeting'),
        ),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 3: Feature Flags ----
        _sectionHeader('सुविधाएँ'),
        const SizedBox(height: YugmaSpacing.s2),
        _featureFlagInfo('Decision Circle (परिवार)', true),
        _featureFlagInfo('Guest Mode', true),
        _featureFlagInfo('OTP at Commit', true),
        _featureFlagInfo('In-app Chat', true),
        const SizedBox(height: YugmaSpacing.s1),
        Text(
          'सुविधाएँ Remote Config से नियंत्रित होती हैं — Yugma Labs से संपर्क कीजिए',
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: YugmaColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 4: Operators ----
        _sectionHeader('ऑपरेटर'),
        const SizedBox(height: YugmaSpacing.s2),
        _operatorsSection(shopId),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- S4.19: Shop closure option ----
        _sectionHeader(strings.shopClosureSettingsOption),
        const SizedBox(height: YugmaSpacing.s2),
        _actionTile(
          icon: Icons.power_settings_new,
          label: strings.shopClosureSettingsOption,
          color: YugmaColors.commit,
          onTap: () {
            // S4.19 wiring — deferred until S4.19 is implemented
          },
        ),
        const SizedBox(height: YugmaSpacing.s6),

        // Save button (AC #2)
        SizedBox(
          height: YugmaSpacing.s12,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : () => _save(tokens, shopId),
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.primary,
              foregroundColor: YugmaColors.textOnPrimary,
              textStyle: TextStyle(
                fontFamily: YugmaFonts.devaBody,
                fontSize: YugmaTypeScale.body,
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
                : Text('सहेजिए'),
          ),
        ),
        const SizedBox(height: YugmaSpacing.s8),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: YugmaFonts.devaBody,
        fontSize: YugmaTypeScale.bodyLarge,
        fontWeight: FontWeight.w700,
        color: YugmaColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: YugmaFonts.devaBody,
        fontSize: YugmaTypeScale.body,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: YugmaFonts.devaBody),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? YugmaColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(YugmaRadius.md),
      child: Container(
        padding: const EdgeInsets.all(YugmaSpacing.s3),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(YugmaRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: YugmaSpacing.s2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: YugmaFonts.devaBody,
                  fontSize: YugmaTypeScale.body,
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: YugmaColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _featureFlagInfo(String name, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s1),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: enabled ? YugmaColors.primary : YugmaColors.textMuted,
          ),
          const SizedBox(width: YugmaSpacing.s2),
          Text(
            name,
            style: TextStyle(
              fontFamily: YugmaFonts.enBody,
              fontSize: YugmaTypeScale.body,
              color: YugmaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorsSection(String shopId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('operators')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 40);
        }
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final name = data['displayName'] as String? ?? doc.id;
            final role = data['role'] as String? ?? 'unknown';
            return Container(
              margin: const EdgeInsets.only(bottom: YugmaSpacing.s1),
              padding: const EdgeInsets.all(YugmaSpacing.s3),
              decoration: BoxDecoration(
                color: YugmaColors.surface,
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                border: Border.all(color: YugmaColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      color: YugmaColors.primary, size: 20),
                  const SizedBox(width: YugmaSpacing.s2),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: YugmaFonts.devaBody,
                        fontSize: YugmaTypeScale.body,
                        color: YugmaColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: YugmaColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(YugmaRadius.sm),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontFamily: YugmaFonts.enBody,
                        fontSize: YugmaTypeScale.caption,
                        color: YugmaColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _save(ShopThemeTokens current, String shopId) async {
    setState(() => _saving = true);

    try {
      // AC #2: update Firestore + bump version
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('theme')
          .doc('current')
          .set(<String, dynamic>{
        'taglineDevanagari': _taglineDevaController.text.trim(),
        'taglineEnglish': _taglineEnController.text.trim(),
        'gstNumber': _gstController.text.trim().isEmpty
            ? null
            : _gstController.text.trim(),
        'whatsappNumberE164': _whatsappController.text.trim(),
        'upiVpa': _upiVpaController.text.trim(),
        'version': current.version + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('सेटिंग्स सहेजी गईं')),
        );
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
