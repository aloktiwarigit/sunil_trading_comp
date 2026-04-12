// =============================================================================
// formatInr — Indian Rupee formatting with lakh/thousand separators.
//
// Centralised from 20+ duplicate `_formatInr` copies across both apps.
// Pattern: 1,50,000 (not 150,000).
// =============================================================================

/// Format an integer amount into Indian Rupee notation with comma grouping.
///
/// Examples:
/// - `formatInr(999)` → `'999'`
/// - `formatInr(1000)` → `'1,000'`
/// - `formatInr(150000)` → `'1,50,000'`
/// - `formatInr(-22000)` → `'-22,000'`
String formatInr(int amount) {
  if (amount < 0) return '-${formatInr(-amount)}';
  final s = amount.toString();
  if (s.length <= 3) return s;
  final lastThree = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buffer = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i != 0 && (rest.length - i) % 2 == 0) {
      buffer.write(',');
    }
    buffer.write(rest[i]);
  }
  return '$buffer,$lastThree';
}
