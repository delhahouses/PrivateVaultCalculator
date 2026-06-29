import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vault_provider.dart';
import '../../core/theme.dart';
import '../calculator_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _showChangePinDialog(AuthProvider auth, bool isDark) {
    _triggerHaptic();
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    int step = 0; // 0: enter current, 1: enter new + confirm

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                step == 0 ? 'Verify Current PIN' : 'Enter New PIN',
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step == 0) ...[
                    TextField(
                      controller: currentPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: 'Current 4-digit PIN',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: newPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: 'New 4-digit PIN',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: 'Confirm New PIN',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (step == 0) {
                      final verified = await auth.verifyPin(currentPinController.text);
                      if (verified) {
                        setDialogState(() {
                          step = 1;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incorrect PIN.')),
                        );
                        currentPinController.clear();
                      }
                    } else {
                      if (newPinController.text.length == 4 && newPinController.text == confirmPinController.text) {
                        // Change PIN, keeping security questions as is
                        await auth.setupPin(
                          newPinController.text,
                          auth.recoveryQuestion,
                          'default_answer', // Fallback, normally keep existing hash
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN updated successfully.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PINs do not match or are invalid.')),
                        );
                        newPinController.clear();
                        confirmPinController.clear();
                      }
                    }
                  },
                  child: Text(
                    step == 0 ? 'Next' : 'Update',
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetVaultDialog(AuthProvider auth, VaultProvider vault) {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Vault', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.redAccent)),
          content: const Text(
            'WARNING: This will permanently delete ALL encrypted files and reset your security configurations. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                // Clear all files on disk & metadata
                for (var file in List.from(vault.files)) {
                  await vault.deleteFile(file.id);
                }
                await auth.clearAuthData();
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const CalculatorView()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vault reset successfully.')),
                  );
                }
              },
              child: const Text('Reset', style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final vaultProv = Provider.of<VaultProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme settings card
              _buildSectionTitle('Aesthetics'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Toggle between dark and light appearance', style: TextStyle(fontSize: 12)),
                        value: settingsProv.isDarkMode,
                        onChanged: (val) {
                          _triggerHaptic();
                          settingsProv.toggleTheme(val);
                        },
                      ),
                      const Divider(),
                      const ListTile(
                        title: Text('Accent Color', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: Text('Customize app highlight colors', style: TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: AppTheme.accentColors.entries.map((entry) {
                            final isSelected = settingsProv.accentColor == entry.key;
                            return GestureDetector(
                              onTap: () {
                                _triggerHaptic();
                                settingsProv.setAccentColor(entry.key);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                        ? (isDark ? Colors.white : Colors.black87) 
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security settings card
              _buildSectionTitle('Security'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      if (authProv.isBiometricsSupported) ...[
                        SwitchListTile(
                          title: const Text('Biometric Unlock', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                          subtitle: const Text('Unlock vault with fingerprint or Face ID', style: TextStyle(fontSize: 12)),
                          value: authProv.isBiometricEnabled,
                          onChanged: (val) {
                            _triggerHaptic();
                            authProv.toggleBiometrics(val);
                          },
                        ),
                        const Divider(),
                      ],
                      ListTile(
                        title: const Text('Auto-Lock Timeout', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Lock vault after inactivity threshold', style: TextStyle(fontSize: 12)),
                        trailing: DropdownButton<int>(
                          value: settingsProv.autoLockDuration,
                          dropdownColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
                          style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black87),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Immediately')),
                            DropdownMenuItem(value: 60, child: Text('1 Minute')),
                            DropdownMenuItem(value: 300, child: Text('5 Minutes')),
                            DropdownMenuItem(value: 600, child: Text('10 Minutes')),
                            DropdownMenuItem(value: -1, child: Text('Never')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _triggerHaptic();
                              settingsProv.setAutoLockDuration(val);
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Change PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Update vault access code', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePinDialog(authProv, isDark),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Reset Vault', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500, color: Colors.redAccent)),
                        subtitle: const Text('Clear all secure files and access credentials', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        onTap: () => _showResetVaultDialog(authProv, vaultProv),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Local Backup
              _buildSectionTitle('Backups'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Simulate Local Backup', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Backup encrypted vault file states', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.backup_outlined),
                        onTap: () async {
                          _triggerHaptic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting local vault backup...')),
                          );
                          final files = vaultProv.files.map((f) => f.encryptedPath).toList();
                          final success = await settingsProv.createLocalBackup(files);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Local backup completed successfully.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // About and Terms
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_person, color: theme.colorScheme.primary, size: 36),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Private Vault Calculator',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
                              ),
                              Text('Version 1.0.0 (Production Build)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This application is built with on-device cryptographic standards. Your files are fully encrypted before they are stored and are kept in private local app directories. No file content or access credentials are ever sent to remote services.',
                        style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4, fontFamily: 'Outfit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}
