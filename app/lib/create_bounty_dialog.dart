import 'dart:async';

import 'package:app/api_service.dart';
import 'package:app/auth_prompt_dialog.dart';
import 'package:app/funding_qr_dialog.dart';
import 'package:app/notification_service.dart';
import 'package:app/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CreateBountyDialog extends StatefulWidget {
  const CreateBountyDialog({super.key});

  @override
  State<CreateBountyDialog> createState() => _CreateBountyDialogState();
}

class _CreateBountyDialogState extends State<CreateBountyDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _requirementsController = TextEditingController();
  final _perPostController = TextEditingController();
  final _numberOfBountiesController = TextEditingController();

  bool _isLoading = false;
  bool _isHardening = false;
  String _selectedDuration = '30d';
  double _totalCost = 0.0;

  Map<String, dynamic>? _bountyCreationResponse;
  Map<String, dynamic>? _config;
  bool _showAllDurations = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _perPostController.addListener(_updateTotalCost);
    _numberOfBountiesController.addListener(_updateTotalCost);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
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
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final response = await apiService.createBounty(
          requirements: [_requirementsController.text],
          bountyPerPost: double.parse(_perPostController.text),
          totalBounty: _totalCost,
          timeoutDuration: _selectedDuration,
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
        if (e is ApiUnauthorizedException) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AuthPromptDialog(
                onTokenSaved: () {
                  _submitForm(); // Retry the submission
                },
              ),
            );
          }
        } else {
          if (mounted) {
            NotificationService.showError('Failed to create bounty: $e');
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _hardenRequirements() async {
    final current = _requirementsController.text;
    if (current.trim().isEmpty) {
      NotificationService.showError('Enter requirements to refine.');
      return;
    }

    setState(() {
      _isHardening = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final hardened = await apiService.hardenRequirements(current);
      if (!mounted) return;
      setState(() {
        _requirementsController.text = hardened;
        // Move cursor to end
        _requirementsController.selection = TextSelection.fromPosition(
          TextPosition(offset: _requirementsController.text.length),
        );
      });
      NotificationService.showSuccess('Requirements refined.');
    } catch (e) {
      if (e.toString().contains('ApiUnauthorizedException')) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AuthPromptDialog(
            onTokenSaved: () {
              // Retry after token is saved
              _hardenRequirements();
            },
          ),
        );
      } else {
        NotificationService.showError('Failed to refine: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHardening = false;
        });
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        final Color color1, color2;
                        if (_isHardening) {
                          color1 = Color.lerp(Colors.grey.shade600,
                              Colors.grey.shade800, _glowAnimation.value)!;
                          color2 = Color.lerp(Colors.grey.shade800,
                              Colors.grey.shade600, _glowAnimation.value)!;
                        } else {
                          color1 = Color.lerp(
                              const Color.fromARGB(255, 0, 31, 124),
                              const Color.fromARGB(255, 126, 26, 209),
                              _glowAnimation.value)!;
                          color2 = Color.lerp(
                              const Color.fromARGB(255, 126, 26, 209),
                              const Color.fromARGB(255, 0, 31, 124),
                              _glowAnimation.value)!;
                        }

                        return Container(
                          width: 90, // Give a fixed width to the container
                          height: 24, // Give a fixed height
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [color1, color2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _isHardening ? null : _hardenRequirements,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(120, 48), // Match the container size
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors
                            .transparent, // Keep transparent when disabled
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isHardening
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 238, 255, 108),
                                  Color.fromARGB(255, 255, 240, 78)
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                '✨',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                      label: Text(
                        _isHardening ? 'Refining…' : 'Refine',
                        style: TextStyle(
                          color: _isHardening
                              ? Colors.white
                              : const Color.fromARGB(255, 243, 242, 241),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
