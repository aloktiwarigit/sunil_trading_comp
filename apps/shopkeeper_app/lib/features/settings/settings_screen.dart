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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  final AppStrings _strings = const AppStringsHi();

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
    final strings = _strings;

    return Scaffold(
      backgroundColor: YugmaColors.background,
      appBar: AppBar(
        backgroundColor: YugmaColors.primary,
        foregroundColor: YugmaColors.textOnPrimary,
        title: Text(
          strings.settingsTitle,
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
        _sectionHeader(strings.settingsShopInfo),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField(strings.settingsTaglineHindi, _taglineDevaController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('Tagline (English)', _taglineEnController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField(strings.settingsGst, _gstController),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField(strings.settingsWhatsapp, _whatsappController,
            keyboardType: TextInputType.phone),
        const SizedBox(height: YugmaSpacing.s2),
        _buildTextField('UPI VPA', _upiVpaController),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 2: Branding ----
        _sectionHeader(strings.settingsBranding),
        const SizedBox(height: YugmaSpacing.s2),
        // Greeting voice note — link to B1.8
        _actionTile(
          icon: Icons.record_voice_over,
          label: strings.settingsChangeGreeting,
          onTap: () => context.push('/greeting'),
        ),
        const SizedBox(height: YugmaSpacing.s2),
        // D-10: Color picker tile
        _actionTile(
          icon: Icons.palette,
          label: strings.settingsColorPicker,
          onTap: () => _showColorPicker(context, tokens, shopId),
        ),
        const SizedBox(height: YugmaSpacing.s2),
        // D-10: Face photo upload tile
        _actionTile(
          icon: Icons.face,
          label: strings.settingsFaceUpload,
          onTap: () => _pickAndUploadFace(shopId),
        ),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 3: Feature Flags ----
        _sectionHeader(strings.settingsFeatures),
        const SizedBox(height: YugmaSpacing.s2),
        _featureFlagInfo(strings.settingsDecisionCircle, true),
        _featureFlagInfo('Guest Mode', true),
        _featureFlagInfo('OTP at Commit', true),
        _featureFlagInfo('In-app Chat', true),
        const SizedBox(height: YugmaSpacing.s1),
        Text(
          strings.settingsRemoteConfigNote,
          style: TextStyle(
            fontFamily: YugmaFonts.devaBody,
            fontSize: YugmaTypeScale.caption,
            color: YugmaColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- Section 4: Operators ----
        _sectionHeader(strings.settingsOperators),
        const SizedBox(height: YugmaSpacing.s2),
        _operatorsSection(shopId, strings),
        const SizedBox(height: YugmaSpacing.s4),

        // ---- S4.19: Shop closure option ----
        _sectionHeader(strings.shopClosureSettingsOption),
        const SizedBox(height: YugmaSpacing.s2),
        _actionTile(
          icon: Icons.power_settings_new,
          label: strings.shopClosureSettingsOption,
          color: YugmaColors.commit,
          onTap: () => context.push('/deactivate'),
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
                : Text(strings.settingsSave),
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

  Widget _operatorsSection(String shopId, AppStrings strings) {
    final currentUid =
        ref.read(opsAuthControllerProvider).valueOrNull?.user?.uid;
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
          children: [
            ...docs.map((doc) {
              final data = doc.data();
              final name = data['displayName'] as String? ?? doc.id;
              final role = data['role'] as String? ?? 'unknown';
              final isSelf = doc.id == currentUid;
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
                    // D-10: Remove button (bhaiya-only, hidden for self per
                    // firestore.rules)
                    if (!isSelf)
                      IconButton(
                        onPressed: () => _removeOperator(shopId, doc.id),
                        icon: Icon(Icons.close,
                            color: YugmaColors.textMuted, size: 18),
                        tooltip: strings.settingsRemoveOperator,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),
            // D-10: Add operator button
            const SizedBox(height: YugmaSpacing.s2),
            _actionTile(
              icon: Icons.person_add,
              label: strings.settingsAddOperator,
              onTap: () => _addOperator(shopId),
            ),
          ],
        );
      },
    );
  }

  // ---- D-10: Color picker ----
  void _showColorPicker(
    BuildContext context,
    ShopThemeTokens tokens,
    String shopId,
  ) {
    final currentHex = tokens.primaryColorHex;
    Color pickerColor =
        Color(int.parse('FF${currentHex.replaceAll('#', '')}', radix: 16));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _strings.settingsColorPicker,
          style: TextStyle(fontFamily: YugmaFonts.devaBody),
        ),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings.draftQtyHighCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final hexString =
                  '#${pickerColor.value.toRadixString(16).substring(2).toUpperCase()}';
              await FirebaseFirestore.instance
                  .collection('shops')
                  .doc(shopId)
                  .collection('theme')
                  .doc('current')
                  .set(<String, dynamic>{
                'primaryColorHex': hexString,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.primary,
            ),
            child: Text(
              _strings.settingsSave,
              style: TextStyle(color: YugmaColors.textOnPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ---- D-10: Face photo upload ----
  Future<void> _pickAndUploadFace(String shopId) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final storageRef =
        FirebaseStorage.instance.ref('shops/$shopId/branding/face.jpg');
    await storageRef.putData(bytes);
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('theme')
        .doc('current')
        .set(<String, dynamic>{
      'shopkeeperFaceUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.settingsSaved)),
      );
    }
  }

  // ---- D-10: Add operator ----
  // SK006 fix: use a proper Firebase UID-based docId (email serves as lookup
  // context, not docId). SK007 fix: add role dropdown (beta/munshi).
  Future<void> _addOperator(String shopId) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    var selectedRole = 'beta'; // Default to beta (nephew) per playbook
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            _strings.settingsAddOperator,
            style: TextStyle(fontFamily: YugmaFonts.devaBody),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SK007 fix: role dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'beta', child: Text('Beta (बेटा)')),
                  DropdownMenuItem(
                      value: 'munshi', child: Text('Munshi (मुंशी)')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? 'beta'),
              ),
              const SizedBox(height: YugmaSpacing.s3),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: YugmaSpacing.s2),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_strings.draftQtyHighCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: YugmaColors.primary,
              ),
              child: Text(
                _strings.settingsAddOperator,
                style: TextStyle(color: YugmaColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ), // StatefulBuilder
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      // SK006 fix: use a timestamp-based docId so auth lookup by UID works.
      // The email is stored as a field for human reference, not as docId.
      // When the operator signs in via Google, the signupNewOperator Cloud
      // Function will create a proper doc keyed by their Firebase UID.
      // This pre-registration doc serves as an invitation marker.
      final operatorId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('operators')
          .doc(operatorId)
          .set(<String, dynamic>{
        'displayName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'status': 'pending_invite',
        'addedAt': FieldValue.serverTimestamp(),
        'shopId': shopId,
      });
    }
    nameController.dispose();
    emailController.dispose();
  }

  // ---- D-10: Remove operator ----
  // SK008 fix: add confirmation dialog before destructive action.
  Future<void> _removeOperator(String shopId, String operatorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _strings.settingsRemoveOperator,
          style: TextStyle(fontFamily: YugmaFonts.devaBody),
        ),
        content: Text(
          _strings.settingsRemoveOperatorConfirm,
          style: TextStyle(fontFamily: YugmaFonts.devaBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_strings.draftQtyHighCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: YugmaColors.error,
            ),
            child: Text(
              _strings.settingsRemoveOperator,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('operators')
        .doc(operatorId)
        .delete();
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
          SnackBar(content: Text(_strings.settingsSaved)),
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
