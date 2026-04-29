import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../locale/strings_base.dart';
import '../theme/tokens.dart';
import '../theme/yugma_theme_extension.dart';

/// Maps FirebaseException codes to friendly Hindi error messages.
/// Logs raw error details to console for debugging.
class YugmaErrorBanner extends StatelessWidget {
  final Object error;

  const YugmaErrorBanner({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final message = _resolveMessage(error);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(YugmaSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.shopCommit, size: 48),
            SizedBox(height: YugmaSpacing.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodyDeva.copyWith(color: theme.shopTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String _resolveMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return 'इंटरनेट नहीं है — जुड़ने पर दोबारा कोशिश करेंगे';
        case 'permission-denied':
          return 'अनुमति नहीं है';
        case 'not-found':
          return 'यह जानकारी नहीं मिली';
        default:
          return 'कुछ गड़बड़ हो गयी — दोबारा कोशिश कीजिए';
      }
    }
    return 'कुछ गड़बड़ हो गयी — दोबारा कोशिश कीजिए';
  }
}
