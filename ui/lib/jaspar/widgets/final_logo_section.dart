import 'package:flutter/material.dart';

import '../jaspar_info_texts.dart';
import 'section_card.dart';

class FinalLogoSection extends StatelessWidget {
  const FinalLogoSection({
    super.key,
    required this.definition,
    required this.onUse,
    this.fillHeight = false,
  });

  /// The motif that will be sent to the motif editor
  final String definition;

  /// Null disables the button (nothing to use)
  final VoidCallback? onUse;

  /// True: the section stretches to the height it is given and the button
  /// takes all the free space (wide layout, bottom aligned with section 2).
  final bool fillHeight;

  Widget _useButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onUse,
      child: Text(
        definition.isEmpty ? 'Use this logo' : 'Use "$definition"',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      title: '4. Final logo',
      infoTitle: infoFinalLogoTitle,
      infoText: infoFinalLogoText,
      expand: fillHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (definition.isEmpty)
            Text(
              'No logo can be generated: every position is N.',
              style: textTheme.bodyLarge,
            )
          else
            SelectableText.rich(
              TextSpan(
                style: textTheme.bodyLarge,
                children: [
                  const TextSpan(text: 'Final logo: '),
                  TextSpan(
                    text: definition,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      fontSize: 24,
                    ),
                  ),
                  const TextSpan(text: ' that will be used'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (fillHeight)
            Expanded(child: _useButton())
          else
            SizedBox(height: 72, child: _useButton()),
        ],
      ),
    );
  }
}
