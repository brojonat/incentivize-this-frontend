import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:go_router/go_router.dart'; // For navigation

import 'bounty.dart';
import 'claim_dialog.dart';
import 'info_chip.dart';
import 'api_service.dart';
import 'paid_bounty_item.dart';
import 'loading_indicator.dart';
import 'storage_service.dart'; // For wallet and auth token
import 'auth_prompt_dialog.dart'; // For auth prompt

class BountyDetailScreen extends StatefulWidget {
  final String bountyId;
  final Bounty? initialBounty; // Optional initial bounty data

  const BountyDetailScreen({
    super.key,
    required this.bountyId,
    this.initialBounty,
  });

  @override
  State<BountyDetailScreen> createState() => _BountyDetailScreenState();
}

class _BountyDetailScreenState extends State<BountyDetailScreen> {
  late final ApiService _apiService;
  late final StorageService _storageService;
  List<PaidBountyItem> _paidItemsForWorkflow = [];
  bool _isLoadingPaidItems = true;
  bool _isLoadingBounty = true;
  String? _paidItemsError;
  String? _bountyError;
  Timer? _pollingTimer;
  Bounty? _currentBounty;
  String? _walletAddress;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _storageService = Provider.of<StorageService>(context, listen: false);
    _currentBounty = widget.initialBounty;
    _loadWalletAddress();
    _refreshBountyData(isInitialLoad: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWalletAddress() async {
    _walletAddress = await _storageService.getWalletAddress();
    if (mounted) {
      setState(() {});
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _refreshBountyData();
      }
    });
  }

  Future<void> _refreshBountyData({bool isInitialLoad = false}) async {
    bool showPaidItemsLoading = isInitialLoad || _paidItemsForWorkflow.isEmpty;
    bool showBountyLoading = isInitialLoad || _currentBounty == null;

    if (showPaidItemsLoading) {
      setState(() {
        _isLoadingPaidItems = true;
        _paidItemsError = null;
      });
    }
    if (showBountyLoading && _currentBounty == null) {
      // Only set loading if no bounty data yet
      setState(() {
        _isLoadingBounty = true;
        _bountyError = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.fetchBountyById(widget.bountyId), // Use widget.bountyId
        _apiService.fetchPaidBountiesForWorkflow(
            bountyId: widget.bountyId), // Use widget.bountyId
      ]);

      final newBountyDetails = results[0] as Bounty;
      final paidItems = results[1] as List<PaidBountyItem>;

      paidItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _currentBounty = newBountyDetails;
          _paidItemsForWorkflow = paidItems;

          if (showBountyLoading) {
            _isLoadingBounty = false;
          }
          _bountyError = null;

          if (showPaidItemsLoading) {
            _isLoadingPaidItems = false;
          }
          _paidItemsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error refreshing bounty data: ${e.toString()}');
        if (isInitialLoad || _currentBounty == null) {
          setState(() {
            _bountyError = 'Failed to load bounty details: ${e.toString()}';
            _isLoadingBounty = false;
          });
        }
        if (isInitialLoad || _paidItemsForWorkflow.isEmpty) {
          setState(() {
            _paidItemsError = 'Failed to load claim activity: ${e.toString()}';
            _isLoadingPaidItems = false;
          });
        }
      }
    }
  }

  Future<void> _submitClaim(
    String contentId,
    String walletAddress,
  ) async {
    if (_currentBounty == null) return;

    final token = await _storageService.getAuthToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AuthPromptDialog(
            onTokenSaved: () {
              print('Token saved, retrying submission...');
              _submitClaim(contentId, walletAddress);
            },
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        // Pop the claim dialog before showing snackbar
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

      await _storageService.saveWalletAddress(walletAddress);
      setState(() {
        _walletAddress = walletAddress; // Update local state
      });

      final result = await _apiService.submitClaim(
        bountyId: _currentBounty!.id,
        contentId: contentId,
        walletAddress: walletAddress,
        platformKind: _currentBounty!.platformKind,
        contentKind: _currentBounty!.contentKind,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Claim submitted successfully! ID: ${result["claim_id"] ?? "N/A"}'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshBountyData(); // Refresh data after successful claim
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting claim: ${e.toString()}'),
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

  void _showClaimDialog(BuildContext context) {
    if (_currentBounty == null) return;
    showDialog(
      context: context,
      builder: (context) => ClaimDialog(
        bounty: _currentBounty!,
        initialWalletAddress: _walletAddress,
        onSubmit: _submitClaim, // Pass the internal _submitClaim method
      ),
    );
  }

  String _formatRequirements(String description) {
    const String noRequirementsText = 'No specific requirements listed.';
    if (description == noRequirementsText) {
      return description;
    }
    final List<String> requirements = description
        .split('\n')
        .expand((line) => line.split('. '))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .map((sentence) =>
            '• ${sentence.endsWith('.') ? sentence : '$sentence.'}')
        .toList();
    return requirements.join('\n');
  }

  Widget _buildPaidBountyTile(ThemeData theme, PaidBountyItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      leading: Icon(
        Icons.timer_outlined,
        color: theme.colorScheme.secondary,
        size: 22,
      ),
      title: Text(
        item.formattedTimestamp,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    if (_isLoadingBounty && _currentBounty == null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.initialBounty?.title ?? 'Bounty Details')),
        body: const LoadingIndicator(message: 'Loading bounty details...'),
      );
    }

    if (_bountyError != null && _currentBounty == null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.initialBounty?.title ?? 'Bounty Details')),
        body: Center(
            child: Text(_bountyError!,
                style: TextStyle(color: theme.colorScheme.error))),
      );
    }

    if (_currentBounty == null) {
      // This case should ideally be covered by the error or loading state,
      // but as a fallback:
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Could not load bounty details.')),
      );
    }

    // Bounty is loaded, build the UI
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBounty!.title.isNotEmpty
            ? _currentBounty!.title
            : 'Bounty Details'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // If it can't pop (e.g., deep link), go to home
                context.go('/');
              }
            }),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      InfoChip(
                        icon: Icons.monetization_on_outlined,
                        text:
                            '${_currentBounty!.bountyPerPost.toStringAsFixed(2)} per post',
                        color: Colors.green.shade700,
                      ),
                      InfoChip(
                        icon: Icons.device_hub_outlined,
                        text: _currentBounty!.platformKind,
                        color: theme.colorScheme.tertiary,
                      ),
                      InfoChip(
                        icon: Icons.article_outlined,
                        text: _currentBounty!.contentKind,
                        color: Colors.orange.shade700,
                      ),
                      InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: _currentBounty!.remainingPostsDisplay,
                        color: theme.colorScheme.secondary,
                      ),
                      if (_currentBounty!.deadline != null &&
                          _currentBounty!.deadline!.year > 1970)
                        InfoChip(
                            icon: Icons.schedule,
                            text: dateFormat.format(_currentBounty!.deadline!),
                            color: theme.colorScheme.tertiary),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentBounty!.isClaimable
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentBounty!.rawStatus == 'AwaitingFunding' ||
                                      _currentBounty!.rawStatus ==
                                          'TransferringFee'
                                  ? Icons.hourglass_top_outlined
                                  : (_currentBounty!.rawStatus == 'Listening'
                                      ? Icons.play_circle_outline
                                      : (_currentBounty!.rawStatus == 'Paying'
                                          ? Icons.payment_outlined
                                          : (_currentBounty!.rawStatus ==
                                                      'Refunded' ||
                                                  _currentBounty!.rawStatus ==
                                                      'Cancelled'
                                              ? Icons.stop_circle_outlined
                                              : Icons.pause_circle_outline))),
                              size: 16,
                              color: _currentBounty!.isClaimable
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentBounty!.displayStatus,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _currentBounty!.isClaimable
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatRequirements(_currentBounty!.description),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Claim Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingPaidItems)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: LoadingIndicator(message: 'Loading claims...'),
              )
            else if (_paidItemsError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    _paidItemsError!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_paidItemsForWorkflow.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    'No claims have been paid for this bounty yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paidItemsForWorkflow.length,
                itemBuilder: (context, index) {
                  final item = _paidItemsForWorkflow[index];
                  return _buildPaidBountyTile(theme, item);
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _currentBounty!.isClaimable
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showClaimDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_task,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentBounty!.displayStatus == 'Listening' &&
                              !_currentBounty!.isClaimable
                          ? 'Bounty Not Claimable'
                          : (_currentBounty!.isClaimable
                              ? 'Claim This Bounty'
                              : 'Bounty: ${_currentBounty!.displayStatus}'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentBounty!.rawStatus == 'Refunded' ||
                              _currentBounty!.rawStatus == 'Cancelled'
                          ? Icons.cancel_outlined
                          : Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentBounty!.displayStatus == 'Listening'
                          ? 'Bounty Not Claimable'
                          : 'Bounty: ${_currentBounty!.displayStatus}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
