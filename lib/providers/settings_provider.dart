import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  static const _channel = MethodChannel('com.example.private_vault_calculator/security');

  bool _isDarkMode = true;
  String _accentColor = 'Classic Blue';
  int _autoLockDuration = 60; // Default 1 minute in seconds
  bool _screenshotProtection = true; // Default enabled
  bool _rootDetectionEnabled = true;
  int _failedAttemptsThreshold = 3;
  List<String> _intruderLogs = [];

  bool get isDarkMode => _isDarkMode;
  String get accentColor => _accentColor;
  int get autoLockDuration => _autoLockDuration;
  bool get screenshotProtection => _screenshotProtection;
  bool get rootDetectionEnabled => _rootDetectionEnabled;
  int get failedAttemptsThreshold => _failedAttemptsThreshold;
  List<String> get intruderLogs => _intruderLogs;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? true;
    _accentColor = _prefs?.getString('accentColor') ?? 'Classic Blue';
    _autoLockDuration = _prefs?.getInt('autoLockDuration') ?? 60;
    _screenshotProtection = _prefs?.getBool('screenshotProtection') ?? true;
    _rootDetectionEnabled = _prefs?.getBool('rootDetectionEnabled') ?? true;
    _failedAttemptsThreshold = _prefs?.getInt('failedAttemptsThreshold') ?? 3;
    _intruderLogs = _prefs?.getStringList('intruderLogs') ?? [];
    
    _applyScreenshotProtection();
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

  Future<void> setScreenshotProtection(bool enabled) async {
    _screenshotProtection = enabled;
    await _prefs?.setBool('screenshotProtection', enabled);
    await _applyScreenshotProtection();
    notifyListeners();
  }

  Future<void> setRootDetectionEnabled(bool enabled) async {
    _rootDetectionEnabled = enabled;
    await _prefs?.setBool('rootDetectionEnabled', enabled);
    notifyListeners();
  }

  Future<void> setFailedAttemptsThreshold(int count) async {
    _failedAttemptsThreshold = count;
    await _prefs?.setInt('failedAttemptsThreshold', count);
    notifyListeners();
  }

  Future<void> addIntruderLog(String logMessage) async {
    _intruderLogs.insert(0, logMessage);
    await _prefs?.setStringList('intruderLogs', _intruderLogs);
    notifyListeners();
  }

  Future<void> clearIntruderLogs() async {
    _intruderLogs.clear();
    await _prefs?.setStringList('intruderLogs', []);
    notifyListeners();
  }

  Future<void> _applyScreenshotProtection() async {
    try {
      await _channel.invokeMethod('secureScreen', {'secure': _screenshotProtection});
    } catch (e) {
      // Ignored on non-supported platforms (e.g. iOS/Windows simulation)
    }
  }

  /// Creates a local encrypted backup of all metadata and vault files.
  Future<bool> createLocalBackup() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docDir.path, 'vault_backup'));
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      // Copy metadata file
      final metaFile = File(p.join(docDir.path, 'vault_metadata.json'));
      if (await metaFile.exists()) {
        await metaFile.copy(p.join(backupDir.path, 'vault_metadata.json'));
      }

      // Copy encrypted vault files
      final filesDir = Directory(p.join(docDir.path, 'vault_files'));
      if (await filesDir.exists()) {
        final backupFilesDir = Directory(p.join(backupDir.path, 'vault_files'));
        await backupFilesDir.create(recursive: true);
        await for (var entity in filesDir.list()) {
          if (entity is File) {
            await entity.copy(p.join(backupFilesDir.path, p.basename(entity.path)));
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restores all metadata and vault files from the local backup.
  Future<bool> restoreLocalBackup() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docDir.path, 'vault_backup'));
      if (!await backupDir.exists()) return false;

      // Copy metadata back
      final backupMetaFile = File(p.join(backupDir.path, 'vault_metadata.json'));
      if (await backupMetaFile.exists()) {
        await backupMetaFile.copy(p.join(docDir.path, 'vault_metadata.json'));
      }

      // Copy files back
      final backupFilesDir = Directory(p.join(backupDir.path, 'vault_files'));
      if (await backupFilesDir.exists()) {
        final filesDir = Directory(p.join(docDir.path, 'vault_files'));
        if (!await filesDir.exists()) {
          await filesDir.create(recursive: true);
        }
        await for (var entity in backupFilesDir.list()) {
          if (entity is File) {
            await entity.copy(p.join(filesDir.path, p.basename(entity.path)));
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
