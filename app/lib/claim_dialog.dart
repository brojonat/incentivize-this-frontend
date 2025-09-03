import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bounty.dart';
import 'content_id_parser.dart';
import 'notification_service.dart';

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
  final _scrollController = ScrollController();
  final _contentIdFocusNode = FocusNode();
  final _walletAddressFocusNode = FocusNode();
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
    _contentIdFocusNode.addListener(_scrollToFocusedField);
    _walletAddressFocusNode.addListener(_scrollToFocusedField);
  }

  @override
  void dispose() {
    _contentIdController.removeListener(_parseContentIdInput);
    _contentIdController.dispose();
    _walletAddressController.dispose();
    _scrollController.dispose();
    _contentIdFocusNode.removeListener(_scrollToFocusedField);
    _contentIdFocusNode.dispose();
    _walletAddressFocusNode.removeListener(_scrollToFocusedField);
    _walletAddressFocusNode.dispose();
    super.dispose();
  }

  void _scrollToFocusedField() {
    // This is a more robust way to scroll to the focused field.
    // It waits for the frame to be rendered *after* the focus change,
    // and then uses Scrollable.ensureVisible to make sure the field is in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      FocusNode? focusedNode;
      if (_contentIdFocusNode.hasFocus) {
        focusedNode = _contentIdFocusNode;
      } else if (_walletAddressFocusNode.hasFocus) {
        focusedNode = _walletAddressFocusNode;
      }

      if (focusedNode != null && focusedNode.context != null) {
        Scrollable.ensureVisible(
          focusedNode.context!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.1, // Aligns the field near the top of the visible area
        );
      }
    });
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

      // If it's a URL but didn't parse, we show an error.
      // Otherwise, we accept it as a raw ID.
      final isUrl = rawInput.startsWith('http') || rawInput.startsWith('www.');

      // For Bluesky, the "parsed" value is the URL itself, so didParse is false.
      // We must treat this as a valid case.
      final isBlueskyAndValid =
          widget.bounty.platformKind.toUpperCase() == 'BLUESKY' && isUrl;

      setState(() {
        if (isUrl && !didParse && !isBlueskyAndValid) {
          _parsedContentId = null;
          _parsingError = "The provided URL is not valid for this platform.";
        } else {
          _parsedContentId = didParse ? parsed : null;
          _parsingError = null;
        }
      });
    } catch (e) {
      setState(() {
        _parsedContentId = null;
        _parsingError = "Invalid format or URL";
      });
    }
  }

  void _submitClaim() {
    _parseContentIdInput(); // This will set _parsingError if needed

    // For Bluesky, we bypass the parsing check because the URL is the ID.
    final isBlueskyAndValid =
        widget.bounty.platformKind.toUpperCase() == 'BLUESKY' &&
            (_contentIdController.text.trim().startsWith('http') ||
                _contentIdController.text.trim().startsWith('www.'));

    // Check for validation errors from both fields and parsing
    setState(() {
      _contentIdError = _contentIdController.text.trim().isEmpty
          ? 'Content ID is required'
          : null;

      _walletAddressError = _walletAddressController.text.trim().isEmpty
          ? 'Wallet address is required'
          : null;
    });

    // Stop if there are any errors
    if (_contentIdError != null ||
        _walletAddressError != null ||
        (_parsingError != null && !isBlueskyAndValid)) {
      return;
    }

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: 500,
        ),
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SelectionArea(
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
                    Text(
                      'Content ID or URL',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentIdController,
                      focusNode: _contentIdFocusNode,
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
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.error, width: 2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      style: theme.textTheme.bodyLarge,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
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
                      focusNode: _walletAddressFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter your wallet address',
                        errorText: _walletAddressError,
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: theme.colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.error, width: 2),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      style: theme.textTheme.bodyLarge,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    _buildWalletHelpSection(theme),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
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
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHelpSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
        NotificationService.showError('Could not open the link.');
      }
    }
  }
}
