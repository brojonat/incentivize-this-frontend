import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'contact_us_dialog.dart';

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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final offset = _scrollController.offset;

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

      _section2AnimationValue =
          _calculateAnimationValue(offset, screenHeight, 1);
      _section3AnimationValue =
          _calculateAnimationValue(offset, screenHeight, 2);
      _section4AnimationValue =
          _calculateAnimationValue(offset, screenHeight, 3);
      _section5AnimationValue =
          _calculateAnimationValue(offset, screenHeight, 4);

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

  double _calculateAnimationValue(
      double offset, double screenHeight, int section) {
    final sectionHeight = 500.0;
    final sectionStart = screenHeight + (section - 1) * sectionHeight;
    final animationStart = sectionStart - screenHeight * 0.8;
    final animationEnd = sectionStart;

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
              child: Image.asset(
                'assets/images/marketing-carrot.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              // Hero Section
              SliverToBoxAdapter(
                child: Container(
                  height: screenHeight,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      const SizedBox(height: 40),
                      Opacity(
                        opacity: _arrowOpacity,
                        child: SlideTransition(
                          position: _arrowAnimation,
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white, size: 48),
                        ),
                      ),
                    ],
                  ),
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
                                    'Yuck. Nobody wants to see this. Nobody is clicking on this. At least not on purpose.',
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Just Incentivize Creators!',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                Text(
                                    'Tell us what you want and where you want it (Reddit, Instagram, YouTube, etc.), and we\'ll fund bounties that match your niche and audience.',
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
                                    'People post on the Internet all the time. Thanks to this unremarkable comment, I spent thousands at a local lumber business instead of the big box stores!',
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
                                    'Anyone can submit their content for review. If it meets the bounty criteria, the user gets paid with USDC. Everyone wins, it\'s that easy!',
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
                  color: theme.colorScheme.surfaceVariant,
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
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const ContactUsDialog(),
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
}
