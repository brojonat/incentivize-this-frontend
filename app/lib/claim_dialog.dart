import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bounty.dart';
import 'content_id_parser.dart';

class ClaimDialog extends StatefulWidget {
  final Bounty bounty;
  final String? initialWalletAddress;
  final Function(String contentId, String walletAddress) onSubmit;

  const ClaimDialog({
    super.key,
    required this.bounty,
    this.initialWalletAddress,
    required this.onSubmit,
  });

  @override
  State<ClaimDialog> createState() => _ClaimDialogState();
}

class _ClaimDialogState extends State<ClaimDialog> {
  late final TextEditingController _contentIdController;
  late final TextEditingController _walletAddressController;
  bool _isSubmitting = false;
  String? _contentIdError;
  String? _walletAddressError;
  String? _parsedContentId;
  String? _parsingError;

  @override
  void initState() {
    super.initState();
    _contentIdController = TextEditingController();
    _walletAddressController = TextEditingController(
      text: widget.initialWalletAddress ?? '',
    );
    _contentIdController.addListener(_parseContentIdInput);
  }

  @override
  void dispose() {
    _contentIdController.removeListener(_parseContentIdInput);
    _contentIdController.dispose();
    _walletAddressController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _contentIdError = _contentIdController.text.trim().isEmpty
          ? 'Content ID is required'
          : null;

      _walletAddressError = _walletAddressController.text.trim().isEmpty
          ? 'Wallet address is required'
          : null;

      if (_contentIdError == null && _walletAddressError == null) {
        _submitClaim();
      }
    });
  }

  void _parseContentIdInput() {
    final rawInput = _contentIdController.text.trim();
    if (rawInput.isEmpty) {
      setState(() {
        _parsedContentId = null;
        _parsingError = null;
      });
      return;
    }

    try {
      final parsed = ContentIdParser.parse(
        rawInput,
        widget.bounty.platformKind,
      );
      final didParse = parsed != rawInput;
      setState(() {
        _parsedContentId = didParse ? parsed : null;
        _parsingError = null;
      });
    } catch (e) {
      setState(() {
        _parsedContentId = null;
        _parsingError = "Invalid format or URL";
      });
    }
  }

  void _submitClaim() {
    _parseContentIdInput();

    setState(() {
      _isSubmitting = true;
    });

    final String finalContentId =
        _parsedContentId ?? _contentIdController.text.trim();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onSubmit(
          finalContentId,
          _walletAddressController.text.trim(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context, theme),
    );
  }

  Widget _buildDialogContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Claim Bounty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWalletHelpSection(theme),
            const SizedBox(height: 24),
            Text(
              'Content ID or URL',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentIdController,
              decoration: InputDecoration(
                labelText: 'Content ID or URL',
                hintText: 'Enter the content ID or URL',
                errorText: _contentIdError ?? _parsingError,
                prefixIcon: Icon(
                  Icons.insert_drive_file_outlined,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: theme.textTheme.bodyLarge,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
            ),
            if (_parsedContentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  'Using ID: $_parsedContentId',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Wallet Address',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _walletAddressController,
              decoration: InputDecoration(
                hintText: 'Enter your wallet address',
                errorText: _walletAddressError,
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: theme.textTheme.bodyLarge,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _validate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Claim',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHelpSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                "Don't have a wallet?",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              children: [
                const TextSpan(
                    text: "No problem! It's super easy to make one with "),
                _buildLinkSpan(theme, 'MetaMask', 'https://metamask.io/'),
                const TextSpan(text: ' or '),
                _buildLinkSpan(theme, 'Phantom', 'https://phantom.app/'),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildLinkSpan(ThemeData theme, String text, String url) {
    return TextSpan(
      text: text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error, e.g., show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }
}
