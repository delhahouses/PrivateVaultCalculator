import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/calculator_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/premium_provider.dart';
import 'views/calculator_view.dart';
import 'core/theme.dart';

void main() {
  // Ensure framework services are loaded before state initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Private Vault Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(settingsProv.accentColor, false),
      darkTheme: AppTheme.getTheme(settingsProv.accentColor, true),
      themeMode: settingsProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const CalculatorView(),
    );
  }
}
