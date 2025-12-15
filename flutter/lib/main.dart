import 'package:flutter/material.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'screen/slashscreen.dart';
import 'homePage.dart';
import 'login/login_page.dart';
import 'login/signup_page.dart';
import 'screen/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Lang>(
      valueListenable: LangStore.current,
      builder: (_, __, ___) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/splash',
          navigatorObservers: [AnalyticsService.routeObserver],

          routes: {
            '/splash': (context) => const SplashScreen(),
            '/home': (context) => const HomePage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/onboarding': (context) => const OnboardingPage(),
          },
        );
      },
    );
  }
}
