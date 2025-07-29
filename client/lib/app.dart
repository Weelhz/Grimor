import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';
import 'components/offline_banner.dart';

class BookSphereApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, child) {
        return MaterialApp(
          title: 'Book Sphere',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: OfflineBanner(
            child: authProvider.isAuthenticated ? HomePage() : LoginPage(),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}