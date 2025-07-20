import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_service.dart';

class FundingQrDialog extends StatefulWidget {
  final String bountyId;
  final double totalCharged;
  final DateTime paymentTimeoutExpiresAt;
  final String walletAddress;
  final String usdcMintAddress;

  const FundingQrDialog({
    super.key,
    required this.bountyId,
    required this.totalCharged,
    required this.paymentTimeoutExpiresAt,
    required this.walletAddress,
    required this.usdcMintAddress,
  });

  @override
  State<FundingQrDialog> createState() => _FundingQrDialogState();
}

class _FundingQrDialogState extends State<FundingQrDialog> {
  Timer? _countdownTimer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.paymentTimeoutExpiresAt);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        NotificationService.showError('Could not launch link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri =
        'solana:${widget.walletAddress}?amount=${widget.totalCharged}&spl-token=${widget.usdcMintAddress}&message=${Uri.encodeComponent('Bounty ID: ${widget.bountyId}')}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Fund Bounty'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600.0),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_timeRemaining == null)
                  const Text(
                    'Expires in: -',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                else if (_timeRemaining != Duration.zero)
                  Text(
                    'Expires in: ${_formatDuration(_timeRemaining!)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    'Expired',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
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
                const Text('Scan with your wallet to fund the bounty.')
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
