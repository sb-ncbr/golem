import 'dart:convert';
import 'dart:io';

import 'package:es_compression/zstd.dart';

const String outputDirName = "output";
const String headerSymbol = ">";
const String commentSymbol = ";";
const String markersKey = "MARKERS";
const String transcriptionRatesKey = "TRANSCRIPTION_RATES";

typedef Markers = Map<String, int>;
typedef TranscriptionRates = Map<String, double>;

class OrganismMetadata {
  final Map<String, StageMetadata> stages;
  final Map<String, SequenceMetadata> genes;

  const OrganismMetadata({required this.stages, required this.genes});
}

class StageMetadata {
  final String srr;
  final String url;

  const StageMetadata({required this.srr, required this.url});

  Map<String, dynamic> toJson() => {
    'srr': srr,
    'url': url
  };
}

class SequenceMetadata {
  Markers markers;
  TranscriptionRates transcriptionRates;

  SequenceMetadata({
    required this.markers,
    required this.transcriptionRates,
  });

  Map<String, dynamic> toJson() => {
        'markers': markers,
        'transcriptionRates': transcriptionRates,
      };
}

class ParserArgs {
  final String inPath;
  final String outPath;
  final bool compress;
  final bool skipExtract;

  const ParserArgs({required this.inPath, this.outPath = '.', this.compress = false, this.skipExtract = false}); 
}

ParserArgs _parseArgs(List<String> arguments) {
  String? inPath;
  String outPath = '.';
  bool compress = false;
  bool skipExtract = false;

  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '-i':
      case '--in-path':
        if (i + 1 < arguments.length) {
          inPath = arguments[++i];
        }
        break;
      case '-o':
      case '--out-path':
        if (i + 1 < arguments.length) {
          outPath = arguments[++i];
        }
        break;
      case '-c':
      case '--compress':
        compress = true;
        break;
      case '-s':
      case '--skip-extract':
        skipExtract = true;
        break;
      case '-h':
      case '--help':
        print('''
GOLEM fasta metadata extractor

This script processes FASTA files from the GOLEM pipeline to extract metadata. 
It creates two output files: a JSON file that stores the extracted metadata, 
and a new FASTA file that contains only the sequences, stripped of the original metadata.

Usage:
  dart fasta_metadata_extractor.dart -i <input_file> [-o <output_directory>] [-c] [-s]

Options:
  -i, --in-path       Input FASTA file path (required)
  -o, --out-path      Output directory path (default: current directory)
  -c, --compress      Whether to also compress FASTA and metadata files using gzip (default: false).
  -s, --skip-extract  Whether the extraction should be skipped. Can be used to compress already parsed fasta/json files.
  -h, --help          Show this help message
        ''');
        exit(0);
      default:
        print('Unknown argument "${arguments[i]}", skipping');
    }
  }

  if (inPath == null || inPath.isEmpty) {
    print(
        'Error: Input path is required. Use -i or --in-path to specify the input file.');
    print('Use --help for more information.');
    exit(1);
  }

  return ParserArgs(
      inPath: inPath,
      outPath: outPath,
      compress: compress,
      skipExtract: skipExtract);
}

void _ensureValidInPath(File inPath) {
  if (!inPath.existsSync()) {
    throw FileSystemException("File ${inPath.path} not found");
  }

  if (inPath.statSync().type != FileSystemEntityType.file) {
    throw ArgumentError("${inPath.path} is not a file");
  }

  if (!inPath.path.endsWith(".fasta")) {
    throw ArgumentError("${inPath.path} is not a FASTA file");
  }
}

Stream<String> _readFasta(File inPath) async* {
  final lines =
      inPath.openRead().transform(utf8.decoder).transform(LineSplitter());
  await for (final line in lines) {
    yield line;
  }
}

String _parseHeader(String headerLine) {
  return headerLine.substring(1).split(' ')[0].trim();
}

void _parseMetadata(String metadataLine, SequenceMetadata seqMetadata) {
  final trimmedLine = metadataLine.trim();

  if (trimmedLine.startsWith('$commentSymbol$markersKey')) {
    seqMetadata.markers.addAll(_parseMarkers(trimmedLine.substring(1)));
  }

  if (trimmedLine.startsWith('$commentSymbol$transcriptionRatesKey')) {
    seqMetadata.transcriptionRates
        .addAll(_parseTranscriptionRates(trimmedLine.substring(1)));
  }
}

