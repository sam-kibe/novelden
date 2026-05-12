import 'dart:math';

/// Introduces a human-like delay between web requests.
/// This reduces load on servers and helps avoid rate-limit blocks.
class DelayUtil {
  static final _rng = Random();

  /// Base 1.5s + up to 2.5s of random jitter = 1.5–4s range.
  static Future<void> humanDelay() async {
    final ms = 1500 + _rng.nextInt(2500);
    await Future.delayed(Duration(milliseconds: ms));
  }

  /// Shorter delay for paginated list fetching (not chapter content).
  static Future<void> listDelay() async {
    final ms = 800 + _rng.nextInt(1200);
    await Future.delayed(Duration(milliseconds: ms));
  }
}
