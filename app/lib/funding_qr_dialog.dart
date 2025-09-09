import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_service.dart';

// Reusable QR content widget that can be used standalone or embedded
class FundingQrContent extends StatefulWidget {
  final String bountyId;
  final double totalCharged;
  final DateTime paymentTimeoutExpiresAt;
  final String walletAddress;
  final String usdcMintAddress;
  final bool showActions; // Whether to show the "Open in Wallet" button
  final VoidCallback? onDone;

  const FundingQrContent({
    super.key,
    required this.bountyId,
    required this.totalCharged,
    required this.paymentTimeoutExpiresAt,
    required this.walletAddress,
    required this.usdcMintAddress,
    this.showActions = true,
    this.onDone,
  });

  @override
  State<FundingQrContent> createState() => _FundingQrContentState();
}

class _FundingQrContentState extends State<FundingQrContent> {
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  late final Widget qrCodeWidget;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.paymentTimeoutExpiresAt);

    final formattedAmount = widget.totalCharged.toStringAsFixed(2);
    final uri =
        'solana:${widget.walletAddress}?amount=$formattedAmount&spl-token=${widget.usdcMintAddress}&memo=${Uri.encodeComponent('Bounty ID: ${widget.bountyId}')}';

    qrCodeWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16.0),
      child: QrImageView(
        data: uri,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        embeddedImage: const AssetImage('assets/images/qr-center.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(40, 40),
        ),
      ),
    );
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_timeRemaining == null)
          const Text(
            'Expires in: -',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        else if (_timeRemaining != Duration.zero)
          Text(
            'Expires in: ${_formatDuration(_timeRemaining!)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        else
          const Text(
            'Expired',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        const SizedBox(height: 10),
        qrCodeWidget,
        const SizedBox(height: 20),
        if (widget.showActions) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final formattedAmount = widget.totalCharged.toStringAsFixed(2);
              final uri =
                  'solana:${widget.walletAddress}?amount=$formattedAmount&spl-token=${widget.usdcMintAddress}&memo=${Uri.encodeComponent('Bounty ID: ${widget.bountyId}')}';
              _launchURL(uri);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Wallet'),
          ),
        ],
        if (widget.onDone != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onDone,
            child: const Text('Done'),
          )
        ]
      ],
    );
  }
}

class FundingQrDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Fund Bounty'),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600.0),
        child: Center(
          child: SingleChildScrollView(
            child: FundingQrContent(
              bountyId: bountyId,
              totalCharged: totalCharged,
              paymentTimeoutExpiresAt: paymentTimeoutExpiresAt,
              walletAddress: walletAddress,
              usdcMintAddress: usdcMintAddress,
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
