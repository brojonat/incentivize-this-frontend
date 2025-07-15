import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'clueso_video_player.dart';
import 'contact_us_dialog.dart';

class _MarketingLine {
  final String text;
  final String platformName;
  final Decoration decoration;
  final Color textColor;

  _MarketingLine({
    required this.text,
    required this.platformName,
    required this.decoration,
    required this.textColor,
  });
}

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _arrowAnimationController;
  late final Animation<Offset> _arrowAnimation;
  late final Timer _platformAnimationTimer;

  final GlobalKey _heroContentKey = GlobalKey();
  double _heroContentHeight = 0;

  int _currentLineIndex = 0;
  final List<_MarketingLine> _marketingLines = [
    _MarketingLine(
        text: 'a Reddit post with at least 1k upvotes mentioning Home Depot',
        platformName: 'Reddit',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 234, 78, 0),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a Reddit comment in r/OrangeCounty about SuzieCakes bakery',
        platformName: 'Reddit',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 234, 78, 0),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a YouTube video about Mark Weins visiting Lisbon, Portugal',
        platformName: 'YouTube',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 33, 33),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text:
            'a YouTube comment with at least 100 likes on a video about oysters',
        platformName: 'YouTube',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 33, 33),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a Bluesky post about how A.I. doesn\'t live up to the hype',
        platformName: 'Bluesky',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 165, 245),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'an Instagram post with at least 2M likes about Positano, Italy',
        platformName: 'Instagram',
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a Twitch video about Dota 2 with at least 100k views',
        platformName: 'Twitch',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 127, 21, 157),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a Twitch clip from Purge\'s channel with at least 25k views',
        platformName: 'Twitch',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 127, 21, 157),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a HackerNews post about Temporal with at least 100 upvotes',
        platformName: 'HackerNews',
        decoration: BoxDecoration(
            color: const Color(0xFFFF6600),
            borderRadius: BorderRadius.circular(8)),
        textColor: const Color.fromARGB(255, 250, 239, 227)),
    _MarketingLine(
        text: 'a HackerNews comment with tips on using Goose',
        platformName: 'HackerNews',
        decoration: BoxDecoration(
            color: const Color(0xFFFF6600),
            borderRadius: BorderRadius.circular(8)),
        textColor: const Color.fromARGB(255, 250, 239, 227)),
    _MarketingLine(
        text:
            'a TripAdvisor review for a hotel in Honolulu with a 5 star rating',
        platformName: 'TripAdvisor',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 175, 122),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
    _MarketingLine(
        text: 'a TripAdvisor review for a restaurant in New York',
        platformName: 'TripAdvisor',
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 175, 122),
            borderRadius: BorderRadius.circular(8)),
        textColor: Colors.white),
  ];

  double _imageOffset = 0.0;
  double _textOpacity = 1.0;
  double _arrowOpacity = 1.0;
  double _section2AnimationValue = 0.0;
  double _section3AnimationValue = 0.0;
  double _section4AnimationValue = 0.0;
  double _section5AnimationValue = 0.0;
  double _section6AnimationValue = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _marketingLines.shuffle();

    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.15),
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOut,
    ));

    _platformAnimationTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentLineIndex = (_currentLineIndex + 1) % _marketingLines.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _arrowAnimationController.dispose();
    _platformAnimationTimer.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final offset = _scrollController.offset;

    if (_heroContentKey.currentContext != null) {
      final heroHeight = _heroContentKey.currentContext!.size!.height;
      if (heroHeight != _heroContentHeight) {
        setState(() {
          _heroContentHeight = heroHeight;
        });
      }
    }

    setState(() {
      _imageOffset = offset * 0.5;

      if (offset < screenHeight * 0.75) {
        _textOpacity = 1.0 - (offset / (screenHeight * 0.75));
      } else {
        _textOpacity = 0.0;
      }
      _textOpacity = _textOpacity.clamp(0.0, 1.0);

      if (offset < 100) {
        _arrowOpacity = 1.0 - (offset / 100);
      } else {
        _arrowOpacity = 0.0;
      }
      _arrowOpacity = _arrowOpacity.clamp(0.0, 1.0);

      final animationStartOffset =
          _heroContentHeight > 0 ? _heroContentHeight : screenHeight;

      _section2AnimationValue = _calculateAnimationValue(
          offset, screenHeight, 1, animationStartOffset);
      _section3AnimationValue = _calculateAnimationValue(
          offset, screenHeight, 2, animationStartOffset);
      _section4AnimationValue = _calculateAnimationValue(
          offset, screenHeight, 3, animationStartOffset);
      _section5AnimationValue = _calculateAnimationValue(
          offset, screenHeight, 4, animationStartOffset);

      if (_scrollController.position.hasContentDimensions) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final animationStart = maxScroll - 500;
        if (offset >= animationStart) {
          _section6AnimationValue = (offset - animationStart) / 500;
        } else {
          _section6AnimationValue = 0.0;
        }
      } else {
        _section6AnimationValue = 0.0;
      }
      _section6AnimationValue = _section6AnimationValue.clamp(0.0, 1.0);
    });
  }

  double _calculateAnimationValue(double offset, double screenHeight,
      int section, double animationStartOffset) {
    final sectionHeight = 500.0;
    final sectionStart = animationStartOffset + (section - 1) * sectionHeight;
    final animationStart = sectionStart - screenHeight * 0.8;
    final animationEnd = sectionStart + sectionHeight * 0.5;

    double value;
    if (offset >= animationStart && offset <= animationEnd) {
      value = (offset - animationStart) / (animationEnd - animationStart);
    } else if (offset > animationEnd) {
      value = 1.0;
    } else {
      value = 0.0;
    }
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -_imageOffset),
              child: OverflowBox(
                maxHeight: double.infinity,
                child: Image.asset(
                  'assets/images/marketing-carrot.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.0, 0.0),
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              // Add a SliverToBoxAdapter to place the video player
              SliverToBoxAdapter(
                child: Center(
                  // Center the player
                  child: Container(
                    key: _heroContentKey,
                    padding: const EdgeInsets.only(
                        top: 150.0, left: 24.0, right: 24.0, bottom: 24.0),
                    constraints:
                        const BoxConstraints(maxWidth: 800), // Max width
                    child: Column(
                      children: [
                        Opacity(
                          opacity: _arrowOpacity,
                          child: SlideTransition(
                            position: _arrowAnimation,
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 48),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Opacity(
                          opacity: _textOpacity,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text('Welcome to IncentivizeThis',
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 330.0),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16.0), // Rounded corners
                            child: const CluesoVideoPlayer(
                              videoId: '2d30eedc-4b2d-4851-a3c0-475885a4f26e',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Hero Section
              SliverToBoxAdapter(
                child: Container(
                  height: screenHeight - 250,
                  alignment: Alignment.center,
                ),
              ),
              // "Ads Suck" Section
              SliverToBoxAdapter(
                child: Container(
                  height: 500,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: _section2AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(-50 * (1 - _section2AnimationValue), 0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ads Suck.',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                Text(
                                    'Yuck. Nobody\'s clicking on this. At least not on purpose.',
                                    style:
                                        TextStyle(fontSize: 16, height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Opacity(
                          opacity: _section2AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(50 * (1 - _section2AnimationValue), 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                  'assets/images/marketing-yuck-full.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "Discover Bounties" Section
              SliverToBoxAdapter(
                child: Container(
                  height: 500,
                  color: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: _section3AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(-50 * (1 - _section3AnimationValue), 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                  'assets/images/marketing-browse.png'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Opacity(
                          opacity: _section3AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(50 * (1 - _section3AnimationValue), 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Just Incentivize Creators!',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('Tell us you want:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(height: 1.5)),
                                    const SizedBox(height: 8),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        final offsetAnimation = Tween<Offset>(
                                          begin: const Offset(0.0, 0.25),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOut,
                                          ),
                                        );
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: offsetAnimation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: RichText(
                                        key: ValueKey<String>(
                                            _marketingLines[_currentLineIndex]
                                                .text),
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  height: 1.5,
                                                  fontWeight: FontWeight.bold),
                                          children: _buildStyledMarketingText(
                                              context,
                                              _marketingLines[
                                                  _currentLineIndex]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        'and we\'ll fund bounties that match your niche and audience.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(height: 1.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "Create Content" Section
              SliverToBoxAdapter(
                child: Container(
                  height: 500,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: _section4AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(-50 * (1 - _section4AnimationValue), 0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Regular Users Post...',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                Text(
                                    'Just 3 upvotes. That\'s all it took to steer thousands of dollars away from a big-box retailer and into the hands of a local business owner.',
                                    style:
                                        TextStyle(fontSize: 16, height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Opacity(
                          opacity: _section4AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(50 * (1 - _section4AnimationValue), 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                  'assets/images/marketing-content.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "Get Paid" Section
              SliverToBoxAdapter(
                child: Container(
                  height: 500,
                  color: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: _section5AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(-50 * (1 - _section5AnimationValue), 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                  'assets/images/marketing-paid.png'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Opacity(
                          opacity: _section5AnimationValue,
                          child: Transform.translate(
                            offset:
                                Offset(50 * (1 - _section5AnimationValue), 0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('...And Get Paid!',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                Text(
                                    'Anyone can submit their content for review. If it meets the bounty criteria, they get paid instantly with USDC!',
                                    style:
                                        TextStyle(fontSize: 16, height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // CTA Section
              SliverToBoxAdapter(
                child: Container(
                  height: 500,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: Opacity(
                      opacity: _section6AnimationValue,
                      child: Transform.scale(
                        scale: 0.95 + (_section6AnimationValue * 0.05),
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - _section6AnimationValue)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ready to Get Started?',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      label: const Text('Contact Us'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor:
                                              theme.colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16)),
                                      onPressed: () {
                                        final apiService =
                                            Provider.of<ApiService>(context,
                                                listen: false);
                                        showDialog(
                                          context: context,
                                          builder: (context) => ContactUsDialog(
                                              apiService: apiService),
                                        );
                                      }),
                                  const SizedBox(width: 20),
                                  ElevatedButton.icon(
                                      icon: const Icon(Icons.search),
                                      label: const Text('Explore Bounties'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.secondary,
                                          foregroundColor:
                                              theme.colorScheme.onSecondary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16)),
                                      onPressed: () => context.go('/bounties')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildStyledMarketingText(
      BuildContext context, _MarketingLine line) {
    final text = line.text;
    final platform = line.platformName;
    final firstIndex = text.indexOf(platform);

    if (firstIndex == -1) {
      return [TextSpan(text: text)]; // Fallback
    }

    final beforeText = text.substring(0, firstIndex);
    final afterText = text.substring(firstIndex + platform.length);

    final platformStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          height: 1.5,
          fontWeight: FontWeight.bold,
          color: line.textColor,
        );

    return [
      TextSpan(text: beforeText),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: line.decoration,
          child: Text(platform, style: platformStyle),
        ),
      ),
      TextSpan(text: afterText),
    ];
  }
}
