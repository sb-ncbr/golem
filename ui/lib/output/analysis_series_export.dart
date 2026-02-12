import 'package:excel/excel.dart';
import 'package:geneweb/analysis/analysis_series.dart';

/// Responsible for exporting the [series]
class AnalysisSeriesExport {
  final AnalysisSeries series;

  final cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('FFDDFFDD'), bold: true);

  AnalysisSeriesExport(this.series);

  /// Exports the series to Excel and saves it to user
  Future<List<int>?> toExcelAndSave(String fileName, {Function(double progress)? progressCallback}) async {
    final excel = await toExcel(fileName, progressCallback: progressCallback);
    return excel.save(fileName: fileName);
  }

    /// Exports the series to Excel
    Future<Excel> toExcel(String fileName, { Function(double progress)? progressCallback }) async {
    assert(series.geneList.genes.isNotEmpty);
    final excel = Excel.createExcel();
    final originalSheets = excel.sheets.keys;

    await Future.wait([
      _addSelectedGenesSheet(excel, progressCallback),
      _addDistributionSheet(excel, progressCallback),
      _addPositionSheet(excel, progressCallback)
    ]);

    for (var element in originalSheets) {
      excel.delete(element);
    }
    
    return excel;
  }

  Future<void> _addSelectedGenesSheet(
      Excel excel, Function(double)? progressCallback) async {
    Sheet genesSheet = excel['selected_genes'];
    final stages = series.geneList.genes.first.transcriptionRates.keys.toList();
    // header row
    genesSheet.appendRow([
      TextCellValue('Gene Id'),
      for (final stage in stages) TextCellValue(stage),
    ]);
    // data rows
    for (var i = 0; i < series.geneList.genes.length; i++) {
      if (i % 1000 == 0) {
        progressCallback?.call(i / series.geneList.genes.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final gene = series.geneList.genes[i];
      genesSheet.appendRow([
        TextCellValue(gene.geneId),
//        series.result?.where((g) => g.gene.geneId == gene.geneId).length,
        for (final stage in stages)
          gene.transcriptionRates[stage] == null
              ? TextCellValue('')
              : DoubleCellValue(gene.transcriptionRates[stage]!.toDouble()),
      ]);
    }
    
    _styleSheetHeader(genesSheet);
    await _styleSheetColumn(genesSheet, 0, progressCallback);
  }

  Future<void> _addDistributionSheet(
      Excel excel, Function(double)? progressCallback) async {
    Sheet distributionSheet = excel['distribution'];
    // header row
    distributionSheet.appendRow(
        [TextCellValue('Interval'), TextCellValue('Genes with motif')]);
    // data rows
    int i = 0;
    final datapoints = series.distribution!.dataPoints!;
    for (final dataPoint in datapoints) {
      if (i++ % 100 == 0) {
        progressCallback?.call(0.6 + i / datapoints.length * 0.3);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      distributionSheet.appendRow([
        TextCellValue(dataPoint.label),
        for (final gene in dataPoint.genes) TextCellValue(gene),
      ]);
    }

    _styleSheetHeader(distributionSheet);
    await _styleSheetColumn(distributionSheet, 0, progressCallback);
  } 
  
  Future<void> _addPositionSheet(
      Excel excel, Function(double)? progressCallback) async {
    Sheet positionSheet = excel['position'];
    // header row
    positionSheet.appendRow([
      TextCellValue('Gene Id'),
      TextCellValue('Number of matches'),
      TextCellValue('Positions')
    ]);

    // data rows
    final resultsMap = series.resultsMap;
    final alignMarker = series.distribution?.alignMarker ?? '';
    for (var i = 0; i < series.geneList.genes.length; i++) {
      if (i % 1000 == 0) {
        progressCallback?.call(i / series.geneList.genes.length * 0.5);
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final gene = series.geneList.genes[i];
      final geneResults = resultsMap[gene.geneId];
      final positions = geneResults
              ?.map((result) => (
                    start: result.position - (gene.markers[alignMarker] ?? 0),
                    length: result.matchedSequence.length
                  ))
              .map((span) => '(${span.start}, ${span.start + span.length})')
              .join(',') ?? '';

      positionSheet.appendRow([
        TextCellValue(gene.geneId),
        IntCellValue(geneResults?.length ?? 0),
        TextCellValue(positions)
      ]);
    }

    _styleSheetHeader(positionSheet);
    await Future.wait([
      _styleSheetColumn(positionSheet, 0, progressCallback),
      _styleSheetColumn(positionSheet, 1, progressCallback)
    ]);
  }

  void _styleSheetHeader(Sheet sheet) {    
    for (int i = 0; i < sheet.maxColumns; i++) {
      _styleSheetCell(sheet, cellStyle, i, 0);
    }
  }

  Future<void> _styleSheetColumn(Sheet sheet, int columnIndex, Function(double)? progressCallback) async {
    for (int i = 0; i< sheet.maxRows; i++) {
      if (i % 1000 == 0) {
        progressCallback?.call(0.5 + i / sheet.maxRows * 0.1);
        await Future.delayed(const Duration(milliseconds: 20));
      }
      _styleSheetCell(sheet, cellStyle, columnIndex, i);
    }
  }
  
  void _styleSheetCell(
      Sheet sheet, CellStyle cellStyle, int columnIndex, int rowIndex) {
    sheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: columnIndex, rowIndex: rowIndex))
        .cellStyle = cellStyle;
  }

}
