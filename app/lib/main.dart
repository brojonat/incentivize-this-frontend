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
      defaultValue: 'http://localhost:8080',
    );

    const String gumroadCheckoutUrl = String.fromEnvironment(
      'GUMROAD_CHECKOUT_URL',
      defaultValue:
          'https://yourawesomedev.gumroad.com/l/yourproduct', // Default placeholder
    );

    if (apiBaseUrl.isEmpty) {
      throw Exception('API_BASE_URL must be provided via --dart-define');
    }
    if (gumroadCheckoutUrl.isEmpty ||
        gumroadCheckoutUrl ==
            'https://yourawesomedev.gumroad.com/l/yourproduct') {
      // Optionally, you could throw an error if it's not set or still the default,
      // or just print a warning during development.
      print(
          'Warning: GUMROAD_CHECKOUT_URL is not set or is using the default placeholder. Update via --dart-define.');
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
