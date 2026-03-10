# Genes Module

The `genes` module is responsible for loading, representing, and filtering gene sequence data. It also contains the main application state model.

## Gene (gene.dart)

Represents a **single gene**.

- Holds the raw nucleotide sequence (`data`), a gene ID (e.g. `ATG0001.1`), positional markers (e.g. ATG, TSS), and per-stage transcription rates.
- Two supported FASTA formats:
  - `Gene.fromFastaWithComments` - parses a FASTA entry where metadata (markers, transcription rates) is embedded in comment lines prefixed with - the output of the pipeline.
  - `Gene.fromFasta` - parses a plain FASTA entry and looks up metadata from a separately loaded `OrganismMetadata` object. The goal of this change was to allow loading large FASTA files in the background while user is configuring the analysis.
- `geneCode` strips the splicing variant suffix (e.g. `ATG0001.1` → `ATG0001`).
- `geneSplicingVariant` returns just the variant suffix (e.g. `1`).

## GeneList (gene_list.dart)

A collection of genes for a given organism and stage configuration.

- Holds the list of `Gene` objects, optional stage groupings, per-stage colors, and aggregated transcription rates.
- **Parsing pipeline** (call in sequence):
  1. `parseFastaWithComments()` or `parseFasta()` - parse raw FASTA text into genes. Both are async and yield progress callbacks to avoid blocking the UI.
  2. `takeSingleTranscript()` - optionally deduplicate to one transcript per gene (keeps the lexicographically first).
  3. `GeneList.fromList()` - wraps the result into a `GeneList`.
- `filterByPercentile()` - filters genes for a given stage by transcription rate percentile or fixed count, returning a map of `percentile - GeneList`.
- `stageKeys` - returns stage names in a consistent order, whether stage groupings or transcription rates are the source of truth.

## GeneModel (gene_model.dart)

The **central application state**, implemented as a `ChangeNotifier`. Most UI widgets depend on this model for data and change notifications.

**Note:** It might me worth considering to split into separate state models, as it's currently doing too many things.

Key responsibilities:

- **Auth state** - holds the current `User` and exposes `isSignedIn` / `isAdmin`.
- **Data loading** - orchestrates loading genes from FASTA files (`loadFastaFromString`, `loadFastaFromFile`), stage groupings from CSV (`loadStagesFromString`), and TPM data from CSV (`loadTPMFromString`).
- **Analysis orchestration** - `analyze()` iterates over all selected stages, motifs, and percentiles, dispatches each run to a background isolate via `compute(runAnalysis, ...)`, and tracks progress. Supports cancellation mid-run.
- **Color management** - resolves stage display colors by merging user preferences, organism defaults, and random fallbacks.
- **`matchWhenAll`** - when multiple motifs are selected, optionally restricts analysis to genes that contain all motifs (pre-computed via `_identifyIntersectingGenes`).

`LoadingState` is a simple value object used to communicate loading progress and messages to the UI.

`runAnalysis` is a top-level function (required by Flutter's `compute`) that deserializes parameters and calls `AnalysisSeries.run()` in an isolate. **Note:** for web, this might be useless as isolates are not supported :).

## Data Loading Flow

```
FASTA file
    ↓
GeneList.parseFasta() / parseFastaWithComments()
    ↓
GeneList.takeSingleTranscript()  (if enabled)
    ↓
GeneList.fromList()  →  sourceGenes in GeneModel
    ↓
Optional: loadStagesFromString()
       or: loadTPMFromString()
    ↓
User selects stages + filter → StageSelection
    ↓
GeneModel.analyze()
    ↓
GeneList.filterByPercentile() per stage
    ↓
compute(runAnalysis) in isolate → AnalysisSeries
```
