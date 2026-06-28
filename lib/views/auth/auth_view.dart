import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';
import '../vault/vault_home_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final List<String> _securityQuestions = [
    'What was the name of your first pet?',
    'In what city were you born?',
    'What was your childhood nickname?',
    'What is your mother\'s maiden name?',
    'What was the name of your primary school?',
  ];

  // PIN input state
  String _enteredPin = '';
  String _tempSetupPin = '';
  int _setupStep = 0; // 0: enter PIN, 1: confirm PIN, 2: set recovery question

  // Recovery setup state
  String _selectedQuestion = 'What was the name of your first pet?';
  final _recoveryAnswerController = TextEditingController();

  // Forgot PIN state
  bool _isRecovering = false;
  final _recoveryVerifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricsAutoTrigger();
    });
  }

  Future<void> _checkBiometricsAutoTrigger() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (authProv.isPinSet && authProv.isBiometricEnabled) {
      final success = await authProv.authenticateWithBiometrics();
      if (success && mounted) {
        _enterVault('');
      }
    }
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _handlePinPress(String val) {
    _triggerHaptic();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
      });
      if (_enteredPin.length == 4) {
        _evaluatePinState();
      }
    }
  }

  void _handleBackspace() {
    _triggerHaptic();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _evaluatePinState() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProv.isPinSet) {
      // Setup PIN path
      if (_setupStep == 0) {
        _tempSetupPin = _enteredPin;
        setState(() {
          _enteredPin = '';
          _setupStep = 1;
        });
      } else if (_setupStep == 1) {
        if (_tempSetupPin == _enteredPin) {
          setState(() {
            _setupStep = 2; // Proceed to recovery setup
            _enteredPin = '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs do not match. Start over.')),
          );
          setState(() {
            _enteredPin = '';
            _setupStep = 0;
            _tempSetupPin = '';
          });
        }
      }
    } else {
      // Verify existing PIN
      final verified = await authProv.verifyPin(_enteredPin);
      if (verified) {
        _enterVault(_enteredPin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN. Please try again.')),
        );
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  void _enterVault(String pin) {
    final vaultProv = Provider.of<VaultProvider>(context, listen: false);
    vaultProv.setPin(pin); // Store PIN in vault provider for encryption keys
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VaultHomeView()),
    );
  }

  Future<void> _submitRecoverySetup() async {
    if (_recoveryAnswerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recovery answer.')),
      );
      return;
    }
    
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.setupPin(
      _tempSetupPin,
      _selectedQuestion,
      _recoveryAnswerController.text,
    );
    
    _enterVault(_tempSetupPin);
  }

  Future<void> _submitRecoveryVerify() async {
    if (_recoveryVerifyController.text.isEmpty) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final verified = await authProv.verifyRecoveryAnswer(_recoveryVerifyController.text);
    
    if (verified) {
      // In-memory PIN is required for database operations. Since PIN recovery bypassed PIN entry,
      // reset auth settings so they can setup a new PIN immediately.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery successful. Please set a new PIN.')),
      );
      await authProv.clearAuthData();
      setState(() {
        _isRecovering = false;
        _setupStep = 0;
        _enteredPin = '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect answer. Try again.')),
      );
      _recoveryVerifyController.clear();
    }
  }

  @override
  void dispose() {
    _recoveryAnswerController.dispose();
    _recoveryVerifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          !authProv.isPinSet ? 'Setup Vault' : (_isRecovering ? 'Recover Vault' : 'Unlock Vault'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isRecovering 
                      ? _buildRecoveryVerifyPanel(authProv, isDark)
                      : (!authProv.isPinSet && _setupStep == 2
                          ? _buildRecoverySetupPanel(isDark)
                          : _buildPinLockPanel(authProv, isDark)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinLockPanel(AuthProvider auth, bool isDark) {
    String titleText = 'Create a Secure PIN';
    String subtitleText = 'Enter 4 digits to secure your private vault';

    if (auth.isPinSet) {
      titleText = 'Enter Vault PIN';
      subtitleText = 'Enter your 4-digit code to access files';
    } else if (_setupStep == 1) {
      titleText = 'Confirm Vault PIN';
      subtitleText = 'Re-enter your 4-digit code to confirm';
    }

    return Column(
      key: ValueKey('pin_lock_step_$_setupStep'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.security, size: 64, color: Colors.blueAccent),
        const SizedBox(height: 20),
        Text(
          titleText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        const SizedBox(height: 8),
        Text(
          subtitleText,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Outfit'),
        ),
        const SizedBox(height: 32),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            bool isFilled = index < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled 
                    ? Theme.of(context).colorScheme.primary 
                    : (isDark ? Colors.white24 : Colors.black12),
                border: Border.all(
                  color: isFilled 
                      ? Theme.of(context).colorScheme.primary 
                      : (isDark ? Colors.white38 : Colors.black26),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        // Pin Pad Grid
        _buildPinPad(auth, isDark),
        const SizedBox(height: 16),
        if (auth.isPinSet)
          TextButton(
            onPressed: () {
              _triggerHaptic();
              setState(() {
                _isRecovering = true;
              });
            },
            child: const Text(
              'Forgot PIN?',
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildPinPad(AuthProvider auth, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildPinPadButton(n, isDark)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildPinPadButton(n, isDark)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildPinPadButton(n, isDark)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left extra action: Biometrics
            Expanded(
              child: auth.isPinSet && auth.isBiometricsSupported && auth.isBiometricEnabled
                  ? IconButton(
                      icon: const Icon(Icons.fingerprint, size: 28, color: Colors.blueAccent),
                      onPressed: () async {
                        _triggerHaptic();
                        final success = await auth.authenticateWithBiometrics();
                        if (success) _enterVault('');
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            _buildPinPadButton('0', isDark),
            // Right extra action: Backspace
            Expanded(
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined, size: 24),
                onPressed: _handleBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinPadButton(String label, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          onTap: () => _handlePinPress(label),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoverySetupPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration(isDark: isDark),
      child: Column(
        key: const ValueKey('recovery_setup'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.help_outline, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'Security Question',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a security question to recover your PIN if you forget it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedQuestion,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white05 : Colors.black05,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _securityQuestions.map((q) {
              return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 14)));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedQuestion = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _recoveryAnswerController,
            decoration: InputDecoration(
              hintText: 'Enter your answer',
              filled: true,
              fillColor: isDark ? Colors.white05 : Colors.black05,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitRecoverySetup,
            child: const Text('Complete Setup', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryVerifyPanel(AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration(isDark: isDark),
      child: Column(
        key: const ValueKey('recovery_verify'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.help, size: 48, color: Colors.blueAccent),
          const SizedBox(height: 16),
          const Text(
            'Answer Security Question',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          Text(
            auth.recoveryQuestion,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _recoveryVerifyController,
            decoration: InputDecoration(
              hintText: 'Your Answer',
              filled: true,
              fillColor: isDark ? Colors.white05 : Colors.black05,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitRecoveryVerify,
            child: const Text('Submit Recovery', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _triggerHaptic();
              setState(() {
                _isRecovering = false;
                _enteredPin = '';
              });
            },
            child: const Text('Back to PIN Lock', style: TextStyle(fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
  }
}
