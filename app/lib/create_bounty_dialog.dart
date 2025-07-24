import 'dart:async';

import 'package:app/api_service.dart';
import 'package:app/auth_prompt_dialog.dart';
import 'package:app/funding_qr_dialog.dart';
import 'package:app/notification_service.dart';
import 'package:app/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  bool _showAllDurations = false;

  @override
  void initState() {
    super.initState();
    _perPostController.addListener(_updateTotalCost);
    _numberOfBountiesController.addListener(_updateTotalCost);
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double dialogWidth =
        (screenWidth > maxDialogWidth + 48) ? maxDialogWidth : screenWidth - 48;

    // Calculate available height, accounting for keyboard and dialog chrome
    final double availableHeight = screenHeight -
        keyboardHeight -
        200; // 200px for title, actions, padding

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      title: Text(_bountyCreationResponse == null
          ? 'Create Bounty'
          : 'Fund Your Bounty'),
      content: SizedBox(
        width: dialogWidth,
        height: availableHeight > 300
            ? null
            : availableHeight, // Constrain height if keyboard is up
        child: _bountyCreationResponse == null
            ? _buildFormView()
            : SingleChildScrollView(
                child: FundingQrContent(
                  bountyId: _bountyCreationResponse!['bounty_id'],
                  totalCharged:
                      (_bountyCreationResponse!['total_charged'] as num)
                          .toDouble(),
                  paymentTimeoutExpiresAt: DateTime.parse(
                      _bountyCreationResponse!['payment_timeout_expires_at']),
                  walletAddress: _config!['escrow_wallet'],
                  usdcMintAddress: _config!['usdc_mint_address'],
                  showActions: true,
                  onDone: () => Navigator.of(context).pop(),
                ),
              ),
      ),
      actions: _bountyCreationResponse == null
          ? [
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
            ]
          : [],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _requirementsController,
              decoration: const InputDecoration(
                labelText: 'Requirements',
                counterText: '', // Hide the character counter
              ),
              maxLength: 4000,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
              decoration: const InputDecoration(
                labelText: 'Bounty Per Post',
                counterText: '', // Hide the character counter
              ),
              maxLength: 10, // Allows for amounts up to 9,999,999.99
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final amount = double.parse(value);
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberOfBountiesController,
              decoration: const InputDecoration(
                labelText: 'Number of Bounties',
                counterText: '', // Hide the character counter
              ),
              maxLength: 6, // Allows for up to 999,999 bounties
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a whole number';
                }
                if (int.tryParse(value)! <= 0) {
                  return 'Number of bounties must be greater than 0';
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
              runSpacing: 4.0,
              children: [
                ..._getDurationChips(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllDurations = !_showAllDurations;
                    });
                  },
                  child:
                      Text(_showAllDurations ? 'Show less' : 'More options...'),
                )
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Total Cost: \$${_totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // Add bottom padding to ensure last field is accessible when keyboard is up
            SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 50 : 0),
          ],
        ),
      ),
    );
  }

  List<Widget> _getDurationChips() {
    const allDurations = ['1d', '3d', '7d', '30d', '60d', '90d', '180d'];
    List<String> visibleDurations;

    if (_showAllDurations) {
      visibleDurations = allDurations;
    } else {
      visibleDurations = allDurations.take(3).toList();
      if (!visibleDurations.contains(_selectedDuration)) {
        visibleDurations.add(_selectedDuration);
      }
    }

    return visibleDurations.map((duration) {
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
    }).toList();
  }
}
