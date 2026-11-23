import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.infoText,
    required this.child,
    this.infoTitle,
    this.actions = const [],
    this.expand = false,
  });

  final String title;
  final Widget child;

  /// Shown in the dialog behind the "i" button next to the title.
  final String infoText;
  final String? infoTitle;

  final List<Widget> actions;

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Header: title + "i" take ALL the free width (Expanded), so the
            // actions sit flush in the right corner. minHeight keeps the
            // cards aligned, but a long title may wrap instead of overflowing.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        InfoButton(title: infoTitle ?? title, text: infoText),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (expand) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

/// Small "i" icon that opens an explanation dialog.
class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
    required this.title,
    required this.text,
    this.color,
  });

  final String title;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More information',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(Icons.info_outline, size: 20, color: color),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(child: SelectableText(text)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
