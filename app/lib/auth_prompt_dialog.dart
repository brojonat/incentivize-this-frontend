import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'storage_service.dart';
import 'app_config_service.dart';
import 'notification_service.dart';

class AuthPromptDialog extends StatefulWidget {
  // Callback function to indicate successful token saving
  final VoidCallback onTokenSaved;

  const AuthPromptDialog({super.key, required this.onTokenSaved});

  @override
  State<AuthPromptDialog> createState() => _AuthPromptDialogState();
}

class _AuthPromptDialogState extends State<AuthPromptDialog> {
  final _jwtController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _jwtController.dispose();
    super.dispose();
  }

  Future<void> _submitJwt() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final jwt = _jwtController.text.trim();

      try {
        final success = await storageService.saveAuthToken(jwt);
        if (success) {
          if (mounted) {
            // Pop the dialog and notify the caller
            Navigator.of(context).pop();
            widget.onTokenSaved(); // Call the callback
          }
        } else {
          throw Exception('Failed to save token.');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error: Could not save token. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _launchCheckoutLink() async {
    final supportUrlString =
        Provider.of<AppConfigService>(context, listen: false)
            .gumroadCheckoutUrl;
    if (supportUrlString.isEmpty) {
      if (mounted) {
        NotificationService.showError('Checkout URL is not configured.');
      }
      return;
    }

    final url = Uri.parse(supportUrlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError('Could not open link: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8, // Limit height to 80% of screen
          maxWidth: 400,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.lock_open, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Authentication Required',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Simplified instructions
                  Text(
                    'Enter your access token to submit a claim.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Compact link to get token
                  GestureDetector(
                    onTap: _launchCheckoutLink,
                    child: Text(
                      'Need a token? Get one here →',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Token input field
                  TextFormField(
                    controller: _jwtController,
                    decoration: InputDecoration(
                      labelText: 'Access Token',
                      hintText: 'Paste your token here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      isDense: true,
                    ),
                    obscureText: true,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitJwt(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Token cannot be empty';
                      }
                      if (value.trim().split('.').length != 3) {
                        return 'Invalid token format';
                      }
                      return null;
                    },
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitJwt,
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
