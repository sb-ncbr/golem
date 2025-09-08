import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/utilities/color.dart';

/// Parses a CSV file with the following format:
/// ```
/// stage1, stage2, stage3, ...
/// #RRGGBB, #RRGGBB, #RRGGBB, ...
/// gene1, gene1, gene3, ...
/// gene2, gene3, gene4, ...
/// gene4, , , ...
/// ```
///
/// Colors row is optional, but must be in row 2 if present.
class StagesData {
  static const _converter =
      CsvToListConverter(csvSettingsDetector: FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']));

  final Map<String, Set<String>> stages;
  final Map<String, Color> colors;

  StagesData(this.stages, this.colors);

  factory StagesData.fromCsv(String csv) {
    final table = _converter.convert(csv);
    if (table.length < 2) {
      throw ArgumentError('CSV must have at least 2 rows');
    }
    final stageNames = table[0].map((e) => '$e'.trim()).toList();
    if (stageNames.isEmpty) {
      throw ArgumentError('CSV must have at least 1 column');
    }

    final Map<String, Set<String>> stages = {};
    Map<String, Color> colors = {};
    for (int rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final row = table[rowIndex];
      if (rowIndex == 1) {
        final colorRow = ColorRowParser.tryParse(row);
        if (colorRow != null) {
          for (var i = 0; i < row.length; i++) {
            final color = colorRow[i];
            final stage = stageNames[i];
            if (color != null) {
              colors[stage] = color;
            }
          }
        }
        continue;
      }
      for (var i = 0; i < row.length; i++) {
        final gene = '${row[i]}'.trim();
        final stage = stageNames[i];
        if (gene.isEmpty) {
          continue;
        }
        stages[stage] ??= {};
        stages[stage]!.add(gene);
      }
    }
    return StagesData(stages, colors);
  }
}
