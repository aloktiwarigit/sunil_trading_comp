// =============================================================================
// UpiIntentBuilder — constructs a UPI deep link URI per C3.5.
//
// The UPI deep link format:
//   upi://pay?pa={vpa}&pn={name}&am={amount}&tn={note}&cu=INR
//
// Triple Zero invariant (C3.5 AC #8):
//   - am= MUST equal totalAmount EXACTLY (no service fee, no rounding)
//   - pa= MUST equal shop.upiVpa directly (no intermediate account)
//   - No fee / charge / mdr parameters in the URI
//
// This is a pure utility — no Firebase, no state, fully testable.
// =============================================================================

/// Builds a UPI payment intent URI.
///
/// Returns a [Uri] that can be launched via `url_launcher` to open the
/// user's preferred UPI app (PhonePe, GPay, Paytm, etc.).
class UpiIntentBuilder {
  UpiIntentBuilder._();

  /// Build the UPI deep link URI.
  ///
  /// [shopVpa] — the shopkeeper's UPI VPA (e.g. `sunil@oksbi`)
  /// [shopName] — display name for the payee (e.g. `Sunil Trading Company`)
  /// [totalAmount] — amount in rupees (not paise — UPI uses rupees)
  /// [projectId] — order reference for the transaction note
  ///
  /// Returns a `upi://pay?...` URI ready to be launched.
  static Uri build({
    required String shopVpa,
    required String shopName,
    required int totalAmount,
    required String projectId,
  }) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: <String, String>{
        'pa': shopVpa,
        'pn': shopName,
        'am': totalAmount.toStringAsFixed(2),
        'tn': 'Order $projectId',
        'cu': 'INR',
      },
    );
  }
}
