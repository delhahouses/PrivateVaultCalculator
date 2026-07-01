import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/premium_provider.dart';
import '../../core/theme.dart';
import '../calculator_view.dart';
import 'premium_upgrade_view.dart';
import 'vault_drawer.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _showUpgradeSheet() {
    _triggerHaptic();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumUpgradeView()),
    );
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
                        await auth.setupPin(
                          newPinController.text,
                          auth.recoveryQuestion,
                          'default_answer',
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

  void _showSetDecoyPinDialog(AuthProvider auth, bool isDark) {
    _triggerHaptic();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Setup Decoy PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Decoy 4-digit PIN',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Confirm Decoy PIN',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            if (auth.hasDecoyPin)
              TextButton(
                onPressed: () async {
                  await auth.clearDecoyPin();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Decoy PIN disabled.')),
                    );
                  }
                },
                child: const Text('Disable', style: TextStyle(fontFamily: 'Outfit', color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text.length == 4 && pinController.text == confirmController.text) {
                  await auth.setupDecoyPin(pinController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Decoy PIN saved successfully.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match.')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSetPanicPinDialog(AuthProvider auth, bool isDark) {
    _triggerHaptic();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Setup Panic PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Panic 4-digit PIN',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Confirm Panic PIN',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            if (auth.hasPanicPin)
              TextButton(
                onPressed: () async {
                  await auth.clearPanicPin();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panic PIN disabled.')),
                    );
                  }
                },
                child: const Text('Disable', style: TextStyle(fontFamily: 'Outfit', color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pinController.text.length == 4 && pinController.text == confirmController.text) {
                  await auth.setupPanicPin(pinController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panic PIN configured.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PINs do not match.')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showIntruderLogsDialog(SettingsProvider settings, bool isDark) {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Failed Logins / Intruder Logs', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: settings.intruderLogs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No unauthorized entry attempts detected.',
                          style: TextStyle(fontFamily: 'Outfit', color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: settings.intruderLogs.length,
                        itemBuilder: (context, idx) {
                          return ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            title: Text(
                              settings.intruderLogs[idx],
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 13),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                if (settings.intruderLogs.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await settings.clearIntruderLogs();
                      setState(() {});
                    },
                    child: const Text('Clear Logs', style: TextStyle(fontFamily: 'Outfit', color: Colors.redAccent)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontFamily: 'Outfit')),
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
                await vault.panicDestruct();
                await auth.clearAuthData();
                if (mounted) {
                  Navigator.pop(context);
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
    final premiumProv = Provider.of<PremiumProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const VaultDrawer(),
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
              // Premium banner
              if (!premiumProv.isPremium) ...[
                GestureDetector(
                  onTap: _showUpgradeSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.amber.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unlock All PRO Features',
                                  style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                                Text(
                                  'Decoy Vault, Panic PIN, Ad-Free & More',
                                  style: TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                            final isLockedColor = !premiumProv.isPremium && !['Classic Blue', 'Deep Purple'].contains(entry.key);
                            
                            return GestureDetector(
                              onTap: () {
                                _triggerHaptic();
                                if (isLockedColor) {
                                  _showUpgradeSheet();
                                } else {
                                  settingsProv.setAccentColor(entry.key);
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
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
                                  if (isLockedColor)
                                    const Icon(Icons.lock, color: Colors.white, size: 14),
                                ],
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
              _buildSectionTitle('Security & Privacy'),
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
                      SwitchListTile(
                        title: const Text('Screenshot Protection', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Block screenshots and hide app switcher preview', style: TextStyle(fontSize: 12)),
                        value: settingsProv.screenshotProtection,
                        onChanged: (val) {
                          _triggerHaptic();
                          settingsProv.setScreenshotProtection(val);
                        },
                      ),
                      const Divider(),
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
                        title: const Text('Change Main PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Update vault access code', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePinDialog(authProv, isDark),
                      ),
                      const Divider(),
                      
                      // Decoy PIN (PRO)
                      ListTile(
                        title: Row(
                          children: [
                            const Text('Decoy Vault PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                            if (!premiumProv.isPremium) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock, color: Colors.amber, size: 14),
                            ]
                          ],
                        ),
                        subtitle: const Text('Access a fake decoy vault with separate files', style: TextStyle(fontSize: 12)),
                        trailing: Icon(Icons.chevron_right, color: premiumProv.isPremium ? null : Colors.grey),
                        onTap: () {
                          if (premiumProv.isPremium) {
                            _showSetDecoyPinDialog(authProv, isDark);
                          } else {
                            _showUpgradeSheet();
                          }
                        },
                      ),
                      const Divider(),

                      // Panic PIN (PRO)
                      ListTile(
                        title: Row(
                          children: [
                            const Text('Panic Self-Destruct PIN', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                            if (!premiumProv.isPremium) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock, color: Colors.amber, size: 14),
                            ]
                          ],
                        ),
                        subtitle: const Text('Erase all files instantly by typing this PIN', style: TextStyle(fontSize: 12)),
                        trailing: Icon(Icons.chevron_right, color: premiumProv.isPremium ? null : Colors.grey),
                        onTap: () {
                          if (premiumProv.isPremium) {
                            _showSetPanicPinDialog(authProv, isDark);
                          } else {
                            _showUpgradeSheet();
                          }
                        },
                      ),
                      const Divider(),

                      // Intruder Logs
                      ListTile(
                        title: const Text('Failed Logins / Intruder Logs', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('View unauthorized entry attempts', style: TextStyle(fontSize: 12)),
                        trailing: Badge(
                          label: Text(settingsProv.intruderLogs.length.toString()),
                          isLabelVisible: settingsProv.intruderLogs.isNotEmpty,
                          child: const Icon(Icons.warning_amber),
                        ),
                        onTap: () => _showIntruderLogsDialog(settingsProv, isDark),
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

              // Backups card
              _buildSectionTitle('Backups & Cloud'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Create Local Backup', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Saves encrypted state to local directory', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.backup_outlined),
                        onTap: () async {
                          _triggerHaptic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting local vault backup...')),
                          );
                          final success = await settingsProv.createLocalBackup();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Local backup completed successfully.' : 'Backup failed.'),
                                backgroundColor: success ? Colors.green : Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Restore Local Backup', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                        subtitle: const Text('Restores metadata & files from local backup directory', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.restore_outlined),
                        onTap: () async {
                          _triggerHaptic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting restore process...')),
                          );
                          final success = await settingsProv.restoreLocalBackup();
                          if (success) {
                            // Re-initialize vault files
                            await vaultProv.switchVaultContext(decoy: authProv.isDecoy, pin: 'default');
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Local restore completed. Vault reloaded.' : 'Restore failed. No backups found.'),
                                backgroundColor: success ? Colors.green : Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // About card
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
                              Text('Version 2.0.0 (Premium Build)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This application is built with on-device cryptographic standards. Your files are fully encrypted using AES-256 before they are stored and are kept in private local app directories. No file content or access credentials are ever sent to remote services.',
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
