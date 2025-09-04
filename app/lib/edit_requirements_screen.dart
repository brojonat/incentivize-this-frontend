import 'package:flutter/material.dart';

class EditRequirementsScreen extends StatefulWidget {
  final String initialValue;

  const EditRequirementsScreen({super.key, required this.initialValue});

  @override
  State<EditRequirementsScreen> createState() => _EditRequirementsScreenState();
}

class _EditRequirementsScreenState extends State<EditRequirementsScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Requirements'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_textController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: null, // Allows for unlimited lines
          expands: true, // Expands to fill available space
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter your bounty requirements...',
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    );
  }
}
