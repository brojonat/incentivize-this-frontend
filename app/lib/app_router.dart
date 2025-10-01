import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens deferred
import 'home_screen.dart' deferred as home_screen;
import 'bounty_detail_screen.dart' deferred as bounty_detail_screen;
import 'bounty.dart';
import 'about_screen.dart' deferred as about_screen;
import 'marketing_screen.dart';
import 'loading_indicator.dart'; // A simple loading widget

// Potentially, ApiService might be needed here if we decide to pre-fetch
// import 'api_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Helper widget to handle deferred loading
class DeferredLoader extends StatefulWidget {
  final Future<void> libraryFuture;
  final Widget child;

  const DeferredLoader(
      {super.key, required this.libraryFuture, required this.child});

  @override
  _DeferredLoaderState createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<DeferredLoader> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    await widget.libraryFuture;
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? widget.child
        : const Scaffold(
            body: Center(
              child: LoadingIndicator(message: 'Loading...'),
            ),
          );
  }
}

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
      pageBuilder: (context, state) => NoTransitionPage(
        child: DeferredLoader(
          libraryFuture: home_screen.loadLibrary(),
          child: home_screen.HomeScreen(
            key: const ValueKey('HomeScreen'),
          ),
        ),
      ),
      routes: <RouteBase>[
        GoRoute(
          path: ':bountyId', // Note: no leading '/'
          builder: (BuildContext context, GoRouterState state) {
            return DeferredLoader(
              libraryFuture: bounty_detail_screen.loadLibrary(),
              child: bounty_detail_screen.BountyDetailScreen(
                bountyId: state.pathParameters['bountyId']!,
                initialBounty: state.extra as Bounty?,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/about', // Add the new route for AboutScreen
      builder: (BuildContext context, GoRouterState state) {
        return DeferredLoader(
          libraryFuture: about_screen.loadLibrary(),
          child: about_screen.AboutScreen(),
        );
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
