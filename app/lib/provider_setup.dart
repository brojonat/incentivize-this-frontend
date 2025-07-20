import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'storage_service.dart';
import 'app_config_service.dart';

class ProviderSetup extends StatelessWidget {
  final Widget child;
  final String apiBaseUrl;
  final String gumroadCheckoutUrl;

  const ProviderSetup({
    super.key,
    required this.child,
    required this.apiBaseUrl,
    required this.gumroadCheckoutUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(
            baseUrl: apiBaseUrl,
          ),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<AppConfigService>(
          create: (_) => AppConfigService(
            gumroadCheckoutUrl: gumroadCheckoutUrl,
          ),
        ),
      ],
      child: child,
    );
  }
}
