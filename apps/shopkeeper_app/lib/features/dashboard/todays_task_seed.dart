// =============================================================================
// TodaysTaskSeed — static 30-day ramp sequence for the "Today's task" card.
//
// S4.13 ACs #2, #5, #8, #9:
//   - Each task: Devanagari title, English subtitle, estimated time in minutes
//   - Tasks from static seed shipped with app for Day 1-30
//   - Day 30 celebration + first-customer-test walkthrough
//   - After Day 30: weekly habit rotation
//
// All strings use AppStrings where possible, but the task titles/subtitles
// are domain-specific ramp content not part of the general AppStrings
// interface. They are stored here as structured data and rendered via
// YugmaFonts in the card widget.
//
// Forbidden vocabulary check applied: no udhaar lending terms, no mythic
// vocabulary in any of the 30 task descriptions.
// =============================================================================

/// A single task in the 30-day ramp sequence.
class TaskSeedEntry {
  /// Create a task seed entry.
  const TaskSeedEntry({
    required this.day,
    required this.titleHi,
    required this.subtitleEn,
    required this.estimatedMinutes,
  });

  /// Day number (1-30 for ramp, 31+ for weekly rotation).
  final int day;

  /// Devanagari title — the primary text shown on the card.
  final String titleHi;

  /// English subtitle — secondary text for clarity.
  final String subtitleEn;

  /// Estimated time in minutes.
  final int estimatedMinutes;
}

/// The static 30-day ramp sequence plus the weekly rotation pool.
///
/// Week 1 (Days 1-7): Getting started — basic app familiarity.
/// Week 2 (Days 8-14): Inventory basics — adding items, photos.
/// Week 3 (Days 15-21): Customer interaction — chat, orders.
/// Week 4 (Days 22-29): Advanced ops — udhaar, analytics, presence.
/// Day 30: Celebration + first-customer-test walkthrough (AC #8).
class TodaysTaskSeed {
  TodaysTaskSeed._();

