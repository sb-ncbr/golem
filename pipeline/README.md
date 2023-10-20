# GOLEM data pipeline

This pipeline processes data for the GOLEM UI.
A source FASTA, GFF3 and TPM files for an organism are processed into a single FASTA compatible file, 
that contains the genes and with the respective TPM for every development stage.

## Installation

Installation assumes that you have cloned the repository from GitHub and are in the `pipeline` directory.

Start by installing Dart and the Dart package manager `pub` as described [here](https://dart.dev/get-dart).

Install the dependencies:

```bash
dart pub get
```

## Configuration

You will need to download the source FASTA, GFF3 and TPM files for the organism you want to process.

Put each organism into its own subdirectory inside the `source_data` directory. The resulting structure should look like this:

```
source_data
 - Arabidopsis_thaliana
   - Arabidopsis_thaliana.fasta
   - Arabidopsis_thaliana.gff3
   - TPM
     - egg_cell.csv
     - seedlings.csv
     - tapetum.csv
     - ...
```

The pipeline scans for .fasta, .fa, .gff3 and .gff files and additionally for all files in the TPM directory.
Only one FASTA and GFF3 file is allowed per organism.

Organism name is defined by the name of the directory. If the name matches one of the 
pre-configured organisms in the `lib/organisms` directory, some additional tweaks are applied so that the data is matched correctly for each organism,
as the source data format is not always consistent across organisms. If you want to process a new organism, this is where you should start.

## Usage

To run the pipeline for an organism, use the following command: (this assumes you have `Arabidopsis_thaliana` in the `source_data` directory)

```bash
dart run bin/pipeline.dart Arabidopsis_thaliana --with-tss
```

the optional `--with-tss` will attempts to find the TSS position for each gene and add it to the output file.

See also `run.sh` script for inspiration on how to run the pipeline for multiple organisms (as used in GOLEM).