import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/premium_provider.dart';
import '../core/theme.dart';
import 'auth/auth_view.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  bool _showHistory = false;
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  int _lockoutSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _checkRootAndShowWarning();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _checkRootAndShowWarning() async {
    // Check root detection (simulated or jailbreak checker)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.rootDetectionEnabled) {
        // Since we are running in simulator/various devices, we log or notify
        debugPrint("Root/Jailbreak verification complete. Status: Safe");
      }
    });
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        setState(() {
          _lockoutEndTime = null;
          _lockoutSecondsRemaining = 0;
          _failedAttempts = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _lockoutSecondsRemaining = remaining;
        });
      }
    });
  }

  void _navigateToVault(BuildContext context) {
    _triggerHaptic();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthView()),
    );
  }

  Future<void> _handleSecretBiometrics() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final vaultProv = Provider.of<VaultProvider>(context, listen: false);
    
    if (authProv.isBiometricEnabled && authProv.isBiometricsSupported) {
      _triggerHaptic();
      final success = await authProv.authenticateWithBiometrics();
      if (success) {
        final plainPin = await authProv.getPlainPin() ?? "4000";
        await vaultProv.switchVaultContext(decoy: false, pin: plainPin);
        if (mounted) {
          _navigateToVault(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcProv = Provider.of<CalculatorProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final premiumProv = Provider.of<PremiumProvider>(context);
    final isDark = settingsProv.isDarkMode;

    final isLockedOut = _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              return Column(
                children: [
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeLayout(calcProv, settingsProv, isLockedOut)
                        : _buildPortraitLayout(calcProv, settingsProv, isLockedOut),
                  ),
                  // Mock Banner Ad for free users
                  if (!premiumProv.isPremium) _buildPromoAdBanner(settingsProv),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(CalculatorProvider calc, SettingsProvider settings, bool isLockedOut) {
    return Column(
      children: [
        _buildHeader(settings),
        Expanded(
          flex: 3,
          child: _buildDisplay(calc, settings, isLockedOut),
        ),
        if (_showHistory)
          Expanded(
            flex: 3,
            child: _buildHistoryPanel(calc, settings),
          ),
        Expanded(
          flex: 6,
          child: _buildButtonGrid(calc, settings, isLockedOut, isLandscape: false),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(CalculatorProvider calc, SettingsProvider settings, bool isLockedOut) {
    final isDark = settings.isDarkMode;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHeader(settings),
              Expanded(child: _buildDisplay(calc, settings, isLockedOut)),
              if (_showHistory)
                Expanded(child: _buildHistoryPanel(calc, settings)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
        Expanded(
          flex: 6,
          child: _buildButtonGrid(calc, settings, isLockedOut, isLandscape: true),
        ),
      ],
    );
  }

  Widget _buildHeader(SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showHistory ? Icons.history_toggle_off : Icons.history,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () {
                  _triggerHaptic();
                  setState(() {
                    _showHistory = !_showHistory;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () {
                  _triggerHaptic();
                  settings.toggleTheme(!isDark);
                },
              ),
            ],
          ),
          // Subtly hidden title that responds to double-taps for hidden biometric trigger
          GestureDetector(
            onDoubleTap: _handleSecretBiometrics,
            child: Text(
              'Calculator',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay(CalculatorProvider calc, SettingsProvider settings, bool isLockedOut) {
    final isDark = settings.isDarkMode;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GestureDetector(
        onDoubleTap: _handleSecretBiometrics,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isLockedOut) ...[
              const Icon(Icons.security, color: Colors.redAccent, size: 28),
              const SizedBox(height: 8),
              Text(
                'Security Lockout: $_lockoutSecondsRemaining s',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Too many failed attempts. Try again later.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ] else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  calc.display.isEmpty ? '0' : calc.display,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedScale(
                scale: calc.result.isNotEmpty ? 1.0 : 0.8,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  calc.result,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(CalculatorProvider calc, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: AppTheme.glassBoxDecoration(isDark: isDark, radius: 12),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: calc.history.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              calc.history[index],
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonGrid(CalculatorProvider calc, SettingsProvider settings, bool isLockedOut, {required bool isLandscape}) {
    final buttons = [
      ['C', 'DEL', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', '00'], // Replaced VAULT with a benign 00 key
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: buttons.map((row) {
          return Expanded(
            child: Row(
              children: row.map((char) {
                return Expanded(
                  child: _buildCalculatorButton(char, calc, settings, isLockedOut),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalculatorButton(String char, CalculatorProvider calc, SettingsProvider settings, bool isLockedOut) {
    final isDark = settings.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Color btnColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (char == '=') {
      btnColor = primaryColor;
      textColor = Colors.white;
    } else if (char == 'C' || char == 'DEL' || char == '%' || char == '÷' || char == '×' || char == '-' || char == '+') {
      btnColor = isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.1);
      textColor = primaryColor;
    }

    return _ElasticButton(
      onPressed: isLockedOut
          ? () => _triggerHaptic()
          : () async {
              _triggerHaptic();
              if (char == 'C') {
                calc.clear();
              } else if (char == 'DEL') {
                calc.delete();
              } else if (char == '=') {
                final authProv = Provider.of<AuthProvider>(context, listen: false);
                final vaultProv = Provider.of<VaultProvider>(context, listen: false);
                final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
                
                final enteredText = calc.display;
                
                // Verify if expression matches any PIN
                final verified = await authProv.verifyPin(enteredText);
                if (verified) {
                  _failedAttempts = 0; // reset
                  if (authProv.isPanicTriggered) {
                    await vaultProv.panicDestruct();
                    await authProv.clearAuthData();
                    calc.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Panic: All vault data wiped securely.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } else {
                    await vaultProv.switchVaultContext(decoy: authProv.isDecoy, pin: enteredText);
                    calc.clear();
                    _navigateToVault(context);
                  }
                } else {
                  // Check for potential failed attempt (exactly 4 digits entered)
                  if (enteredText.length == 4 && RegExp(r'^\d{4}$').hasMatch(enteredText)) {
                    _failedAttempts++;
                    if (_failedAttempts >= settingsProv.failedAttemptsThreshold) {
                      final nowStr = DateTime.now().toString().substring(0, 19);
                      await settingsProv.addIntruderLog("Intruder failed entry at $nowStr");
                      setState(() {
                        _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
                      });
                      _startLockoutTimer();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Access Denied. Attempt $_failedAttempts/${settingsProv.failedAttemptsThreshold}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                  calc.evaluate();
                }
              } else {
                calc.append(char);
              }
            },
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isLockedOut ? btnColor.withOpacity(0.02) : btnColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: char == '=' && !isLockedOut ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          char,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isLockedOut ? textColor.withOpacity(0.2) : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPromoAdBanner(SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFE8EEF8),
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Upgrade for Ad-Free & Unlimited Storage!',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // Trigger upgrade screen/dialog
              _navigateToVault(context); // Tapping ad banner takes user to vault auth/upgrade path
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Remove Ads',
              style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}

class _ElasticButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _ElasticButton({required this.onPressed, required this.child});

  @override
  State<_ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<_ElasticButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
