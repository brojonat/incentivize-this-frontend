import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:go_router/go_router.dart'; // For navigation
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import 'bounty.dart';
import 'claim_dialog.dart';
import 'info_chip.dart';
import 'api_service.dart';
import 'paid_bounty_item.dart';
import 'loading_indicator.dart';
import 'storage_service.dart'; // For wallet and auth token
import 'auth_prompt_dialog.dart'; // For auth prompt
import 'responsive_layout.dart';
import 'notification_service.dart';
import 'funding_qr_dialog.dart';

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
        NotificationService.showPageSuccess('Claim submitted successfully!');
        _refreshBountyData(); // Refresh data after successful claim
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showPageError(
            'Failed to submit claim: ${e.toString()}');
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

    // After loading, _currentBounty should not be null.
    // Use a local variable for convenience and null safety.
    final bounty = _currentBounty!;

    return Scaffold(
      body: CenteredConstrainedView(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              title: Text(bounty.title),
              floating: true,
              pinned: true,
              snap: true,
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
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
                                    '\$${_currentBounty!.bountyPerPost.toStringAsFixed(2)}',
                                color: Colors.green.shade700,
                              ),
                              InfoChip(
                                icon: _currentBounty!.platformIcon,
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
                              Builder(builder: (context) {
                                final statusInfo =
                                    _currentBounty!.getStatusInfo(theme);
                                return InfoChip(
                                  icon: statusInfo.icon,
                                  text: statusInfo.text,
                                  color: statusInfo.textColor,
                                  backgroundColor: statusInfo.backgroundColor,
                                  textColor: statusInfo.textColor,
                                );
                              }),
                              if (_currentBounty!.tier != 8)
                                InfoChip(
                                  icon: _currentBounty!.tierInfo(theme).icon,
                                  text: _currentBounty!.tierInfo(theme).name,
                                  color:
                                      _currentBounty!.tierInfo(theme).textColor,
                                  backgroundColor: _currentBounty!
                                      .tierInfo(theme)
                                      .backgroundColor,
                                  textColor:
                                      _currentBounty!.tierInfo(theme).textColor,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Html(
                              data: md
                                  .markdownToHtml(_currentBounty!.description),
                              style: {
                                "body": Style(
                                  fontSize: FontSize(
                                      theme.textTheme.bodyLarge?.fontSize ??
                                          16),
                                  lineHeight: const LineHeight(1.5),
                                ),
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    if (bounty.rawStatus == 'AwaitingFunding') ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (bounty.totalCharged == null ||
                                bounty.paymentTimeoutExpiresAt == null) {
                              NotificationService.showError(
                                  'Funding information is not available for this bounty.');
                              return;
                            }

                            final apiService =
                                Provider.of<ApiService>(context, listen: false);
                            try {
                              final config = await apiService.fetchAppConfig();
                              final walletAddress = config['escrow_wallet'];
                              final usdcMintAddress =
                                  config['usdc_mint_address'];

                              if (walletAddress == null ||
                                  usdcMintAddress == null) {
                                throw Exception('Configuration is missing');
                              }

                              showDialog(
                                context: context,
                                builder: (context) => FundingQrDialog(
                                  bountyId: bounty.id,
                                  totalCharged: bounty.totalCharged!,
                                  paymentTimeoutExpiresAt:
                                      bounty.paymentTimeoutExpiresAt!,
                                  walletAddress: walletAddress,
                                  usdcMintAddress: usdcMintAddress,
                                ),
                              );
                            } catch (e) {
                              NotificationService.showError(
                                  'Could not load funding information: $e');
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Fund Bounty'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: _buildClaimButton(theme),
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
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimButton(ThemeData theme) {
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      minimumSize: const Size(double.infinity, 50), // Ensure it's wide
    );

    if (_currentBounty!.isClaimable) {
      return ElevatedButton(
        onPressed: () => _showClaimDialog(context),
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
          foregroundColor:
              WidgetStateProperty.all(theme.colorScheme.onPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_task),
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
      );
    } else {
      return ElevatedButton(
        onPressed: null,
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
              theme.colorScheme.outline.withOpacity(0.2)),
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
              'Bounty: ${_currentBounty!.displayStatus}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
}
