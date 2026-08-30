// consensus_output.dart

import 'package:flutter/material.dart';

import '../motif_logic.dart';
import '../nucleotide_colors.dart';

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
    final bounds = trim
        ? trimCoreByLetters(letters)
        : (left: 0, right: letters.length - 1);
    final trimmedText = letters.isNotEmpty
        ? letters.sublist(bounds.left, bounds.right + 1).join()
        : '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Consensus output',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 20),

            // Řádek zvětšených barevných písmen (využití prostoru)
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
                              : iupacColor(letters[i]).withOpacity(0.35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Výsledná sekvence
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                trimmedText,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.0,
                  fontSize: 26, // Zvětšený text výsledné sekvence
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '"Use this motif" always sends the trimmed core shown above.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
