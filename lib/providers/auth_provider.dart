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
  
  // Decoy & Panic State
  bool _isDecoy = false;
  bool _isPanicTriggered = false;
  bool _hasDecoyPin = false;
  bool _hasPanicPin = false;
  
  String _recoveryQuestion = 'What was the name of your first pet?';
  DateTime _lastInteractionTime = DateTime.now();

  bool get isPinSet => _isPinSet;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isBiometricsSupported => _isBiometricsSupported;
  bool get isDecoy => _isDecoy;
  bool get isPanicTriggered => _isPanicTriggered;
  bool get hasDecoyPin => _hasDecoyPin;
  bool get hasPanicPin => _hasPanicPin;
  String get recoveryQuestion => _recoveryQuestion;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Check if secure keys exist
    var pinHash = await _secureStorage.read(key: 'vault_pin_hash');
    if (pinHash == null) {
      // Setup default PIN "4000" for first-time users
      pinHash = VaultSecurity.hashPin("4000");
      await _secureStorage.write(key: 'vault_pin_hash', value: pinHash);
      await _secureStorage.write(key: 'vault_pin_plain', value: '4000');
      await _secureStorage.write(key: 'recovery_question', value: 'What is the default recovery PIN?');
      await _secureStorage.write(key: 'recovery_answer_hash', value: VaultSecurity.hashPin('4000'));
    }
    _isPinSet = true;

    final decoyHash = await _secureStorage.read(key: 'vault_decoy_pin_hash');
    _hasDecoyPin = decoyHash != null;

    final panicHash = await _secureStorage.read(key: 'vault_panic_pin_hash');
    _hasPanicPin = panicHash != null;

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

  /// Sets up a new main PIN and security question answers.
  Future<void> setupPin(String pin, String question, String answer) async {
    final pinHash = VaultSecurity.hashPin(pin);
    await _secureStorage.write(key: 'vault_pin_hash', value: pinHash);
    await _secureStorage.write(key: 'vault_pin_plain', value: pin);
    
    await _secureStorage.write(key: 'recovery_question', value: question);
    _recoveryQuestion = question;
    
    // Hash recovery answer
    final answerHash = VaultSecurity.hashPin(answer.toLowerCase().trim());
    await _secureStorage.write(key: 'recovery_answer_hash', value: answerHash);
    
    _isPinSet = true;
    _isAuthenticated = true;
    _isDecoy = false;
    updateInteractionTime();
    notifyListeners();
  }

  /// Sets up the Decoy Vault PIN.
  Future<void> setupDecoyPin(String pin) async {
    final pinHash = VaultSecurity.hashPin(pin);
    await _secureStorage.write(key: 'vault_decoy_pin_hash', value: pinHash);
    _hasDecoyPin = true;
    notifyListeners();
  }

  /// Sets up the Panic PIN.
  Future<void> setupPanicPin(String pin) async {
    final pinHash = VaultSecurity.hashPin(pin);
    await _secureStorage.write(key: 'vault_panic_pin_hash', value: pinHash);
    _hasPanicPin = true;
    notifyListeners();
  }

  /// Clears Decoy PIN.
  Future<void> clearDecoyPin() async {
    await _secureStorage.delete(key: 'vault_decoy_pin_hash');
    _hasDecoyPin = false;
    notifyListeners();
  }

  /// Clears Panic PIN.
  Future<void> clearPanicPin() async {
    await _secureStorage.delete(key: 'vault_panic_pin_hash');
    _hasPanicPin = false;
    notifyListeners();
  }

  /// Verify entered PIN. Handles main PIN, Decoy PIN, and Panic PIN.
  Future<bool> verifyPin(String pin) async {
    final enteredHash = VaultSecurity.hashPin(pin);

    // 1. Check Panic PIN
    final panicHash = await _secureStorage.read(key: 'vault_panic_pin_hash');
    if (panicHash != null && panicHash == enteredHash) {
      _isPanicTriggered = true;
      notifyListeners();
      return true;
    }

    // 2. Check Decoy PIN
    final decoyHash = await _secureStorage.read(key: 'vault_decoy_pin_hash');
    if (decoyHash != null && decoyHash == enteredHash) {
      _isDecoy = true;
      _isAuthenticated = true;
      updateInteractionTime();
      notifyListeners();
      return true;
    }

    // 3. Check Main PIN
    final pinHash = await _secureStorage.read(key: 'vault_pin_hash');
    if (pinHash != null && pinHash == enteredHash) {
      _isDecoy = false;
      _isAuthenticated = true;
      updateInteractionTime();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Retrieves the plain text main PIN for file decryption when biometrics is used.
  Future<String?> getPlainPin() async {
    return await _secureStorage.read(key: 'vault_pin_plain');
  }

  /// Recover PIN using security question.
  Future<bool> verifyRecoveryAnswer(String answer) async {
    final savedHash = await _secureStorage.read(key: 'recovery_answer_hash');
    if (savedHash == null) return false;

    final enteredHash = VaultSecurity.hashPin(answer.toLowerCase().trim());
    if (savedHash == enteredHash) {
      _isAuthenticated = true;
      _isDecoy = false;
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
        _isDecoy = false; // Biometrics always unlocks main vault
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
    _isDecoy = false;
    _isPanicTriggered = false;
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
    await _secureStorage.delete(key: 'vault_pin_plain');
    await _secureStorage.delete(key: 'vault_decoy_pin_hash');
    await _secureStorage.delete(key: 'vault_panic_pin_hash');
    await _secureStorage.delete(key: 'recovery_question');
    await _secureStorage.delete(key: 'recovery_answer_hash');
    await _secureStorage.delete(key: 'biometric_enabled');
    _isPinSet = false;
    _isAuthenticated = false;
    _isBiometricEnabled = false;
    _isDecoy = false;
    _isPanicTriggered = false;
    _hasDecoyPin = false;
    _hasPanicPin = false;
    notifyListeners();
  }
}
