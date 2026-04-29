// =============================================================================
// CommsChannelWhatsApp — wa.me fallback CommsChannel implementation.
//
// Activated when Remote Config `comms_channel_strategy` is flipped to
// `whatsapp_wa_me` per the R13 mitigation path in SAD ADR-005. The R13
// scenario is: WhatsApp "eats" the in-app Firestore chat (customers
// habituate to WhatsApp's unified notification surface and stop opening
// the bundled chat screen), at which point Yugma Dukaan pivots to treat
// its ops app as a WhatsApp-orchestration overlay instead of a chat app.
//
// This adapter is NOT a full WhatsApp Business API client. It builds a
// `wa.me` deep link with a prefilled Hindi message body and returns it as
// an [ExternalConversationHandle] for the UI to launch via url_launcher.
// There is NO programmatic send, NO observe, NO webhook ingest. If the
// client pays for WhatsApp Business Cloud API in v1.5+, that becomes a
// separate adapter implementation behind the same interface.
//
// **Free-features-only note:** wa.me deep links cost ₹0 — they are a
// standard WhatsApp feature that opens the native app with a prefilled
// message on Android + iOS + desktop. No API key, no subscription, no
// bill. Honors the "free features only" rule.
//
// This adapter duplicates the SAD §7 Function 2 (`generateWaMeLink`)
// client-side logic rather than calling the Cloud Function over HTTPS.
// Rationale:
//   1. The Cloud Function has no server-side secrets — it just reads
//      Firestore docs and builds a URL. Every input is already available
//      client-side.
//   2. Avoiding the Cloud Function dependency makes this adapter work in
//      Phase 1 before the Cloud Function deploys — no blocker.
//   3. When the Cloud Function deploys, swapping to a server-side call is
//      a one-line change inside [openConversation] if desired.
//
// See SAD §7 Function 2 for the canonical message body template.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/message.dart';
import '../utils/format_inr.dart';
import 'comms_channel.dart';

/// WhatsApp fallback — returns [ExternalConversationHandle] that wraps a
/// `wa.me` deep link with a Hindi prefilled message body.
class CommsChannelWhatsApp implements CommsChannel {
  /// Create the WhatsApp adapter. Takes a [FirebaseFirestore] instance so
  /// [openConversation] can read the Shop + Project documents to build the
  /// prefilled message with the same context SAD §7 Function 2 provides.
  CommsChannelWhatsApp({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static final Logger _log = Logger('CommsChannelWhatsApp');

  @override
  Future<ConversationHandle> openConversation({
    required String shopId,
    required String projectId,
  }) async {
    // Phase 1.9 code review cleanup (Agent A finding #4): explicit empty
    // string rejection FIRST — before the `/` + `..` path traversal checks.
    // Matches the CommsChannelFirestore validation exactly so both backends
    // reject the same set of malformed inputs.
    if (shopId.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.unauthorized,
        'shopId must not be empty',
      );
    }
    if (shopId.contains('/') || shopId.contains('..')) {
      throw CommsChannelException(
        CommsChannelErrorCode.unauthorized,
        'shopId contains illegal characters: $shopId',
      );
    }
    if (projectId.isEmpty) {
      throw const CommsChannelException(
        CommsChannelErrorCode.notFound,
        'projectId must not be empty',
      );
    }
    if (projectId.contains('/') || projectId.contains('..')) {
      throw CommsChannelException(
        CommsChannelErrorCode.notFound,
        'projectId contains illegal characters: $projectId',
      );
    }

    // Read Shop + Project — 2 reads against the per-session budget
    // (Standing Rule 1). Acceptable because wa.me fallback is an explicit
    // user action (tap to open external chat), not a background listener.
    final shopDoc = await _firestore.doc('shops/$shopId').get();
    if (!shopDoc.exists) {
      throw CommsChannelException(
        CommsChannelErrorCode.notFound,
        'Shop $shopId not found',
      );
    }
    final projectDoc =
        await _firestore.doc('shops/$shopId/projects/$projectId').get();
    if (!projectDoc.exists) {
      throw CommsChannelException(
        CommsChannelErrorCode.notFound,
        'Project $projectId not found in shop $shopId',
      );
    }

    final shop = shopDoc.data()!;
    final project = projectDoc.data()!;

    final whatsappRaw = (shop['whatsappNumber'] ?? '') as String;
    final phoneDigits = whatsappRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.isEmpty) {
      throw CommsChannelException(
        CommsChannelErrorCode.sendFailed,
        'Shop $shopId has no whatsappNumber configured',
      );
    }

    final displayName =
        (shop['displayName'] ?? shop['displayNameEnglish'] ?? shopId) as String;
    final totalAmount =
        _asInt(project['totalAmount'] ?? project['amountReceivedByShop']) ?? 0;
    final lineItemsCount = _asInt(project['lineItemsCount'] ??
            (project['lineItems'] as List?)?.length) ??
        0;

    final message = _buildHindiBody(
      shopDisplayName: displayName,
      projectIdShort: projectId.length <= 6
          ? projectId
          : projectId.substring(projectId.length - 6),
      totalAmount: totalAmount,
      lineItemsCount: lineItemsCount,
    );

    final encodedMessage = Uri.encodeComponent(message);
    final launchUri =
        Uri.parse('https://wa.me/$phoneDigits?text=$encodedMessage');

    _log.info(
      'openConversation (wa.me): shop=$shopId, project=$projectId, '
      'phone=$phoneDigits',
    );

    return ExternalConversationHandle(
      shopId: shopId,
      projectId: projectId,
      launchUri: launchUri,
      prefilledMessageHindi: message,
    );
  }

