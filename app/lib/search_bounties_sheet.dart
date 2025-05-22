import 'package:flutter/material.dart';

class SearchBountiesSheet extends StatefulWidget {
  final Function(String query) onSearchSubmitted;

  const SearchBountiesSheet({
    super.key,
    required this.onSearchSubmitted,
  });

  @override
  State<SearchBountiesSheet> createState() => _SearchBountiesSheetState();
}

class _SearchBountiesSheetState extends State<SearchBountiesSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    // No need to check if empty here, HomeScreen will handle empty query as "clear search"
    widget.onSearchSubmitted(query);
    Navigator.of(context).pop(); // Close the sheet after submitting
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Bounties',
                style: theme.textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter search query...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submitSearch,
                tooltip: 'Search',
                color: theme.colorScheme.primary,
              ),
            ),
            onFieldSubmitted: (_) => _submitSearch(),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 20), // Add some padding at the bottom
        ],
      ),
    );
  }
}
