import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'home_screen.dart';
import 'bounty_detail_screen.dart';
import 'bounty.dart';
// For wallet address access if needed directly by router/screen
import 'about_screen.dart'; // Import the AboutScreen
import 'marketing_screen.dart'; // Import the new marketing screen

// Potentially, ApiService might be needed here if we decide to pre-fetch
// import 'api_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MarketingScreen(); // New landing page
      },
    ),
    GoRoute(
      path: '/bounties', // Old home screen is now here
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: ':bountyId', // Note: no leading '/'
          builder: (BuildContext context, GoRouterState state) {
            return BountyDetailScreen(
              bountyId: state.pathParameters['bountyId']!,
              initialBounty: state.extra as Bounty?,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/about', // Add the new route for AboutScreen
      builder: (BuildContext context, GoRouterState state) {
        return const AboutScreen();
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text('Error: ${state.error?.message ?? "Page not found"}'),
    ),
  ),
);
