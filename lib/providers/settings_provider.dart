import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  bool _isDarkMode = true;
  String _accentColor = 'Classic Blue';
  int _autoLockDuration = 60; // Default 1 minute in seconds

  bool get isDarkMode => _isDarkMode;
  String get accentColor => _accentColor;
  int get autoLockDuration => _autoLockDuration;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? true;
    _accentColor = _prefs?.getString('accentColor') ?? 'Classic Blue';
    _autoLockDuration = _prefs?.getInt('autoLockDuration') ?? 60;
    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    _isDarkMode = dark;
    await _prefs?.setBool('isDarkMode', dark);
    notifyListeners();
  }

  Future<void> setAccentColor(String colorName) async {
    _accentColor = colorName;
    await _prefs?.setString('accentColor', colorName);
    notifyListeners();
  }

  Future<void> setAutoLockDuration(int seconds) async {
    _autoLockDuration = seconds;
    await _prefs?.setInt('autoLockDuration', seconds);
    notifyListeners();
  }

  // Backup / Restore placeholders for local operations
  Future<bool> createLocalBackup(List<String> filesToBackup) async {
    // Mimic backup process with a brief delay
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<bool> restoreLocalBackup(String backupPath) async {
    // Mimic restore process with a brief delay
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
