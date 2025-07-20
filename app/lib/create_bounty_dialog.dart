import 'dart:async';

import 'package:app/api_service.dart';
import 'package:app/auth_prompt_dialog.dart';
import 'package:app/notification_service.dart';
import 'package:app/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateBountyDialog extends StatefulWidget {
  const CreateBountyDialog({super.key});

  @override
  State<CreateBountyDialog> createState() => _CreateBountyDialogState();
}

class _CreateBountyDialogState extends State<CreateBountyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _requirementsController = TextEditingController();
  final _perPostController = TextEditingController();
  final _numberOfBountiesController = TextEditingController();

  bool _isLoading = false;
  String _selectedDuration = '30d';
  double _totalCost = 0.0;

  Map<String, dynamic>? _bountyCreationResponse;
  Map<String, dynamic>? _config;
  Timer? _countdownTimer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _perPostController.addListener(_updateTotalCost);
    _numberOfBountiesController.addListener(_updateTotalCost);
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(expiresAt)) {
        setState(() {
          _timeRemaining = Duration.zero;
        });
        timer.cancel();
      } else {
        setState(() {
          _timeRemaining = expiresAt.difference(now);
        });
      }
    });
  }

  void _updateTotalCost() {
    final perPost = double.tryParse(_perPostController.text) ?? 0;
    final numBounties = int.tryParse(_numberOfBountiesController.text) ?? 0;
    setState(() {
      _totalCost = 2 * numBounties * perPost;
    });
  }

  @override
  void dispose() {
    _requirementsController.dispose();
    _perPostController.dispose();
    _numberOfBountiesController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final storageService =
          Provider.of<StorageService>(context, listen: false);
      String? token = await storageService.getAuthToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AuthPromptDialog(
              onTokenSaved: () {
                _submitForm();
              },
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final response = await apiService.createBounty(
          requirements: [_requirementsController.text],
          bountyPerPost: double.parse(_perPostController.text),
          totalBounty: _totalCost,
          timeoutDuration: _selectedDuration,
          token: token,
        );

        final configData = await apiService.fetchAppConfig();

        if (mounted) {
          final expiresAt =
              DateTime.parse(response['payment_timeout_expires_at']);
          _startCountdown(expiresAt);

          setState(() {
            _config = configData;
            _bountyCreationResponse = response;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError('Failed to create bounty: $e');
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double maxDialogWidth = 400.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth =
        (screenWidth > maxDialogWidth + 48) ? maxDialogWidth : screenWidth - 48;

    return AlertDialog(
      title: Text(_bountyCreationResponse == null
          ? 'Create Bounty'
          : 'Fund Your Bounty'),
      content: SizedBox(
        width: dialogWidth,
        child:
            _bountyCreationResponse == null ? _buildFormView() : _buildQrView(),
      ),
      actions: [
        if (_bountyCreationResponse == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Submit'),
          ),
        ] else
          TextButton(
            onPressed: () {
              _countdownTimer?.cancel();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          )
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _requirementsController,
              decoration: const InputDecoration(labelText: 'Requirements'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter requirements';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _perPostController,
              decoration: const InputDecoration(labelText: 'Bounty Per Post'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberOfBountiesController,
              decoration:
                  const InputDecoration(labelText: 'Number of Bounties'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a whole number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text('Duration',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: ['1d', '3d', '7d', '30d', '60d', '90d', '180d']
                  .map((duration) {
                return ChoiceChip(
                  label: Text(duration),
                  selected: _selectedDuration == duration,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Total Cost: \$${_totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Widget _buildQrView() {
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final walletAddress = _config!['escrow_wallet'];
    final usdcMintAddress = _config!['usdc_mint_address'];
    final bountyId = _bountyCreationResponse!['bounty_id'];
    final totalCharged = _bountyCreationResponse!['total_charged'] as num;
    final uri =
        'solana:$walletAddress?amount=$totalCharged&spl-token=$usdcMintAddress&message=${Uri.encodeComponent('Bounty ID: $bountyId')}';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_timeRemaining != null)
            Text(
              'Expires in: ${_formatDuration(_timeRemaining!)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 10),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: QrImageView(
              data: uri,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Scan with your wallet to fund the bounty.'),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Handle error
      if (mounted) {
        NotificationService.showError('Could not launch link');
      }
    }
  }
}