TranscriptionRates _parseTranscriptionRates(String metadataLine) {
  if (!metadataLine.startsWith(transcriptionRatesKey)) {
    throw ArgumentError(
        "Metadata $metadataLine does not start with '$transcriptionRatesKey'.");
  }

  final jsonString = metadataLine.replaceFirst(transcriptionRatesKey, '');
  final Map<String, dynamic> decoded = json.decode(jsonString);
  return decoded.map((key, value) => MapEntry(key, value.toDouble()));
}

Markers _parseMarkers(String metadataLine) {
  if (!metadataLine.startsWith(markersKey)) {
    throw ArgumentError(
        "Metadata $metadataLine does not start with '$markersKey'.");
  }

  final jsonString = metadataLine.replaceFirst(markersKey, '');
  final Map<String, dynamic> decoded = json.decode(jsonString);
  return decoded.map((key, value) => MapEntry(key, value as int));
}

Future<OrganismMetadata> parse(File inPath, Directory outPath) async {
  _ensureValidInPath(inPath);

  Map<String, SequenceMetadata> genes = {};
  String? seqId;

  final outputDir = Directory('${outPath.path}/$outputDirName');
  await outputDir.create(recursive: true);

  final outFile = File('${outputDir.path}/${inPath.uri.pathSegments.last}');
  final outSink = outFile.openWrite();

  try {
    await for (final line in _readFasta(inPath)) {
      if (line.startsWith(headerSymbol)) {
        seqId = _parseHeader(line);
        genes[seqId] = SequenceMetadata(
          markers: {},
          transcriptionRates: {},
        );
        outSink.writeln(line);
      } else if (line.startsWith(commentSymbol)) {
        if (seqId != null) {
          _parseMetadata(line, genes[seqId]!);
        }
      } else {
        // sequence line
        outSink.writeln(line);
      }
    }
  } finally {
    await outSink.close();
  }

  Map<String, StageMetadata> stages = {
    for (var stage in genes[genes.keys.first]!.transcriptionRates.keys)
      stage: StageMetadata(srr: '', url: ''),
  }; 

  return OrganismMetadata(stages: stages, genes: genes);
}

Future<File> compressFileZstd(File inPath) async {
  final compressedFile = File('${inPath.path}.zstd');
  await compressedFile.create();

  final sink = compressedFile.openWrite();
  final compressor = ZstdEncoder(level: ZstdOption.defaultLevel);

  await for (final chunk in inPath.openRead()) {
    final compressedChunk = compressor.convert(chunk);
    sink.add(compressedChunk);
  }

  await sink.close();
  return compressedFile;
}

Future<void> compressFileGzip(File inPath,
    {int level = ZLibOption.defaultLevel}) async {
  final outPath = File('${inPath.path}.gz');

  print('Compressing to ${outPath.path} ...');

  final inStream = inPath.openRead();
  final outSink = outPath.openWrite();
  final gzipCodec = GZipCodec(level: level);

  await inStream.transform(gzipCodec.encoder).pipe(outSink);
}

Future<void> _writeMetadataFile(
    File metadataFile, OrganismMetadata metadata) async {
  final metadataMap = Map.fromEntries([
    MapEntry(
      'stages',
      metadata.stages.map(
        (key, dynamic value) => MapEntry(key, value.toJson()),
      ),
    ),
    MapEntry(
      'genes',
      metadata.genes.map(
        (key, dynamic value) => MapEntry(key, value.toJson()),
      ),
    ),
  ]);
  final metadataString =
      const JsonEncoder.withIndent('\t').convert(metadataMap);

  await metadataFile.create(recursive: true);
  await metadataFile.writeAsString(metadataString);
}

Future<void> _compressFiles(List<File> files) async {
  print('Compressing ...');

  await Future.wait(files.map((file) => compressFileGzip(file)));
}

Future<void> main(List<String> arguments) async {
  final args = _parseArgs(arguments);

  final inputFile = File(args.inPath);
  final outputDir = Directory(args.outPath);
  List<File> filesToCompress = [];

  try {
    if (!args.skipExtract) {
      print('Extracting ...');

      final metadataFile = File(
          '${outputDir.path}/$outputDirName/${inputFile.uri.pathSegments.last}.metadata.json');

      final OrganismMetadata metadata = await parse(inputFile, outputDir);
      await _writeMetadataFile(metadataFile, metadata);
      filesToCompress.addAll([
        metadataFile,
        File(
            '${outputDir.path}/$outputDirName/${inputFile.uri.pathSegments.last}')
      ]);
    } else {
      print('Skipping extraction ...');

      filesToCompress.add(inputFile);
    }

    if (args.compress) {
      await _compressFiles(filesToCompress);
    }

    print('Output files created in: ${outputDir.path}/$outputDirName/');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
