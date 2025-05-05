import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bounty.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'bounty_card.dart';
import 'claim_dialog.dart';
import 'loading_indicator.dart';
import 'theme.dart';
import 'bounty_detail_screen.dart';
import 'auth_prompt_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late final StorageService _storageService;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  List<Bounty> _bounties = [];
  List<Bounty> _filteredBounties = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _walletAddress;

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

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load saved wallet address
      final walletAddress = await _storageService.getWalletAddress();

      // Fetch bounties from API
      final bounties = await _apiService.fetchBounties();

      if (mounted) {
        setState(() {
          _bounties = bounties;
          _filteredBounties = List.from(_bounties);
          _walletAddress = walletAddress;
          _isLoading = false;
        });

        _applyFilters();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load bounties: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    _animationController.reset();
    await _loadData();
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BountyDetailScreen(
          bounty: bounty,
          walletAddress: _walletAddress,
          onSubmitClaim: (contentId, walletAddress) =>
              _submitClaim(bounty, contentId, walletAddress),
        ),
      ),
    );
  }

  Future<void> _submitClaim(
    Bounty bounty,
    String contentId,
    String walletAddress,
  ) async {
    // 1. Check for auth token
    final token = await _storageService.getAuthToken();

    if (token == null || token.isEmpty) {
      // 2. If no token, show the AuthPromptDialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must enter token or cancel
          builder: (_) => AuthPromptDialog(
            onTokenSaved: () {
              // 3. When token is saved, *try* submitting again
              // Note: Could add loading indicator here while waiting
              print('Token saved, retrying submission...');
              _submitClaim(bounty, contentId, walletAddress);
            },
          ),
        );
      }
      return; // Stop execution until token is provided
    }

    // 4. If token exists, proceed with submission
    try {
      // Show loading/processing indicator (optional)
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submitting claim...')));

      // Save wallet address for future use
      await _storageService.saveWalletAddress(walletAddress);

      // Submit claim to API using details from the bounty object
      final result = await _apiService.submitClaim(
        bountyId: bounty.id,
        contentId: contentId,
        walletAddress: walletAddress,
        platformType: bounty.platformType,
        contentKind: bounty.contentKind,
      );

      if (mounted) {
        // Close claim dialog (if it was open before auth prompt)
        // Check if a dialog is open before popping
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Pop the original ClaimDialog
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Refresh bounties list
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPlatforms.clear();
      _minRewardFilter = null;
      _maxRewardFilter = null;
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    // Get unique platform types from the original bounties list
    final availablePlatforms =
        _bounties.map((b) => b.platformType).toSet().toList();
    availablePlatforms.sort(); // Sort for consistent order

    // Define reward range options (customize as needed)
    final Map<String, ({double? min, double? max})> rewardRanges = {
      'Any Reward': (min: null, max: null),
      '< \$10': (min: null, max: 9.99),
      '\$10 - \$50': (min: 10.0, max: 50.0),
      '\$50 - \$100': (min: 50.0, max: 100.0),
      '> \$100': (min: 100.01, max: null),
    };
    // Find the key corresponding to the current filter state
    String currentRewardRangeKey = rewardRanges.keys.firstWhere(
      (key) =>
          rewardRanges[key]!.min == _minRewardFilter &&
          rewardRanges[key]!.max == _maxRewardFilter,
      orElse: () => rewardRanges.keys.first, // Default to 'Any Reward'
    );

    // *** Declare temporary state variables OUTSIDE the StatefulBuilder ***
    Set<String> tempSelectedPlatforms = Set.from(_selectedPlatforms);
    String tempRewardRangeKey = currentRewardRangeKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to take more height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage local state within the sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // *** REMOVE re-initialization from here ***
            // Set<String> tempSelectedPlatforms = Set.from(_selectedPlatforms); // REMOVED
            // String tempRewardRangeKey = currentRewardRangeKey; // REMOVED

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust for keyboard
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
                            // Reset temporary state within the sheet
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
                            // Apply filters to the main screen state
                            setState(() {
                              _selectedPlatforms = tempSelectedPlatforms;
                              _minRewardFilter =
                                  rewardRanges[tempRewardRangeKey]?.min;
                              _maxRewardFilter =
                                  rewardRanges[tempRewardRangeKey]?.max;
                            });
                            _applyFilters(); // Apply the chosen filters
                            Navigator.pop(context); // Close the sheet
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Bottom padding
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
            Icon(
              Icons.assignment_outlined,
              color: theme.colorScheme.primary,
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

    if (_filteredBounties.isEmpty) {
      bool filtersActive = _selectedPlatforms.isNotEmpty ||
          _minRewardFilter != null ||
          _maxRewardFilter != null;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtersActive
                    ? Icons.filter_alt_off_outlined
                    : Icons.search_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                filtersActive ? 'No Matching Bounties' : 'No Bounties Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filtersActive
                    ? 'Try adjusting your filters or clear them to see all available bounties.'
                    : 'There are no bounties available at the moment. Pull down to refresh.',
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        itemCount: _filteredBounties.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final bounty = _filteredBounties[index];
          return BountyCard(
            bounty: bounty,
            onTap: () => _showBountyDetail(bounty),
          );
        },
      ),
    );
  }
}
