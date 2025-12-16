import 'package:excel/excel.dart';
import 'package:geneweb/analysis/distribution.dart';

/// Responsible for exporting the [distributions]
class DistributionsExport {
  final List<Distribution> distributions;

  DistributionsExport(this.distributions);

  /// Exports the distributions to Excel and saves it to user
  Future<List<int>?> toExcelAndSave(String fileName, {Function(double progress)? progressCallback}) async {
    final excel = await toExcel(fileName, progressCallback: progressCallback);
    return excel.save(fileName: fileName);
  }

  /// Exports the distributions to Excel
  Future<Excel> toExcel(String fileName, {Function(double progress)? progressCallback}) async {
    assert(distributions.isNotEmpty);
    var excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;
    final headerCellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('FFDDFFDD'), bold: true);
    final dataPoints = distributions.map((distribution) => distribution.dataPoints!).toList();
    final first = dataPoints.first;

    // Motifs sheet
    Sheet motifSheet = excel['motifs'];
    // header row
    motifSheet.appendRow([
      TextCellValue('Interval'),
      TextCellValue('Min'),
      ...distributions.map((distribution) => TextCellValue(distribution.name)),
      TextCellValue(''),
      ...distributions.map((distribution) => TextCellValue('${distribution.name} [%]')),
    ]);
    // data rows
    for (var i = 0; i < first.length; i++) {
      if (i % 1000 == 0) {
        progressCallback?.call(i / first.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final dataPoint = first[i];
      motifSheet.appendRow([
        TextCellValue(dataPoint.label),
        IntCellValue(dataPoint.min),
        ...dataPoints.map((dp) => IntCellValue(dp[i].count)),
        TextCellValue(''),
        ...dataPoints.map((dp) => DoubleCellValue(dp[i].percent)),
      ]);
    }
    for (int i = 0; i < motifSheet.maxColumns; i++) {
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
      TextCellValue('Interval'),
      TextCellValue('Min'),
      ...distributions.map((distribution) => TextCellValue(distribution.name)),
      TextCellValue(''),
      ...distributions.map((distribution) => TextCellValue('${distribution.name} [%]')),
    ]);
    // data rows
    for (var i = 0; i < first.length; i++) {
      if (i % 1000 == 0) {
        progressCallback?.call(0.5 + i / first.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final dataPoint = first[i];
      genesSheet.appendRow([
        TextCellValue(dataPoint.label),
        IntCellValue(dataPoint.min),
        ...dataPoints.map((dp) => IntCellValue(dp[i].genesCount)),
        TextCellValue(''),
        ...dataPoints.map((dp) => DoubleCellValue(dp[i].genesPercent)),
      ]);
    }
    for (int i = 0; i < genesSheet.maxColumns; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerCellStyle;
    }
    for (int i = 0; i < genesSheet.maxRows; i++) {
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle = headerCellStyle;
      genesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).cellStyle = headerCellStyle;
    }

    for (var element in originalSheets) {
      excel.delete(element);
    }
    return excel;
  }
}
