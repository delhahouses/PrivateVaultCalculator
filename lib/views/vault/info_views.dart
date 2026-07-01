import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/theme.dart';

class VaultInfoViewHelper {
  static void triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Outfit'))),
    );
  }

  static Future<void> shareApp(BuildContext context) async {
    triggerHaptic();
    try {
      await Share.share(
        'Protect your private photos, videos, audios, and files behind a fully functional calculator. Download Private Vault Calculator: https://play.google.com/store/apps/details?id=com.example.private_vault_calculator',
      );
    } catch (e) {
      showSnackBar(context, 'Unable to share app right now.');
    }
  }

  static Future<void> rateApp(BuildContext context) async {
    triggerHaptic();
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.private_vault_calculator');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showSnackBar(context, 'Could not open Play Store.');
      }
    } catch (e) {
      showSnackBar(context, 'Error launching Play Store.');
    }
  }

  static Future<void> contactSupport(BuildContext context) async {
    triggerHaptic();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'secureappssolutions@gmail.com',
      queryParameters: {
        'subject': 'Support Request - Private Vault Calculator',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        showSnackBar(context, 'No email client found. Email us at: secureappssolutions@gmail.com');
      }
    } catch (e) {
      showSnackBar(context, 'No email client found. Email us at: secureappssolutions@gmail.com');
    }
  }
}

