import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isPremium = false;
  bool _hasLifetime = false;
  String _subscriptionType = 'none'; // 'none', 'monthly', 'yearly'

  bool get isPremium => _isPremium;
  bool get hasLifetime => _hasLifetime;
  String get subscriptionType => _subscriptionType;

  PremiumProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _hasLifetime = _prefs?.getBool('hasLifetime') ?? false;
    _subscriptionType = _prefs?.getString('subscriptionType') ?? 'none';
    _isPremium = _hasLifetime || _subscriptionType != 'none';
    notifyListeners();
  }

  /// Simulates a Google Play Billing checkout flow.
  Future<bool> purchasePremium(String type) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network billing delay
    
    _prefs = await SharedPreferences.getInstance();
    if (type == 'lifetime') {
      _hasLifetime = true;
      await _prefs?.setBool('hasLifetime', true);
    } else {
      _subscriptionType = type; // 'monthly' or 'yearly'
      await _prefs?.setString('subscriptionType', type);
    }
    _isPremium = true;
    notifyListeners();
    return true;
  }

  /// Simulates restoring purchase from Google Play account.
  Future<bool> restorePurchase() async {
    await Future.delayed(const Duration(seconds: 1));
    _prefs = await SharedPreferences.getInstance();
    // For simulation, we restore a mock lifetime purchase
    _hasLifetime = true;
    await _prefs?.setBool('hasLifetime', true);
    _isPremium = true;
    notifyListeners();
    return true;
  }

  /// Cancels subscription (simulated).
  Future<void> cancelSubscription() async {
    _prefs = await SharedPreferences.getInstance();
    _subscriptionType = 'none';
    _hasLifetime = false;
    _isPremium = false;
    await _prefs?.setBool('hasLifetime', false);
    await _prefs?.setString('subscriptionType', 'none');
    notifyListeners();
  }
}
