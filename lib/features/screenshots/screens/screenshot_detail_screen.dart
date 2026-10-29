import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/screenshot_item.dart';
import '../providers/screenshot_provider.dart';
import '../../../core/design/tokens.dart';
import '../../../core/components/sb_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_extensions.dart';
import '../../../core/utils/file_extensions.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';

/// Single-screenshot detail with OCR text, formatted metadata and
/// share/delete actions wired through the screenshot providers.
class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final String screenshotId;
  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  bool _textExpanded = false;

  int get _id => int.tryParse(widget.screenshotId) ?? 0;

  Future<void> _share(ScreenshotItem screenshot) async {
    try {
      await Share.shareXFiles([
        XFile(screenshot.filePath),
      ], text: screenshot.extractedText ?? '');
    } catch (error, stack) {
      // The file can leave the gallery between the scan and the tap, and the
      // platform sheet fails on its own; both used to escape as an unhandled
      // async error with the user seeing nothing happen.
      debugPrint('[ScreenshotDetail] Share failed: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share this screenshot.')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Screenshot'),
        content: const Text('Are you sure you want to delete this screenshot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirmDelete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // Awaited (the old fire-and-forget `ref.read(...)` swallowed errors):
      // the provider deletes the row + linked expense and invalidates the
      // list/home providers itself.
      await ref.read(deleteScreenshotProvider(_id).future);
      if (!mounted) return;
      context.pop();
    } catch (error, stack) {
      // Log the technical detail (repo-wide debugPrint pattern); show the user
      // a short, actionable message instead of an exception dump.
      debugPrint('[ScreenshotDetail] Delete failed: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this screenshot.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenshotAsync = ref.watch(screenshotDetailProvider(_id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () {
              // Reading the AsyncValue instead of `.future` means a failed
              // detail query cannot throw out of this callback (nothing here
              // is awaited, so no use of a disposed context either); the
              // error branch already renders the retry.
              final screenshot = ref
                  .read(screenshotDetailProvider(_id))
                  .valueOrNull;
              if (screenshot == null) return;
              _share(screenshot);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: screenshotAsync.when(
        loading: () => const LoadingWidget(message: 'Loading details...'),
        error: (error, stack) {
          // Technical detail stays in the logs (repo-wide debugPrint pattern);
          // the user sees a short, actionable sentence instead of a dump.
          debugPrint(
            '[ScreenshotDetail] Could not load details: $error\n$stack',
          );
          return AppErrorWidget(
            title: 'Could not load details',
            message: "We couldn't load these details. Please try again.",
            onRetry: () => ref.invalidate(screenshotDetailProvider(_id)),
          );
        },
        data: (screenshot) {
          if (screenshot == null) {
            return EmptyStateWidget(
              icon: Icons.image_not_supported_outlined,
              title: 'Screenshot not found',
              subtitle: 'It may have been deleted from the library.',
              actionLabel: 'Go back',
              onAction: () => context.pop(),
            );
          }
          return _DetailBody(
            screenshot: screenshot,
            textExpanded: _textExpanded,
            onToggleText: () => setState(() => _textExpanded = !_textExpanded),
            onOpenViewer: () => context.push('/viewer/${widget.screenshotId}'),
            onShare: () => _share(screenshot),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  /// Longest edge (physical px) the preview is decoded at. The slot is
  /// ~400x300dp, so a native 1440x3040 capture costs ~4x the pixels it can
  /// ever show; the fullscreen viewer still decodes at full resolution.
  static const int _previewDecodeWidth = 1080;

  final ScreenshotItem screenshot;
  final bool textExpanded;
  final VoidCallback onToggleText;
  final VoidCallback onOpenViewer;
  final Future<void> Function() onShare;

  const _DetailBody({
    required this.screenshot,
    required this.textExpanded,
    required this.onToggleText,
    required this.onOpenViewer,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = screenshot.extractedText ?? '';
    final hasText = text.trim().isNotEmpty;
    final isLongText = hasText && text.length > 160;
    final catColor = _categoryColor(screenshot.categoryDisplay);
    final sizeLabel = screenshot.fileSize != null
        ? screenshot.fileSize!.toReadableFileSize()
        : 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SBSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screenshot preview
          GestureDetector(
            onTap: onOpenViewer,
            child: SbCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SBRadius.xl),
                child: Image(
                  image: ResizeImage(
                    FileImage(File(screenshot.filePath)),
                    width: _previewDecodeWidth,
                  ),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: SBSpacing.xxl),

          // Info section — formatted date/size from the shared utils.
          SbCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.label_rounded,
                  label: 'Category',
                  value: screenshot.categoryDisplay,
                  valueColor: catColor,
                ),
                const Divider(height: SBSpacing.xxl),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Taken',
                  value: screenshot.createdAt.toRelativeString(),
                ),
                const Divider(height: SBSpacing.xxl),
                _InfoRow(
                  icon: Icons.sd_card_outlined,
                  label: 'File size',
                  value: sizeLabel,
                ),
                if (screenshot.isExpense) ...[
                  const Divider(height: SBSpacing.xxl),
                  _InfoRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Expense',
                    value: 'Contains expense data',
                    valueColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SBSpacing.xxl),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenViewer,
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    size: SBSizes.iconMd,
                  ),
                  label: const Text('Open Fullscreen'),
                ),
              ),
              const SizedBox(width: SBSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: SBSizes.iconMd),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: SBSpacing.xxl),

          // Extracted text: collapsed preview, expandable scrollable body.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Extracted Text',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isLongText)
                TextButton(
                  key: const Key('extractedTextToggle'),
                  onPressed: onToggleText,
                  child: Text(textExpanded ? 'Show less' : 'Show more'),
                ),
            ],
          ),
          const SizedBox(height: SBSpacing.md),
          SbCard(
            child: SizedBox(
              width: double.infinity,
              child: hasText
                  ? textExpanded
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: SingleChildScrollView(
                              key: const Key('extractedTextScroller'),
                              child: SelectableText(
                                text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                          )
                  : Text(
                      'No text extracted yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: SBSpacing.xxxl),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SBSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(SBRadius.sm),
          ),
          child: Icon(
            icon,
            size: SBSizes.iconMd,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: SBSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: SBSpacing.xxs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _categoryColor(String? category) {
  switch (category) {
    case 'Payments':
      return AppColors.categoryPayments;
    case 'UPI Receipts':
      return AppColors.categoryUpi;
    case 'Shopping':
      return AppColors.categoryShopping;
    case 'Travel Tickets':
      return AppColors.categoryTravel;
    case 'Bills':
      return AppColors.categoryBills;
    case 'Documents':
      return AppColors.categoryDocuments;
    case 'OTP Screenshots':
      return AppColors.categoryOtp;
    case 'Addresses':
      return AppColors.categoryAddress;
    case 'Notes':
      return AppColors.categoryNotes;
    case 'Social Media':
      return AppColors.categorySocial;
    default:
      return AppColors.categoryOther;
  }
}
