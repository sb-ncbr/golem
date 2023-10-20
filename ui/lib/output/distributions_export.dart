import 'package:excel/excel.dart';
import 'package:golem_ui/analysis/distribution.dart';

/// Responsible for exporting the [distributions]
class DistributionsExport {
  final List<Distribution> distributions;

  DistributionsExport(this.distributions);

  /// Exports the distributions to Excel
  Future<List<int>?> toExcel(String fileName, Function(double progress) progressCallback) async {
    assert(distributions.isNotEmpty);
    var excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;
    final headerCellStyle = CellStyle(backgroundColorHex: 'FFDDFFDD', bold: true);
    final dataPoints = distributions.map((distribution) => distribution.dataPoints!).toList();
    final first = dataPoints.first;

    // Motifs sheet
    Sheet motifSheet = excel['motifs'];
    // header row
    motifSheet.appendRow([
      'Interval',
      'Min',
      ...distributions.map((distribution) => distribution.name),
      '',
      ...distributions.map((distribution) => '${distribution.name} [%]'),
    ]);
    // data rows
    for (var i = 0; i < first.length; i++) {
      if (i % 1000 == 0) {
        progressCallback(i / first.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final dataPoint = first[i];
      motifSheet.appendRow([
        dataPoint.label,
        dataPoint.min,
        ...dataPoints.map((dp) => dp[i].count),
        '',
        ...dataPoints.map((dp) => dp[i].percent),
      ]);
    }
    for (int i = 0; i < motifSheet.maxCols; i++) {
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < motifSheet.maxRows; i++) {
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      motifSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    // Genes sheet
    Sheet genesSheet = excel['genes'];
    // header row
    genesSheet.appendRow([
      'Interval',
      'Min',
      ...distributions.map((distribution) => distribution.name),
      '',
      ...distributions.map((distribution) => '${distribution.name} [%]'),
    ]);
    // data rows
    for (var i = 0; i < first.length; i++) {
      if (i % 1000 == 0) {
        progressCallback(0.5 + i / first.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final dataPoint = first[i];
      genesSheet.appendRow([
        dataPoint.label,
        dataPoint.min,
        ...dataPoints.map((dp) => dp[i].genesCount),
        '',
        ...dataPoints.map((dp) => dp[i].genesPercent),
      ]);
    }
    for (int i = 0; i < genesSheet.maxCols; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < genesSheet.maxRows; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    for (var element in originalSheets) {
      excel.delete(element);
    }
    return excel.save(fileName: fileName);
  }
}
