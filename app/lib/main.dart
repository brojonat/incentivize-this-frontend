import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';
import 'provider_setup.dart';
import 'theme.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final envFileName = kReleaseMode ? ".env.prod" : ".env.dev";
  await dotenv.load(fileName: envFileName);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String apiBaseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://fallback-api.com/';
    final String? authToken = dotenv.env['AUTH_TOKEN'];

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