// 1. About App Screen
class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, size: 64, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'About Private Vault Calculator',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildContentCard(
                  context,
                  'Private Vault Calculator is a secure privacy application designed to protect your personal files behind a fully functional calculator interface. To everyone else, the app looks like a normal calculator, while authorized users can unlock a hidden encrypted vault using their secret PIN.\n\n'
                  'The application provides enterprise-level AES-256 encryption for locally stored files and supports photos, videos, audio, documents, PDFs, and custom folders. Additional security features include biometric authentication, decoy vault, panic PIN, screenshot protection, app switcher preview hiding, secure file deletion, private camera, storage dashboard, premium themes, and more.\n\n'
                  'Our mission is to provide maximum privacy while maintaining a clean, modern, and user-friendly experience.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 2. App Description Screen
class AppDescriptionView extends StatelessWidget {
  const AppDescriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final features = [
      'Fake Calculator Lock Screen',
      'AES-256 File Encryption',
      'Fingerprint & Face Unlock',
      'Private Camera',
      'Gallery Import',
      'Video Player',
      'Audio Player',
      'PDF Viewer',
      'Folder Management',
      'Secure File Deletion',
      'Auto Lock',
      'Decoy Vault',
      'Panic PIN',
      'Screenshot Protection',
      'Root Detection',
      'Premium Material 3 Design',
      'Dark Theme',
      'Storage Dashboard',
      'Backup & Restore Support',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Features', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Features & Description',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Private Vault Calculator combines the appearance of a normal calculator with a powerful encrypted private vault. The application is designed for users who value privacy, security, and a premium user experience.',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: features.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      return ListTile(
                        leading: Icon(Icons.check_circle_outline, color: primaryColor, size: 20),
                        title: Text(
                          features[idx],
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 3. Privacy Policy Screen
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Icon(Icons.security, size: 56, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your privacy is our highest priority.',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildContentCard(
                  context,
                  'Private Vault Calculator stores your encrypted files locally on your device. Your personal files are never uploaded to our servers unless you explicitly choose to use an optional backup service in the future.\n\n'
                  'We do not sell your personal information.\n\n'
                  'The application may request permissions such as Camera, Photos, Storage, Microphone, Notifications, and Biometric Authentication solely to provide the features you choose to use.\n\n'
                  'All encrypted files remain under your control.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 4. Terms & Conditions Screen
class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Icon(Icons.gavel, size: 56, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                _buildContentCard(
                  context,
                  'By using Private Vault Calculator, you agree to use the application responsibly.\n\n'
                  'You are responsible for remembering your PIN and securing your device.\n\n'
                  'The developers are not responsible for data loss caused by forgotten passwords, accidental deletion, device damage, factory reset, malware, or unauthorized device modifications.\n\n'
                  'Rooted or modified devices may reduce the security provided by the application.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 5. Data Safety Screen
class DataSafetyView extends StatelessWidget {
  const DataSafetyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Safety', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Safety & Collection Details',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Data Collection (Not Collected)'),
                Card(
                  color: Colors.green.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildSafetyRow('Personal Data', false),
                        _buildSafetyRow('Contacts', false),
                        _buildSafetyRow('Messages', false),
                        _buildSafetyRow('Location', false),
                        _buildSafetyRow('Browsing History', false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Data Stored On-Device (Encrypted)'),
                Card(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildSafetyRow('Files selected by the user', true),
                        _buildSafetyRow('Security configurations & settings', true),
                        _buildSafetyRow('Application theme & preferences', true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'All sensitive user files remain encrypted on the device utilizing AES-256 standards. No user data is ever uploaded or sold to third parties.',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSafetyRow(String label, bool isStored) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isStored ? Icons.lock : Icons.check_circle,
            color: isStored ? Colors.amber : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isStored ? 'Encrypted' : 'Not Collected',
            style: TextStyle(
              fontFamily: 'Outfit', 
              fontSize: 12, 
              color: isStored ? Colors.amber.shade800 : Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Help & FAQ Screen
class HelpFaqView extends StatelessWidget {
  const HelpFaqView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final faqs = [
      {
        'q': 'How do I unlock the vault?',
        'a': 'Enter your secret PIN on the calculator display and press the "=" button.'
      },
      {
        'q': 'What is the default PIN?',
        'a': 'The default PIN is 4000. Enter it and tap "=" to access your vault immediately after setup.'
      },
      {
        'q': 'Can I change the PIN?',
        'a': 'Yes. Once inside the vault, navigate to Settings and tap the "Change PIN" option.'
      },
      {
        'q': 'What happens if I forget my PIN?',
        'a': 'Due to secure on-device encryption, your vault cannot be unlocked without the correct PIN to prevent unauthorized file access.'
      },
      {
        'q': 'How do I import files?',
        'a': 'Open the vault, navigate to the desired folder, and tap the Add (+) button. Select your files to encrypt and secure them.'
      },
      {
        'q': 'How do I backup my files?',
        'a': 'Navigate to Settings, then under "Backups & Cloud", tap "Create Local Backup". Your metadata and files will be securely packed.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, idx) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    faqs[idx]['q']!,
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        faqs[idx]['a']!,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, height: 1.4, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// 7. Contact Support Screen
class ContactSupportView extends StatelessWidget {
  const ContactSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contact_support_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                const Text(
                  'Need Assistance?',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'If you have questions, encountered issues, or need help recovering data, our support team is ready to assist you.',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Support Email:', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                            Text('secureappssolutions@gmail.com', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Typical Response Time:', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
                            Text('Within 24–48 Hours', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => VaultInfoViewHelper.contactSupport(context),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Send Email Support', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 8. App Version / System Info Screen
class AppVersionView extends StatefulWidget {
  const AppVersionView({super.key});

  @override
  State<AppVersionView> createState() => _AppVersionViewState();
}

class _AppVersionViewState extends State<AppVersionView> {
  String _appName = 'Private Vault Calculator';
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appName = info.appName;
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      // Ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Information', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(isDark)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Icon(Icons.phone_android, size: 72, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 24),
                const Text(
                  'System & Package Info',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow('App Name', _appName),
                        const Divider(height: 20),
                        _buildInfoRow('Version', _version),
                        const Divider(height: 20),
                        _buildInfoRow('Build Number', _buildNumber),
                        const Divider(height: 20),
                        _buildInfoRow('Developer', 'SecureApps Solutions'),
                        const Divider(height: 20),
                        _buildInfoRow('Platform', Platform.isAndroid ? 'Android' : 'iOS'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontFamily: 'Outfit', color: Colors.grey)),
      ],
    );
  }
}

// Utility component to render a formatted content card
Widget _buildContentCard(BuildContext context, String content) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Text(
        content,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ),
  );
}
