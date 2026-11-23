import 'package:flutter/material.dart';

import '../golem_colors.dart';
import '../jaspar_info_texts.dart';
import '../motif_logic.dart';
import '../nucleotide_colors.dart';
import 'section_card.dart';

/// Colourful preview of the consensus, highlighted with the GOLEM green.
class ConsensusOutput extends StatelessWidget {
  const ConsensusOutput({
    super.key,
    required this.letters,
    required this.trim,
  });

  final List<String> letters;
  final bool trim;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bounds = trim
        ? trimCoreByLetters(letters)
        : (left: 0, right: letters.length - 1);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: golemGreenLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: golemGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Consensus output',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: golemInk,
                  ),
                ),
                const InfoButton(
                  title: infoConsensusOutputTitle,
                  text: infoConsensusOutputText,
                  color: golemInk,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < letters.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        letters[i],
                        style: TextStyle(
                          fontSize: nucleotideFontSize(letters[i]),
                          fontWeight: FontWeight.w900,
                          color: (i >= bounds.left && i <= bounds.right)
                              ? iupacColor(letters[i])
                              : iupacColor(letters[i]).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
