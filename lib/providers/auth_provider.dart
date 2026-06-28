import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/security.dart';

class AuthProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _isPinSet = false;
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricsSupported = false;
  
  String _recoveryQuestion = 'What was the name of your first pet?';
  
  DateTime _lastInteractionTime = DateTime.now();

  bool get isPinSet => _isPinSet;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isBiometricsSupported => _isBiometricsSupported;
  String get recoveryQuestion => _recoveryQuestion;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Check if secure keys exist
    final pinHash = await _secureStorage.read(key: 'vault_pin_hash');
    _isPinSet = pinHash != null;

    final bioEnabled = await _secureStorage.read(key: 'biometric_enabled');
    _isBiometricEnabled = bioEnabled == 'true';

    final savedQuestion = await _secureStorage.read(key: 'recovery_question');
    if (savedQuestion != null) {
      _recoveryQuestion = savedQuestion;
    }

    // Check device capabilities
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      _isBiometricsSupported = isDeviceSupported && canCheckBiometrics;
    } catch (e) {
      _isBiometricsSupported = false;
    }

    notifyListeners();
  }

  /// Sets up a new PIN and security question answers.
  Future<void> setupPin(String pin, String question, String answer) async {
    final pinHash = VaultSecurity.hashPin(pin);
    await _secureStorage.write(key: 'vault_pin_hash', value: pinHash);
    
    await _secureStorage.write(key: 'recovery_question', value: question);
    _recoveryQuestion = question;
    
    // Hash recovery answer
    final answerHash = VaultSecurity.hashPin(answer.toLowerCase().trim());
    await _secureStorage.write(key: 'recovery_answer_hash', value: answerHash);
    
    _isPinSet = true;
    _isAuthenticated = true;
    updateInteractionTime();
    notifyListeners();
  }

  /// Verify entered PIN.
  Future<bool> verifyPin(String pin) async {
    final pinHash = await _secureStorage.read(key: 'vault_pin_hash');
    if (pinHash == null) return false;

    final enteredHash = VaultSecurity.hashPin(pin);
    if (pinHash == enteredHash) {
      _isAuthenticated = true;
      updateInteractionTime();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Recover PIN using security question.
  Future<bool> verifyRecoveryAnswer(String answer) async {
    final savedHash = await _secureStorage.read(key: 'recovery_answer_hash');
    if (savedHash == null) return false;

    final enteredHash = VaultSecurity.hashPin(answer.toLowerCase().trim());
    if (savedHash == enteredHash) {
      _isAuthenticated = true;
      updateInteractionTime();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Trigger biometric authentication prompt.
  Future<bool> authenticateWithBiometrics() async {
    if (!_isBiometricsSupported || !_isBiometricEnabled) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your Private Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
        updateInteractionTime();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Biometrics failed or cancelled
    }
    return false;
  }

  Future<void> toggleBiometrics(bool enable) async {
    _isBiometricEnabled = enable;
    await _secureStorage.write(key: 'biometric_enabled', value: enable.toString());
    notifyListeners();
  }

  void updateInteractionTime() {
    _lastInteractionTime = DateTime.now();
  }

  /// Lock session
  void lock() {
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Evaluates and triggers auto lock if threshold duration has passed
  void checkAutoLock(int durationSeconds) {
    if (!_isAuthenticated || durationSeconds <= 0) return;
    
    final difference = DateTime.now().difference(_lastInteractionTime).inSeconds;
    if (difference >= durationSeconds) {
      lock();
    }
  }

  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'vault_pin_hash');
    await _secureStorage.delete(key: 'recovery_question');
    await _secureStorage.delete(key: 'recovery_answer_hash');
    await _secureStorage.delete(key: 'biometric_enabled');
    _isPinSet = false;
    _isAuthenticated = false;
    _isBiometricEnabled = false;
    notifyListeners();
  }
}