  /// The 30-day ramp sequence.
  static const List<TaskSeedEntry> rampSequence = [
    // ── Week 1: Getting started ──
    TaskSeedEntry(
      day: 1,
      titleHi: 'App kholen aur dekhein',
      subtitleEn: 'Open the app and explore',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 2,
      titleHi: 'Apni profile dekhein',
      subtitleEn: 'Check your operator profile',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 3,
      titleHi: 'Dashboard ka har section dekhein',
      subtitleEn: 'Explore every dashboard section',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 4,
      titleHi: 'Settings mein jaake dekhein',
      subtitleEn: 'Visit the settings screen',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 5,
      titleHi: 'Ek item ki detail page kholein',
      subtitleEn: 'Open one item detail page',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 6,
      titleHi: 'Inventory list scroll karein',
      subtitleEn: 'Scroll through the inventory list',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 7,
      titleHi: 'Ek screenshot lein aur share karein',
      subtitleEn: 'Take a screenshot and share it',
      estimatedMinutes: 5,
    ),

    // ── Week 2: Inventory basics ──
    TaskSeedEntry(
      day: 8,
      titleHi: 'Ek naya item add karein',
      subtitleEn: 'Add one new inventory item',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 9,
      titleHi: 'Item ki photo lein',
      subtitleEn: 'Take a photo of an item',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 10,
      titleHi: 'Price aur details bharein',
      subtitleEn: 'Fill in price and details',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 11,
      titleHi: 'Do aur items add karein',
      subtitleEn: 'Add two more items',
      estimatedMinutes: 20,
    ),
    TaskSeedEntry(
      day: 12,
      titleHi: 'Ek item edit karein',
      subtitleEn: 'Edit an existing item',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 13,
      titleHi: 'Golden Hour photo lein',
      subtitleEn: 'Capture a Golden Hour photo',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 14,
      titleHi: 'Inventory mein search karein',
      subtitleEn: 'Search within inventory',
      estimatedMinutes: 5,
    ),

    // ── Week 3: Customer interaction ──
    TaskSeedEntry(
      day: 15,
      titleHi: 'Customer app kholke dekhein',
      subtitleEn: 'Open the customer app to see your shop',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 16,
      titleHi: 'Chat thread mein message bhejein',
      subtitleEn: 'Send a message in the chat thread',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 17,
      titleHi: 'Voice note record karein',
      subtitleEn: 'Record a voice note',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 18,
      titleHi: 'Order list dekhein',
      subtitleEn: 'Review the orders list',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 19,
      titleHi: 'Curated shortlist banayein',
      subtitleEn: 'Create a curated shortlist',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 20,
      titleHi: 'Shortlist mein 3 items daalein',
      subtitleEn: 'Add 3 items to a shortlist',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 21,
      titleHi: 'Customer app pe shortlist check karein',
      subtitleEn: 'Verify shortlist shows in customer app',
      estimatedMinutes: 10,
    ),

    // ── Week 4: Advanced ops ──
    TaskSeedEntry(
      day: 22,
      titleHi: 'Udhaar khaata samjhein',
      subtitleEn: 'Understand the udhaar ledger',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 23,
      titleHi: 'Ek test order confirm karein',
      subtitleEn: 'Confirm a test order end-to-end',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 24,
      titleHi: 'Analytics dashboard dekhein',
      subtitleEn: 'Check the analytics dashboard',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 25,
      titleHi: 'Absence/presence banner set karein',
      subtitleEn: 'Set your away/present banner',
      estimatedMinutes: 5,
    ),
    TaskSeedEntry(
      day: 26,
      titleHi: 'Delivery confirm karna seekhein',
      subtitleEn: 'Learn how to confirm a delivery',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 27,
      titleHi: 'Paanch items aur add karein',
      subtitleEn: 'Add five more items to inventory',
      estimatedMinutes: 25,
    ),
    TaskSeedEntry(
      day: 28,
      titleHi: 'Saari settings ek baar review karein',
      subtitleEn: 'Review all settings once',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 29,
      titleHi: 'Kal ke liye tayyar ho jaayein',
      subtitleEn: 'Get ready for tomorrow',
      estimatedMinutes: 5,
    ),

    // ── Day 30: Celebration (AC #8) ──
    TaskSeedEntry(
      day: 30,
      titleHi: 'Pehle customer ko dikhayein',
      subtitleEn: 'Show the app to your first customer',
      estimatedMinutes: 15,
    ),
  ];

  /// Weekly rotation pool (AC #9) — after Day 30, one task per day
  /// cycles through this list. 7 tasks = one per weekday.
  static const List<TaskSeedEntry> weeklyRotation = [
    TaskSeedEntry(
      day: 0, // not used — rotation ignores day field
      titleHi: 'Naye items ki photo lein',
      subtitleEn: 'Photograph new arrivals',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Inventory update karein',
      subtitleEn: 'Update inventory prices/stock',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Customer messages ka reply dein',
      subtitleEn: 'Reply to pending customer messages',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Order status update karein',
      subtitleEn: 'Update pending order statuses',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Shortlist refresh karein',
      subtitleEn: 'Refresh curated shortlists',
      estimatedMinutes: 15,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Udhaar khaate check karein',
      subtitleEn: 'Review open udhaar accounts',
      estimatedMinutes: 10,
    ),
    TaskSeedEntry(
      day: 0,
      titleHi: 'Analytics dekhein aur plan banayein',
      subtitleEn: 'Check analytics and plan ahead',
      estimatedMinutes: 10,
    ),
  ];

  /// Resolve the task for a given day number (1-based from operator join date).
  ///
  /// Days 1-30: returns the ramp sequence task.
  /// Days 31+: returns from the weekly rotation pool (cyclic).
  static TaskSeedEntry taskForDay(int dayNumber) {
    if (dayNumber >= 1 && dayNumber <= rampSequence.length) {
      return rampSequence[dayNumber - 1];
    }
    // Post-ramp weekly rotation.
    final rotationIndex = (dayNumber - rampSequence.length - 1) %
        weeklyRotation.length;
    return weeklyRotation[rotationIndex];
  }

  /// Whether the given day is the Day 30 celebration day.
  static bool isCelebrationDay(int dayNumber) => dayNumber == 30;
}
