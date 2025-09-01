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
typedef Metadata = Map<String, SequenceMetadata>;

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

  factory SequenceMetadata.fromJson(Map<String, dynamic> json) =>
      SequenceMetadata(
        markers: Map<String, int>.from(json['markers']),
        transcriptionRates:
            Map<String, double>.from(json['transcriptionRates']),
      );
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

Future<Metadata> parse(File inPath, Directory outPath) async {
  _ensureValidInPath(inPath);

  final Metadata seqMetadata = {};
  String? seqId;

  final outputDir = Directory('${outPath.path}/$outputDirName');
  await outputDir.create(recursive: true);

  final outFile = File('${outputDir.path}/${inPath.uri.pathSegments.last}');
  final outSink = outFile.openWrite();

  try {
    await for (final line in _readFasta(inPath)) {
      if (line.startsWith(headerSymbol)) {
        seqId = _parseHeader(line);
        seqMetadata[seqId] = SequenceMetadata(
          markers: {},
          transcriptionRates: {},
        );
        outSink.writeln(line);
      } else if (line.startsWith(commentSymbol)) {
        if (seqId != null) {
          _parseMetadata(line, seqMetadata[seqId]!);
        }
      } else {
        // sequence line
        outSink.writeln(line);
      }
    }
  } finally {
    await outSink.close();
  }

  return seqMetadata;
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

  final inStream = inPath.openRead();
  final outSink = outPath.openWrite();
  final gzipCodec = GZipCodec(level: level);

  await inStream.transform(gzipCodec.encoder).pipe(outSink);
}

Future<void> main(List<String> arguments) async {
  String? inPath;
  String outPath = '.';
  bool compress = false;

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
      case '-h':
      case '--help':
        print('''
GOLEM fasta metadata extractor

This script processes FASTA files from the GOLEM pipeline to extract metadata. 
It creates two output files: a JSON file that stores the extracted metadata, 
and a new FASTA file that contains only the sequences, stripped of the original metadata.

Usage:
  dart fasta_metadata_extractor.dart -i <input_file> [-o <output_directory>] [-c]

Options:
  -i, --in-path     Input FASTA file path (required)
  -o, --out-path    Output directory path (default: current directory)
  -c, --compress    Whether to also compress FASTA and metadata files using gzip (default: false).
  -h, --help        Show this help message
        ''');
        return;
    }
  }

  if (inPath == null) {
    print(
        'Error: Input path is required. Use -i or --in-path to specify the input file.');
    print('Use --help for more information.');
    exit(1);
  }

  final inputFile = File(inPath);
  final outputDir = Directory(outPath);

  try {
    print('Extracting ...');
    final Metadata metadata = await parse(inputFile, outputDir);
    final metadataFile = File(
        '${outputDir.path}/$outputDirName/${inputFile.uri.pathSegments.last}.metadata.json');

    final metadataString = const JsonEncoder.withIndent('\t')
        .convert(metadata.map((key, value) => MapEntry(key, value.toJson())));
    await metadataFile.create(recursive: true);
    await metadataFile.writeAsString(metadataString);

    if (compress) {
      print('Compressing ...');

      await compressFileGzip(metadataFile);
      await compressFileGzip(File(
          '${outputDir.path}/$outputDirName/${inputFile.uri.pathSegments.last}'));
    }

    print('Output files created in: ${outputDir.path}/$outputDirName/');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
