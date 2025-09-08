import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/utilities/color.dart';

/// Parses a CSV file with the following format:
/// ```
/// geneId, stage1, stage2, stage3, ...
/// (ignored), #RRGGBB, #RRGGBB, #RRGGBB, ...
/// gene1, 0.1, 14.5, 0.04, ...
/// gene2, 2.1, , 3.14, ...
/// gene4, 26.2, 19.79, 99.66...
/// ```
///
/// Colors row is optional, but must be in row 2 if present.
class TPMData {
  static const _converter =
      CsvToListConverter(csvSettingsDetector: FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']));

  final Map<String, Map<String, double?>> stages;
  final Map<String, Color> colors;

  TPMData(this.stages, this.colors);

  factory TPMData.fromCsv(String csv) {
    final table = _converter.convert(csv);
    if (table.length < 2) {
      throw ArgumentError('CSV must have at least 2 rows');
    }
    final stageNames = table[0].map((e) => '$e'.trim()).toList();
    if (stageNames.length <= 1) {
      throw ArgumentError('CSV must have at least 2 columns');
    }

    final Map<String, Map<String, double?>> stages = {};
    Map<String, Color> colors = {};
    for (int rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final row = table[rowIndex];
      if (rowIndex == 1) {
        final colorRow = ColorRowParser.tryParse(row);
        if (colorRow != null) {
          for (var i = 1; i < row.length; i++) {
            final color = colorRow[i];
            final stage = stageNames[i];
            if (color != null) {
              colors[stage] = color;
            }
          }
        }
        continue;
      }
      final geneId = row[0];
      for (var i = 1; i < row.length; i++) {
        final tpm = double.tryParse('${row[i]}'.trim());
        final stage = stageNames[i];
        if (tpm == null) {
          continue;
        }
        stages[stage] ??= {};
        stages[stage]![geneId] = tpm;
      }
    }
    return TPMData(stages, colors);
  }
}
