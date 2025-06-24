import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'provider_setup.dart';
import 'theme.dart';
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
    );
    if (apiBaseUrl.isEmpty) {
      throw Exception('API_BASE_URL must be provided via --dart-define');
    }

    const String gumroadCheckoutUrl = String.fromEnvironment(
      'GUMROAD_CHECKOUT_URL',
    );

    if (gumroadCheckoutUrl.isEmpty) {
      throw Exception(
          'GUMROAD_CHECKOUT_URL must be provided via --dart-define');
    }

    return ProviderSetup(
      apiBaseUrl: apiBaseUrl,
      gumroadCheckoutUrl: gumroadCheckoutUrl,
      child: MaterialApp.router(
        title: 'IncentivizeThis',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