  @override
  Future<void> sendText({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String text,
  }) async {
    throw const CommsChannelException(
      CommsChannelErrorCode.notSupported,
      'sendText is not supported on the WhatsApp backend. The wa.me deep '
      'link launches the native WhatsApp app with a prefilled message — '
      'the customer types there, not here. Call openConversation and '
      'launch the returned ExternalConversationHandle.launchUri instead.',
    );
  }

  @override
  Future<void> sendVoiceNote({
    required String shopId,
    required String projectId,
    required String authorUid,
    required MessageAuthorRole authorRole,
    required String voiceNoteId,
    required int durationSeconds,
  }) async {
    throw const CommsChannelException(
      CommsChannelErrorCode.notSupported,
      'sendVoiceNote is not supported on the WhatsApp backend. Voice notes '
      'must be recorded in the native WhatsApp app after the wa.me link '
      'launches.',
    );
  }

  @override
  Stream<List<Message>> observeMessages({
    required String shopId,
    required String projectId,
  }) {
    return Stream<List<Message>>.error(
      const CommsChannelException(
        CommsChannelErrorCode.notSupported,
        'observeMessages is not supported on the WhatsApp backend. WhatsApp '
        'conversations are owned by the native app; this adapter only '
        'provides the launch URL.',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hindi message body (duplicates SAD §7 Function 2 logic)
  // ---------------------------------------------------------------------------

  /// Build the prefilled Hindi message body. Mirrors SAD §7 Function 2 —
  /// if the Cloud Function deploys and the team wants server-authoritative
  /// message construction, swap this out for an HttpsCallable invocation.
  ///
  /// **Vocabulary discipline:** this body uses plain Devanagari warmth
  /// words per Constraint 10. No mythic vocabulary (`शुभ / मंगल / मंदिर /
  /// धर्म / तीर्थ / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ`) — only `धन्यवाद`, plain
  /// nouns, and direct framing.
  static String _buildHindiBody({
    required String shopDisplayName,
    required String projectIdShort,
    required int totalAmount,
    required int lineItemsCount,
  }) {
    // Format INR with Western numerals per UX Spec §5.5 numerical guidance
    // (Devanagari numerals are used only for dates/ordinals, not prices).
    final formattedAmount = formatInr(totalAmount);

    return [
      '🛍️ $shopDisplayName',
      '',
      'ऑर्डर: $projectIdShort',
      'कुल: ₹$formattedAmount',
      'सामान: $lineItemsCount पीस',
      '',
      'नमस्ते! मेरा यह ऑर्डर है। कृपया मदद कीजिए।',
    ].join('\n');
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
