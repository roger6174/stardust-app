import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/features/security_log_screen.dart';
import 'screens/onboarding_agreements_screen.dart';

import 'screens/stardust_guide_screen.dart';
import 'utils/page_transitions.dart';

void main() {
  runApp(const StardustApp());
}

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class StardustApp extends StatelessWidget {
  const StardustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Stardust Vault',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final routes = {
              '/': (_) => const SplashScreen(),
              '/intro': (_) => const IntroScreen(),
              '/auth': (_) => const AuthScreen(initialIndex: 0),
              '/signup': (_) => const AuthScreen(initialIndex: 1),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/recover-account': (_) => const RecoverAccountScreen(),
              '/otp-verification': (_) {
                final args = settings.arguments as Map<String, dynamic>?;
                return OTPVerificationScreen(
                  isLogin: args?['isLogin'] ?? true,
                  userId: args?['userId'],
                  email: args?['email'],
                  mobile: args?['mobile'],
                  destinationSnippet: args?['destinationSnippet'],
                );
              },
              '/dashboard': (_) {
                final args = settings.arguments as Map<String, dynamic>?;
                return DashboardScreen(
                  isGuest: args?['isGuest'] ?? true,
                  isLogin: args?['isLogin'] ?? true,
                );
              },
              '/security-log': (_) => const SecurityLogScreen(),
              '/onboarding': (_) => const OnboardingAgreementsScreen(),
              '/guide': (_) => const StardustGuideScreen(),
            };

            final builder = routes[settings.name];
            if (builder != null) {
              if (settings.name == '/' || settings.name == '/dashboard') {
                return FadePageRoute(child: builder(context));
              }
              return SlideUpPageRoute(child: builder(context));
            }
            return null;
          },
        );
      },
    );
  }
}
