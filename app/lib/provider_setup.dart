import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'storage_service.dart';

class ProviderSetup extends StatelessWidget {
  final Widget child;
  final String apiBaseUrl;

  const ProviderSetup({
    Key? key,
    required this.child,
    required this.apiBaseUrl,
  }) : super(key: key);

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
      ],
      child: child,
    );
  }
}
