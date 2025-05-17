import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Added for Timer

import 'bounty.dart';
import 'claim_dialog.dart';
import 'info_chip.dart';
import 'api_service.dart';
import 'paid_bounty_item.dart';
import 'loading_indicator.dart';

class BountyDetailScreen extends StatefulWidget {
  final Bounty bounty;
  final String? walletAddress;
  final Function(String contentId, String walletAddress) onSubmitClaim;

  const BountyDetailScreen({
    super.key,
    required this.bounty,
    this.walletAddress,
    required this.onSubmitClaim,
  });

  @override
  State<BountyDetailScreen> createState() => _BountyDetailScreenState();
}

class _BountyDetailScreenState extends State<BountyDetailScreen> {
  late final ApiService _apiService;
  List<PaidBountyItem> _paidItemsForWorkflow = [];
  bool _isLoadingPaidItems = true;
  bool _isLoadingBounty = true;
  String? _paidItemsError;
  String? _bountyError;
  Timer? _pollingTimer;
  Bounty? _currentBounty;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _currentBounty = widget.bounty;
    _refreshBountyData(isInitialLoad: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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
    if (showBountyLoading) {
      setState(() {
        _isLoadingBounty = true;
        _bountyError = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.fetchBountyById(widget.bounty.id),
        _apiService.fetchPaidBountiesForWorkflow(bountyId: widget.bounty.id),
      ]);

      final newBountyDetails = results[0] as Bounty;
      final paidItems = results[1] as List<PaidBountyItem>;

      // Sort paid items: most recent first
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

  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClaimDialog(
        bounty: _currentBounty!,
        initialWalletAddress: widget.walletAddress,
        onSubmit: widget.onSubmitClaim,
      ),
    );
  }

  String _formatRequirements(String description) {
    const String noRequirementsText = 'No specific requirements listed.';
    if (description == noRequirementsText) {
      return description;
    }

    // Split by newline, then split each line by ". " to get sentences.
    // Flatten the list, trim whitespace, filter empty strings, and add bullets.
    final List<String> requirements = description
        .split('\n')
        .expand((line) => line.split('. ')) // Split each line into sentences
        .map((sentence) => sentence.trim()) // Trim whitespace
        .where((sentence) => sentence.isNotEmpty) // Remove empty sentences
        // Add bullet point and ensure it ends with a period
        .map((sentence) =>
            '• ${sentence.endsWith('.') ? sentence : '$sentence.'}')
        .toList();

    return requirements.join('\n');
  }

  // Helper Widget to build a tile for a paid bounty (now only showing timestamp)
  Widget _buildPaidBountyTile(ThemeData theme, PaidBountyItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      leading: Icon(
        Icons.timer_outlined, // Changed icon to reflect time
        color: theme.colorScheme.secondary,
        size: 22,
      ),
      title: Text(
        item.formattedTimestamp, // Display formatted timestamp
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
        appBar: AppBar(title: const Text('Bounty Details')),
        body: const LoadingIndicator(message: 'Loading bounty details...'),
      );
    }

    if (_bountyError != null && _currentBounty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bounty Details')),
        body: Center(
            child: Text(_bountyError!,
                style: TextStyle(color: theme.colorScheme.error))),
      );
    }

    if (_currentBounty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Could not load bounty details.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bounty Details'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with bounty title and status
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
                  Row(
                    children: [
                      InfoChip(
                        icon: Icons.monetization_on_outlined,
                        text:
                            '${_currentBounty!.bountyPerPost.toStringAsFixed(2)} per post',
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.device_hub_outlined,
                        text: _currentBounty!.platformType,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.article_outlined,
                        text: _currentBounty!.contentKind,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: _currentBounty!.remainingPostsDisplay,
                        color: theme.colorScheme.secondary,
                      ),
                      if (_currentBounty!.deadline != null &&
                          _currentBounty!.deadline!.year > 1970) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(_currentBounty!.deadline!),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentBounty!.isActive
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentBounty!.isActive
                                  ? Icons.verified_outlined
                                  : Icons.hourglass_empty,
                              size: 16,
                              color: _currentBounty!.isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentBounty!.isActive ? 'Active' : 'Closed',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _currentBounty!.isActive
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

            // Paid Items for this Workflow Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Claim Activity', // Updated section title
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
                shrinkWrap:
                    true, // Important for ListView inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                itemCount: _paidItemsForWorkflow.length,
                itemBuilder: (context, index) {
                  final item = _paidItemsForWorkflow[index];
                  return _buildPaidBountyTile(theme, item);
                },
              ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
      bottomNavigationBar: _currentBounty!.isActive
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
                      'Claim This Bounty',
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
                onPressed: null, // Disabled button
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
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bounty No Longer Available',
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
