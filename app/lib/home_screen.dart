import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import go_router
// For currency formatting
import 'dart:async'; // Added for Timer

import 'bounty.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'bounty_card.dart';
import 'loading_indicator.dart';
// import 'bounty_detail_screen.dart'; // No longer directly navigating
import 'auth_prompt_dialog.dart';
import 'paid_bounty_item.dart'; // Import the new model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late final StorageService _storageService;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  Timer? _pollingTimer; // Added for polling

  List<Bounty> _bounties = [];
  List<Bounty> _filteredBounties = [];
  List<PaidBountyItem> _paidBounties = []; // Add state for paid bounties
  bool _isLoading = true;
  String? _errorMessage;
  // String? _walletAddress; // Wallet address is managed by BountyDetailScreen

  Set<String> _selectedPlatforms = {};
  double? _minRewardFilter;
  double? _maxRewardFilter;

  @override
  void initState() {
    super.initState();

    _apiService = Provider.of<ApiService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadData(isInitialLoad: true);
    _startPolling(); // Start polling
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel(); // Cancel any existing timer
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Check if the widget is still in the tree
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool isInitialLoad = false}) async {
    bool showLoadingIndicator = isInitialLoad || _bounties.isEmpty;

    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    if (isInitialLoad) {
      _animationController.reset();
    }

    try {
      // Fetch bounties and paid bounties concurrently
      final results = await Future.wait([
        _apiService.fetchBounties(),
        _apiService.fetchPaidBounties(limit: 5), // Fetch top 5 paid
      ]);

      final bounties = results[0] as List<Bounty>;
      final paidBounties = results[1] as List<PaidBountyItem>;

      if (mounted) {
        setState(() {
          _bounties = bounties;
          _paidBounties = paidBounties;
          // _walletAddress = walletAddress; // Wallet address managed by BountyDetailScreen
          if (showLoadingIndicator) {
            _isLoading = false;
          }
        });

        _applyFilters();
        if (isInitialLoad) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        if (isInitialLoad || _bounties.isEmpty) {
          setState(() {
            _errorMessage = 'Failed to load data: ${e.toString()}';
            _isLoading = false;
          });
        } else {
          print('Background refresh failed: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData(isInitialLoad: true);
    return Future.value();
  }

  void _applyFilters() {
    setState(() {
      _filteredBounties = _bounties.where((bounty) {
        final bool platformMatch = _selectedPlatforms.isEmpty ||
            _selectedPlatforms.contains(bounty.platformType);

        final bool rewardMatch = (_minRewardFilter == null ||
                bounty.bountyPerPost >= _minRewardFilter!) &&
            (_maxRewardFilter == null ||
                bounty.bountyPerPost <= _maxRewardFilter!);

        return platformMatch && rewardMatch;
      }).toList();
    });
  }

  void _showBountyDetail(Bounty bounty) {
    // Use go_router to navigate
    context.go('/bounties/${bounty.id}', extra: bounty);
  }

  // _submitClaim method is removed as it's now handled in BountyDetailScreen

  void _clearFilters() {
    setState(() {
      _selectedPlatforms.clear();
      _minRewardFilter = null;
      _maxRewardFilter = null;
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    final availablePlatforms =
        _bounties.map((b) => b.platformType).toSet().toList();
    availablePlatforms.sort();

    final Map<String, ({double? min, double? max})> rewardRanges = {
      'Any Reward': (min: null, max: null),
      '< \$10': (min: null, max: 9.99),
      '\$10 - \$50': (min: 10.0, max: 50.0),
      '\$50 - \$100': (min: 50.0, max: 100.0),
      '> \$100': (min: 100.01, max: null),
    };
    String currentRewardRangeKey = rewardRanges.keys.firstWhere(
      (key) =>
          rewardRanges[key]!.min == _minRewardFilter &&
          rewardRanges[key]!.max == _maxRewardFilter,
      orElse: () => rewardRanges.keys.first,
    );

    Set<String> tempSelectedPlatforms = Set.from(_selectedPlatforms);
    String tempRewardRangeKey = currentRewardRangeKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Bounties',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Platform',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: availablePlatforms.map((platform) {
                        return FilterChip(
                          label: Text(platform),
                          selected: tempSelectedPlatforms.contains(platform),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempSelectedPlatforms.add(platform);
                              } else {
                                tempSelectedPlatforms.remove(platform);
                              }
                            });
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          showCheckmark: true,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Reward per Post',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: rewardRanges.keys.map((key) {
                        return ChoiceChip(
                          label: Text(
                            key,
                            style: tempRewardRangeKey == key
                                ? TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  )
                                : TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          ),
                          selected: tempRewardRangeKey == key,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempRewardRangeKey = key;
                              });
                            }
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelectedPlatforms.clear();
                              tempRewardRangeKey = rewardRanges.keys.first;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPlatforms = tempSelectedPlatforms;
                              _minRewardFilter =
                                  rewardRanges[tempRewardRangeKey]?.min;
                              _maxRewardFilter =
                                  rewardRanges[tempRewardRangeKey]?.max;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '🥕',
              style: TextStyle(
                fontSize: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('IncentivizeThis'),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.primary,
            ),
            onPressed: _isLoading ? null : _handleRefresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              _selectedPlatforms.isNotEmpty ||
                      _minRewardFilter != null ||
                      _maxRewardFilter != null
                  ? Icons.filter_list
                  : Icons.filter_list_off_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: _isLoading ? null : _showFilterSheet,
            tooltip: 'Filter Bounties',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading bounties...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(
                  Icons.refresh,
                  color: theme.colorScheme.onPrimary,
                ),
                label: Text(
                  'Try Again',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    bool noActiveBounties = _filteredBounties.isEmpty;
    bool noPaidBounties = _paidBounties.isEmpty;
    bool filtersAreActive = _selectedPlatforms.isNotEmpty ||
        _minRewardFilter != null ||
        _maxRewardFilter != null;

    if (noActiveBounties && noPaidBounties) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtersAreActive
                    ? Icons.filter_alt_off_outlined
                    : Icons.layers_clear_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                filtersAreActive
                    ? 'No Matching Bounties'
                    : 'No Bounties Available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filtersAreActive
                    ? 'Try adjusting your filters or clear them to see all available bounties.'
                    : 'There are no active or recently paid bounties to display right now. Pull down to refresh.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (filtersAreActive)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: Icon(Icons.clear_all),
                    label: Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        slivers: <Widget>[
          if (!noActiveBounties) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                child: Text(
                  'Active Bounties',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bounty = _filteredBounties[index];
                  return BountyCard(
                    bounty: bounty,
                    onTap: () => _showBountyDetail(bounty),
                  );
                },
                childCount: _filteredBounties.length,
              ),
            ),
          ],
          if (noActiveBounties && !noPaidBounties) ...[
            if (filtersAreActive) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: _buildNoActiveBountiesMessage(theme),
                ),
              ),
            ] else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: _buildNoActiveBountiesAvailableMessage(theme),
                ),
              ),
            ],
          ],
          if (!noPaidBounties) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 24.0,
                  bottom: 8.0,
                ),
                child: Text(
                  'Recently Paid',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _paidBounties[index];
                  return _buildPaidBountyTile(theme, item);
                },
                childCount: _paidBounties.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoActiveBountiesMessage(ThemeData theme) {
    bool filtersActive = _selectedPlatforms.isNotEmpty ||
        _minRewardFilter != null ||
        _maxRewardFilter != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No Matching Active Bounties',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting or clearing your filters.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (filtersActive)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.clear_all),
                label: Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoActiveBountiesAvailableMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Bounties Currently',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or pull down to refresh.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaidBountyTile(ThemeData theme, PaidBountyItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.secondary,
        child: Icon(Icons.receipt_long, size: 20),
      ),
      title: Text(
        item.formattedAmount,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.formattedTimestamp,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}
