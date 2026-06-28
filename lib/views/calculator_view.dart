import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import 'auth/auth_view.dart';

class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key});

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  bool _showHistory = false;

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _navigateToVault(BuildContext context) {
    _triggerHaptic();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calcProv = Provider.of<CalculatorProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout(calcProv, settingsProv);
              }
              return _buildPortraitLayout(calcProv, settingsProv);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(CalculatorProvider calc, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Column(
      children: [
        _buildHeader(settings),
        Expanded(
          flex: 3,
          child: _buildDisplay(calc, settings),
        ),
        if (_showHistory)
          Expanded(
            flex: 3,
            child: _buildHistoryPanel(calc, settings),
          ),
        Expanded(
          flex: 6,
          child: _buildButtonGrid(calc, settings, isLandscape: false),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(CalculatorProvider calc, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHeader(settings),
              Expanded(child: _buildDisplay(calc, settings)),
              if (_showHistory)
                Expanded(child: _buildHistoryPanel(calc, settings)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
        Expanded(
          flex: 6,
          child: _buildButtonGrid(calc, settings, isLandscape: true),
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
          // Visible Entry Point for Private Vault as requested by instructions
          GestureDetector(
            onTap: () => _navigateToVault(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: AppTheme.glassBoxDecoration(isDark: isDark, radius: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Private Vault',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay(CalculatorProvider calc, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
        ],
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

  Widget _buildButtonGrid(CalculatorProvider calc, SettingsProvider settings, {required bool isLandscape}) {
    final buttons = [
      ['C', 'DEL', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '=', 'VAULT'],
    ];

    if (isLandscape) {
      // Modify layout for landscape if needed, or keep unified
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: buttons.map((row) {
          return Expanded(
            child: Row(
              children: row.map((char) {
                return Expanded(
                  child: _buildCalculatorButton(char, calc, settings),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalculatorButton(String char, CalculatorProvider calc, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Color btnColor = isDark ? Colors.white05 : Colors.black05;
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (char == '=') {
      btnColor = primaryColor;
      textColor = Colors.white;
    } else if (char == 'C' || char == 'DEL' || char == '%' || char == '÷' || char == '×' || char == '-' || char == '+') {
      btnColor = isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.1);
      textColor = primaryColor;
    } else if (char == 'VAULT') {
      btnColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFE8EEF5);
      textColor = primaryColor;
    }

    return _ElasticButton(
      onPressed: () {
        _triggerHaptic();
        if (char == 'C') {
          calc.clear();
        } else if (char == 'DEL') {
          calc.delete();
        } else if (char == '=') {
          calc.evaluate();
        } else if (char == 'VAULT') {
          _navigateToVault(context);
        } else {
          calc.append(char);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: char == '=' ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        alignment: Alignment.center,
        child: char == 'VAULT'
            ? Icon(Icons.lock, color: textColor, size: 24)
            : Text(
                char,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
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
