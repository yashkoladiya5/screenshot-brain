import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search screenshots...',
            border: InputBorder.none,
            filled: false,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        ),
      ),
      body: query.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Suggestions', style: Theme.of(context).textTheme.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: () {
                        _searchController.text = suggestion;
                        ref.read(searchQueryProvider.notifier).state = suggestion;
                      },
                    );
                    }).toList(),
                  ),
                ),
              ],
            )
          : resultsAsync.when(
              loading: () => const LoadingWidget(message: 'Searching...'),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (results) {
                if (results.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Results Found',
                    subtitle: 'Try a different search term',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final screenshot = results[index];
                    final textPreview = screenshot.extractedText ?? 'No text extracted';
                    final dateStr = DateFormat('dd MMM yyyy').format(screenshot.createdAt);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/screenshots/${screenshot.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Image.file(
                                    File(screenshot.filePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      screenshot.category ?? 'Uncategorized',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildHighlightedText(context, textPreview, query),
                                    const SizedBox(height: 4),
                                    Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String query) {
    if (query.isEmpty) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    if (index == -1) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
