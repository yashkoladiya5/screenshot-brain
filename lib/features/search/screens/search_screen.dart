import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/search_provider.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_loading.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/components/sb_empty_state.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sb = context.sb;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(SBSpacing.lg, SBSpacing.lg, SBSpacing.lg, SBSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: sb.elevated,
                        borderRadius: BorderRadius.circular(SBRadius.lg),
                        border: Border.all(color: sb.borderLight),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search screenshots...',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg, vertical: SBSpacing.md),
                          prefixIcon: Icon(Icons.search_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                        ),
                        style: theme.textTheme.bodyLarge,
                        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                      ),
                    ),
                  ),
                  const SizedBox(width: SBSpacing.sm),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: query.isEmpty ? _buildSuggestions(theme, sb, suggestions) : _buildResults(theme, sb, resultsAsync, query),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme, ScreenshotBrainThemeExtension sb, List<String> suggestions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggestions', style: theme.textTheme.titleMedium?.copyWith(color: sb.textSecondary)),
          const SizedBox(height: SBSpacing.md),
          Wrap(
            spacing: SBSpacing.sm,
            runSpacing: SBSpacing.sm,
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
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, ScreenshotBrainThemeExtension sb, AsyncValue<List<ScreenshotModel>> resultsAsync, String query) {
    return resultsAsync.when(
      loading: () => const SbLoading(message: 'Searching...'),
      error: (error, _) => Center(
        child: Text('Error: $error', style: theme.textTheme.bodyLarge),
      ),
      data: (results) {
        if (results.isEmpty) {
          return SbEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Results Found',
            subtitle: 'Try a different search term or browse categories',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final screenshot = results[index];
            final textPreview = screenshot.extractedText ?? 'No text extracted';
            final dateStr = DateFormat('dd MMM yyyy').format(screenshot.createdAt);
            final catColor = _categoryColor(screenshot.category);

            return Padding(
              padding: const EdgeInsets.only(bottom: SBSpacing.md),
              child: SbCard(
                padding: EdgeInsets.zero,
                onTap: () => context.push('/screenshots/${screenshot.id}'),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(SBRadius.xl),
                          bottomLeft: Radius.circular(SBRadius.xl),
                        ),
                        child: SizedBox(
                          width: 88,
                          child: Image.file(
                            File(screenshot.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: SBSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: SBSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      borderRadius: BorderRadius.circular(SBRadius.full),
                                    ),
                                  ),
                                  const SizedBox(width: SBSpacing.xs),
                                  Text(
                                    screenshot.category ?? 'Uncategorized',
                                    style: theme.textTheme.labelSmall?.copyWith(color: catColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: SBSpacing.sm),
                              _HighlightedText(
                                text: textPreview,
                                query: query,
                                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                              ),
                              const SizedBox(height: SBSpacing.xs),
                              Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: sb.textTertiary)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: SBSpacing.sm),
                        child: Icon(Icons.chevron_right_rounded, color: sb.textTertiary, size: SBSizes.iconMd),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Payments': return AppColors.categoryPayments;
      case 'UPI Receipts': return AppColors.categoryUpi;
      case 'Shopping': return AppColors.categoryShopping;
      case 'Travel Tickets': return AppColors.categoryTravel;
      case 'Bills': return AppColors.categoryBills;
      case 'Documents': return AppColors.categoryDocuments;
      case 'OTP Screenshots': return AppColors.categoryOtp;
      case 'Addresses': return AppColors.categoryAddress;
      case 'Notes': return AppColors.categoryNotes;
      case 'Social Media': return AppColors.categorySocial;
      default: return AppColors.categoryOther;
    }
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;

  const _HighlightedText({required this.text, required this.query, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (query.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style ?? theme.textTheme.bodySmall,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              color: theme.colorScheme.primary,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
