import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'provider_setup.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    const String? authToken = String.fromEnvironment('AUTH_TOKEN') == ""
        ? null
        : String.fromEnvironment('AUTH_TOKEN');

    if (apiBaseUrl.isEmpty) {
      throw Exception('API_BASE_URL must be provided via --dart-define');
    }

    return ProviderSetup(
      apiBaseUrl: apiBaseUrl,
      authToken: authToken,
      child: MaterialApp(
        title: 'IncentivizeThis',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
