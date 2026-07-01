import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import 'settings_view.dart';
import 'premium_upgrade_view.dart';
import 'info_views.dart';

class VaultDrawer extends StatelessWidget {
  const VaultDrawer({super.key});

  void _triggerHaptic() {
    VaultInfoViewHelper.triggerHaptic();
  }

  @override
  Widget build(BuildContext context) {
    final premiumProv = Provider.of<PremiumProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final isDark = settingsProv.isDarkMode;
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [theme.colorScheme.primary.withOpacity(0.15), theme.colorScheme.secondary.withOpacity(0.05)]
                      : [theme.colorScheme.primary.withOpacity(0.85), theme.colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 40,
                  color: isDark ? theme.colorScheme.primary : theme.colorScheme.primary,
                ),
              ),
              accountName: const Text(
                'Private Vault Calculator',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              accountEmail: Row(
                children: [
                  Text(
                    premiumProv.isPremium ? 'Vault Status: PRO Active' : 'Vault Status: Free Tier',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: premiumProv.isPremium ? Colors.amberAccent : Colors.white70,
                      fontWeight: premiumProv.isPremium ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (premiumProv.isPremium) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.stars, color: Colors.amberAccent, size: 14),
                  ]
                ],
              ),
            ),

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (!premiumProv.isPremium) ...[
                    ListTile(
                      leading: const Icon(Icons.stars, color: Colors.amber),
                      title: const Text(
                        'Upgrade to Premium',
                        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      subtitle: const Text('Unlock Decoy, Panic PIN & limits', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        _triggerHaptic();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PremiumUpgradeView()),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutAppView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.featured_play_list_outlined,
                    title: 'App Description',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppDescriptionView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.gavel_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsConditionsView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Data Safety',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DataSafetyView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpFaqView()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ContactSupportView()),
                      );
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    onTap: () => VaultInfoViewHelper.rateApp(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: () => VaultInfoViewHelper.shareApp(context),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.phonelink_setup_outlined,
                    title: 'App Version',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppVersionView()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        _triggerHaptic();
        Navigator.pop(context); // Close Drawer
        onTap();
      },
    );
  }
}
