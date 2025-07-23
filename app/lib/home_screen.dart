import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import go_router
// For currency formatting
import 'dart:async'; // Added for Timer

import 'bounty.dart';
import 'api_service.dart';
import 'bounty_card.dart';
import 'create_bounty_dialog.dart';
import 'loading_indicator.dart';
// import 'bounty_detail_screen.dart'; // No longer directly navigating
import 'paid_bounty_item.dart'; // Import the new model
import 'search_bounties_sheet.dart'; // Import the search sheet
import 'responsive_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /* ------------------------------------------------------------------
   * Static shared polling timer.
   * Ensures ONLY ONE timer exists in the entire isolate regardless of how
   * many HomeScreen instances are (re)created during hot-reload, navigation,
   * etc. Each active HomeScreen registers itself in [_instances].
   * ----------------------------------------------------------------*/
  static Timer? _sharedTimer;
  static final List<_HomeScreenState> _instances = [];

  late final ApiService _apiService;
  late final AnimationController _animationController;
  // No per-instance timer anymore.

  List<Bounty> _bounties = [];
  List<Bounty> _filteredBounties = [];
  List<PaidBountyItem> _paidBounties = []; // Add state for paid bounties
  bool _isLoading = true;
  String? _errorMessage;
  String? _activeSearchQuery; // To store the current search query

  Set<String> _selectedPlatforms = {};
  double? _minRewardFilter;
  double? _maxRewardFilter;
  String? _funderWalletFilter;

  @override
  void initState() {
    super.initState();

    _instances.add(this);

    _apiService = Provider.of<ApiService>(context, listen: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadData(isInitialLoad: true);
    _ensureSharedTimerRunning();
  }

  @override
  void dispose() {
    _animationController.dispose();

    _instances.remove(this);

    // If no more instances, stop the shared timer
    if (_instances.isEmpty) {
      _sharedTimer?.cancel();
      _sharedTimer = null;
    }
    super.dispose();
  }

  // Shared polling logic --------------------------------------------------
  static void _ensureSharedTimerRunning() {
    if (_sharedTimer != null) return;

    void schedule() {
      _sharedTimer = Timer(const Duration(seconds: 5), () async {
        // Snapshot the instances to avoid modification during iteration
        final listeners = List<_HomeScreenState>.from(_instances);
        for (final state in listeners) {
          if (state.mounted && state._activeSearchQuery == null) {
            await state._loadData();
          }
        }

        // Continue if there are still listeners
        if (_instances.isNotEmpty) {
          schedule();
        } else {
          _sharedTimer?.cancel();
          _sharedTimer = null;
        }
      });
    }

    schedule();
  }

  static void _stopSharedTimer() {
    _sharedTimer?.cancel();
    _sharedTimer = null;
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
      List<Bounty> fetchedBounties;
      if (_activeSearchQuery != null && _activeSearchQuery!.trim().isNotEmpty) {
        // Perform search
        fetchedBounties = await _apiService.searchBounties(_activeSearchQuery!);
      } else {
        // Fetch all bounties, potentially with a funder wallet filter
        fetchedBounties =
            await _apiService.fetchBounties(funderWallet: _funderWalletFilter);
      }

      // Fetch paid bounties (only if not searching, or decide if search should also refresh this)
      // For now, let's keep paid bounties fetching independent of search to simplify.
      final paidBounties = _activeSearchQuery == null
          ? await _apiService.fetchPaidBounties(limit: 5)
          : _paidBounties; // Keep existing paid bounties if searching

      if (mounted) {
        setState(() {
          _bounties = fetchedBounties;
          if (_activeSearchQuery == null) {
            // Only update paidBounties if not searching
            _paidBounties = paidBounties;
          }
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

  Future<void> _performSearchAndUpdateList(String query) async {
    setState(() {
      _activeSearchQuery = query.trim().isEmpty ? null : query.trim();
      // Stop polling when a search is active
      if (_activeSearchQuery != null) {
        _stopSharedTimer(); // Cancel the shared timer
      } else {
        _stopSharedTimer(); // Stop existing timer first
        _ensureSharedTimerRunning(); // Restart polling if search is cleared
      }
    });
    // Close the search sheet, which should be done by the sheet itself before calling this
    // if (Navigator.of(context).canPop()) {
    //   Navigator.of(context).pop();
    // }
    await _loadData(
        isInitialLoad: true); // Reload data with the new search query
  }

  Future<void> _clearSearch() async {
    setState(() {
      _activeSearchQuery = null;
    });
    // We don't clear the filters here, that's a separate action.
    _stopSharedTimer(); // Stop existing timer first
    _ensureSharedTimerRunning(); // Restart polling
    await _loadData(isInitialLoad: true); // Reload to show all bounties
  }

  Future<void> _handleRefresh() async {
    // If a search is active, refreshing should re-run the search.
    // If no search is active, it refreshes all bounties.
    await _loadData(isInitialLoad: true);
    return Future.value();
  }

  void _applyFilters() {
    setState(() {
      _filteredBounties = _bounties.where((bounty) {
        final bool platformMatch = _selectedPlatforms.isEmpty ||
            _selectedPlatforms.contains(bounty.platformKind);

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

  void _clearFilters() {
    setState(() {
      _selectedPlatforms.clear();
      _minRewardFilter = null;
      _maxRewardFilter = null;
      _funderWalletFilter = null;
    });
    _loadData(isInitialLoad: true);
  }

  void _showFilterSheet() {
    final availablePlatforms =
        _bounties.map((b) => b.platformKind).toSet().toList();
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
    TextEditingController funderWalletController =
        TextEditingController(text: _funderWalletFilter);

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
                      'Reward',
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
                    Text(
                      'Filter by Funder Wallet (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: funderWalletController,
                      decoration: InputDecoration(
                        hintText: 'Enter wallet address...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: funderWalletController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(
                                      () => funderWalletController.clear());
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setModalState(() {}); // Rebuild to show/hide clear icon
                      },
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
                              funderWalletController.clear();
                            });
                          },
                          child: const Text('Reset All'),
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
                              _funderWalletFilter =
                                  funderWalletController.text.trim();
                            });
                            Navigator.pop(context);
                            // Now, trigger a reload from the backend with the new filters.
                            _loadData(isInitialLoad: true);
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

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Theme.of(context).cardColor,
            child: SearchBountiesSheet(
              onSearchSubmitted: _performSearchAndUpdateList,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10.0,
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
            Expanded(
              child: Text(
                  _activeSearchQuery != null && _activeSearchQuery!.isNotEmpty
                      ? 'Search Results'
                      : 'IncentivizeThis',
                  overflow: TextOverflow.ellipsis),
            ),
            if (_activeSearchQuery == null || _activeSearchQuery!.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CreateBountyDialog(),
                    );
                  },
                  tooltip: 'Create Bounty',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: () => context.push('/about'),
                  tooltip: 'About',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: _isLoading ? null : _showSearchSheet,
            tooltip: 'Search Bounties',
          ),
          if (_activeSearchQuery != null && _activeSearchQuery!.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear, // Clear search icon
                color: theme.colorScheme.primary,
              ),
              onPressed: _isLoading ? null : _clearSearch,
              tooltip: 'Clear Search',
            ),
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
                      _maxRewardFilter != null ||
                      (_funderWalletFilter != null &&
                          _funderWalletFilter!.isNotEmpty)
                  ? Icons.filter_list_off_outlined
                  : Icons.filter_list,
              color: theme.colorScheme.primary,
            ),
            onPressed: _isLoading ? null : _showFilterSheet,
            tooltip: 'Filter Bounties',
          ),
        ],
      ),
      body: CenteredConstrainedView(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return LoadingIndicator(
          message: _activeSearchQuery != null
              ? 'Searching for "$_activeSearchQuery"...'
              : 'Loading bounties...');
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

    bool isSearching =
        _activeSearchQuery != null && _activeSearchQuery!.isNotEmpty;
    bool noActiveBounties = _filteredBounties.isEmpty;
    bool noPaidBounties =
        _paidBounties.isEmpty && !isSearching; // Hide paid if searching for now
    bool filtersAreActive = _selectedPlatforms.isNotEmpty ||
        _minRewardFilter != null ||
        _maxRewardFilter != null ||
        (_funderWalletFilter != null && _funderWalletFilter!.isNotEmpty);

    if (noActiveBounties && (noPaidBounties || isSearching)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : (filtersAreActive
                        ? Icons.filter_alt_off_outlined
                        : Icons.layers_clear_outlined),
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No Results for "$_activeSearchQuery"'
                    : (filtersAreActive
                        ? 'No Matching Bounties'
                        : 'No Bounties Available'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Try a different search term or clear the search.'
                    : (filtersAreActive
                        ? 'Try adjusting your filters or clear them to see all available bounties.'
                        : 'There are no active or recently paid bounties to display right now. Pull down to refresh.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (filtersAreActive && !isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
              if (isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: _clearSearch, // Button to clear the search
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Search'),
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
          if (isSearching && _activeSearchQuery!.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 16.0, bottom: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Search Results for "$_activeSearchQuery":',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    // TextButton.icon( // Alternative clear button placement
                    //   icon: Icon(Icons.clear, size: 18),
                    //   label: Text('Clear'),
                    //   onPressed: _clearSearch,
                    //   style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                    // )
                  ],
                ),
              ),
            ),
          ],
          if (!noActiveBounties) ...[
            if (!isSearching) // Only show "Active Bounties" title if not searching
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
          if (noActiveBounties && !isSearching && !noPaidBounties) ...[
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
          if (!noPaidBounties && !isSearching) ...[
            // Hide paid bounties when searching
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
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
        _maxRewardFilter != null ||
        (_funderWalletFilter != null && _funderWalletFilter!.isNotEmpty);

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
        child: const Icon(Icons.receipt_long, size: 20),
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
