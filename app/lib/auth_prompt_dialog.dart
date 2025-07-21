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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_open, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Authentication Required')),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please enter your access token to submit a claim.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Instructions for getting a token
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  children: [
                    const TextSpan(text: 'Need a token? '),
                    TextSpan(
                      text: 'Get a token via Gumroad',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _launchCheckoutLink,
                    ),
                    const TextSpan(text: ' and we\'ll email one to you.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Wrap TextFormField in a SizedBox for fixed width
              Center(
                child: SizedBox(
                  width: 300, // Set a fixed width for the input field
                  child: TextFormField(
                    controller: _jwtController,
                    decoration: InputDecoration(
                      labelText: 'JWT (token from email)',
                      hintText: 'Paste your token here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                    ),
                    obscureText: true,
                    maxLines: 1,
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
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitJwt,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save & Submit'),
        ),
      ],
    );
  }
}
