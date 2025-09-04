import 'package:flutter/material.dart';

/// A full-screen page for editing requirements, primarily for mobile devices.
class EditRequirementsScreen extends StatefulWidget {
  final String initialValue;

  const EditRequirementsScreen({super.key, required this.initialValue});

  @override
  State<EditRequirementsScreen> createState() => _EditRequirementsScreenState();
}

class _EditRequirementsScreenState extends State<EditRequirementsScreen> {
  final _editorKey = GlobalKey<EditRequirementsContentState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Requirements'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_editorKey.currentState?.currentText);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: EditRequirementsContent(
            key: _editorKey,
            initialValue: widget.initialValue,
          ),
        ),
      ),
    );
  }
}

/// The core text editor widget.
class EditRequirementsContent extends StatefulWidget {
  final String initialValue;

  const EditRequirementsContent({super.key, required this.initialValue});

  @override
  State<EditRequirementsContent> createState() =>
      EditRequirementsContentState();
}

class EditRequirementsContentState extends State<EditRequirementsContent> {
  late final TextEditingController _textController;

  String get currentText => _textController.text;

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
    return TextField(
      controller: _textController,
      autofocus: true,
      maxLines: null, // Allows for unlimited lines
      expands: true, // Expands to fill available space
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter your bounty requirements...',
        contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 20),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
