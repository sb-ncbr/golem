# Analysis Module

The `analysis` module provides the core functionality of the GOLEM application. It lets users search for **motifs** across a collection of genes, then visualizes the positional distribution of matches along the genome.

## Analysis Series (analysis_series.dart)

Represents one complete analysis run (a specific motif searched against a gene list).

- Created via the `AnalysisSeries.run(...)` factory, which:
  1. Iterates over genes and finds all regex matches (forward + reverse complement).
  2. Optionally filters out **overlapping matches** (filtered out by default).
  3. Calculates the positional **distribution** (histogram) of results.

- **Reverse complements**: By default, both strands are searched. This means you'll see results for both the given motif and its reverse complement.

## Distribution (distribution.dart)

Computes and stores the **histogram** of motif positions across all genes.

- Positions are bucketed by `bucketSize` within the `[min, max]` window.
- If an `alignMarker` is set, positions are normalized relative to that marker in each gene (e.g., distance from ATG).
- Tracks both raw match counts and the number of distinct genes per bucket.
- `dataPoints` exposes the result as a list of `DistributionDataPoint` objects, each containing count, percentage, and gene-level stats (for usage in a chart).

## Typical Data Flow

```
User configures AnalysisOptions
        ↓
AnalysisSeries.run() searches genes for Motif matches
        ↓
Each match → AnalysisResult
        ↓
Distribution.run() buckets results into histogram
        ↓
Chart widget renders Distribution.dataPoints
```
