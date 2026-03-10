# Output Module

The `output` module handles exporting analysis results to Excel (`.xlsx`) files for download.

## Key Files & Classes

### AnalysisSeriesExport (analysis_series_export.dart)

Takes one `AnalysisSeries` and produces a workbook with three sheets:

| Sheet            | Contents                                                                                |
| ---------------- | --------------------------------------------------------------------------------------- |
| `selected_genes` | All genes in the analysis with their per-stage transcription rates                      |
| `distribution`   | Positional distribution buckets, listing which genes had a motif match in each interval |
| `position`       | Per-gene match count and exact match positions (aligned to the chosen marker)           |

- `toExcel()` builds the workbook in memory; `toExcelAndSave()` additionally triggers a browser download.
- Progress callbacks and `Future.delayed` breaks are used to keep the UI responsive during larger exports.
- Header row and first column(s) are highlighted with a green cell style (`FFDDFFDD`).

### DistributionsExport (distributions_export.dart)

Exports multiple series side-by-side into a single Excel file for comparison.

Takes a list of `Distribution` objects and produces a workbook with two sheets:

| Sheet    | Contents                                                               |
| -------- | ---------------------------------------------------------------------- |
| `motifs` | Per-interval motif match counts and percentages, one column per series |
| `genes`  | Per-interval gene counts and percentages, one column per series        |

- Both sheets share the same interval rows (from the first distribution), with each series occupying its own column.
- Raw counts and percentage columns are separated by an empty column.
