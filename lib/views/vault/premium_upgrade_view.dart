import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';

class PremiumUpgradeView extends StatefulWidget {
  const PremiumUpgradeView({super.key});

  @override
  State<PremiumUpgradeView> createState() => _PremiumUpgradeViewState();
}

class _PremiumUpgradeViewState extends State<PremiumUpgradeView> {
  String _selectedPlan = 'lifetime'; // 'monthly', 'yearly', 'lifetime'
  bool _isProcessing = false;

  void _triggerHaptic() {
    try {
      // Light feedback
    } catch (_) {}
  }

  Future<void> _handleUpgrade() async {
    _triggerHaptic();
    setState(() {
      _isProcessing = true;
    });

    final premiumProv = Provider.of<PremiumProvider>(context, listen: false);
    final success = await premiumProv.purchasePremium(_selectedPlan);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('Upgrade Successful', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Thank you! Premium has been unlocked on your account. You now have unlimited storage, themes, and all advanced security tools.',
              style: TextStyle(fontFamily: 'Outfit'),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close upgrade screen
                },
                child: const Text('Let\'s Go', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    _triggerHaptic();
    setState(() {
      _isProcessing = true;
    });

    final premiumProv = Provider.of<PremiumProvider>(context, listen: false);
    final success = await premiumProv.restorePurchase();

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Purchase restored successfully!' : 'No purchases found to restore.'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to PRO', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: _isProcessing
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Processing Google Play Billing...',
                        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeaderCard(primaryColor, isDark),
                      const SizedBox(height: 24),
                      
                      // Feature list
                      const Text(
                        'What\'s Included',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildFeaturesList(primaryColor),
                      const SizedBox(height: 24),

                      // Plans selector
                      const Text(
                        'Choose Plan',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildPlanSelector(primaryColor, isDark),
                      const SizedBox(height: 32),

                      // CTA Actions
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: _handleUpgrade,
                        child: Text(
                          _selectedPlan == 'lifetime'
                              ? 'Get Lifetime Pro (PKR 300)'
                              : _selectedPlan == 'yearly'
                                  ? 'Subscribe Yearly (PKR 599/yr)'
                                  : 'Subscribe Monthly (PKR 99/mo)',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _handleRestore,
                        child: const Text(
                          'Restore Previous Purchase',
                          style: TextStyle(fontFamily: 'Outfit', color: Colors.grey, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(Icons.stars, color: Colors.amber, size: 56),
          SizedBox(height: 12),
          Text(
            'Private Vault PRO',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            'Get ultimate privacy with enterprise-level security',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(Color primaryColor) {
    final features = [
      {'title': 'Unlimited Encrypted Storage', 'desc': 'Store infinite pictures, videos & files.'},
      {'title': 'Decoy Vault Mode', 'desc': 'Unlock a separate dummy vault with a decoy PIN.'},
      {'title': 'Panic Self-Destruct PIN', 'desc': 'Enter a secret PIN to erase all data instantly.'},
      {'title': 'Intruder Log Camera Capture', 'desc': 'Captures a photo of unauthorized access attempts.'},
      {'title': 'Custom Premium Themes', 'desc': 'Access high-contrast AMOLED and gold accent themes.'},
      {'title': '100% Ad-Free Experience', 'desc': 'Remove all banners and promotional ads.'},
    ];

    return Column(
      children: features.map((f) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white10.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title']!,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f['desc']!,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanSelector(Color primaryColor, bool isDark) {
    return Column(
      children: [
        _buildPlanTile('lifetime', 'Lifetime Purchase', 'One-time Payment', 'PKR 300', true),
        const SizedBox(height: 12),
        _buildPlanTile('yearly', 'Yearly Subscription', 'Billed Annually', 'PKR 599/yr', false),
        const SizedBox(height: 12),
        _buildPlanTile('monthly', 'Monthly Subscription', 'Billed Monthly', 'PKR 99/mo', false),
      ],
    );
  }

  Widget _buildPlanTile(String id, String title, String subtitle, String price, bool isPopular) {
    final isSelected = _selectedPlan == id;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        setState(() {
          _selectedPlan = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.12)
              : (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              price,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
