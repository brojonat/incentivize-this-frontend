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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
            final bountyId = state.pathParameters['bountyId']!;
            final Bounty? bounty = state.extra as Bounty?;

            // We will modify BountyDetailScreen to accept bountyId and an optional initialBounty.
            // It will also handle its own wallet address fetching and claim submission.
            return BountyDetailScreen(
              bountyId: bountyId,
              initialBounty: bounty,
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
