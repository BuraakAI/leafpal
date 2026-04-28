import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyPaywallShown = 'paywall_shown';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> isPaywallShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPaywallShown) ?? false;
  }

  static Future<void> setPaywallShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPaywallShown, true);
  }
}
