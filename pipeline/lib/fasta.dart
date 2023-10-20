import 'dart:convert';
import 'dart:io';

/// Holds the contents of the FASTA file
///
/// Use [load] to load the file from disk
class Fasta {
  /// Map of available sequences
  ///
  /// Key is the sequence ID, value is the path to the file
  final Map<String, String> availableSequences;

  /// Temporary directory where the files are stored
  final Directory tempDir;

  FastaGene? _sequence;

  Fasta._({required this.availableSequences, required this.tempDir});

  /// Loads the FASTA file from disk
  ///
  /// The file is split into multiple files, one per sequence
  static Future<Fasta> load(FileSystemEntity entity) async {
    Map<String, String> sequences = {};
    final tempDir = Directory.systemTemp.createTempSync(entity.path.split('/').last);
    final file = File(entity.path);
    final stream = file.openRead();
    List<String> buffer = [];
    String? path;
    List<Future> completions = [];
    await stream.transform(utf8.decoder).transform(LineSplitter()).listen((line) {
      if (line.startsWith('>')) {
        if (path != null) {
          assert(buffer.isNotEmpty);
          completions.add(_writeFasta(path!, buffer));
        }
        final seqId = line.substring(1).split(' ').first;
        path = '${tempDir.path}/$seqId.fasta';
        sequences[seqId] = path!;
        buffer = [line];
      } else {
        if (path == null) {
          throw StateError('Unknown sequence ID for line $line.');
        }
        buffer.add(line);
      }
    }).asFuture();
    if (path != null) {
      completions.add(_writeFasta(path!, buffer));
    }
    Future.wait(completions);
    return Fasta._(availableSequences: sequences, tempDir: tempDir);
  }

  static Future<void> _writeFasta(String path, List<String> lines) async {
    final outputFile = File(path);
    outputFile.writeAsString(lines.join("\n"), flush: true);
  }

  /// Returns the sequence with the given ID
  Future<FastaGene?> sequence(String seqId) async {
    if (_sequence == null || _sequence!.seqId != seqId) {
      if (availableSequences[seqId] == null) {
        return null;
      }
      _sequence = await FastaGene.fromFile(availableSequences[seqId]!);
    }
    return _sequence!;
  }

  /// Cleans up the temporary files
  Future<void> cleanup() async {
    for (final path in availableSequences.values) {
      final file = File(path);
      await file.delete();
    }
    await tempDir.delete();
  }
}

/// Holds the contents of a single FASTA sequence
class FastaGene {
  /// Sequence ID
  final String seqId;

  /// Sequence
  final String sequence;

  FastaGene._({required this.seqId, required this.sequence});

  /// Loads the sequence from a file
  static Future<FastaGene> fromFile(String path) async {
    final file = File(path);
    final lines = await file.readAsLines();
    String? seqId;
    List<String> current = [];
    for (final line in lines) {
      if (line.startsWith('>')) {
        if (seqId != null || current.isNotEmpty) {
          throw ('Expected single sequence in $path');
        }
        seqId = line.substring(1).split(' ').first;
      } else {
        if (seqId == null) {
          throw StateError('Unknown sequence ID for line $line in $path.');
        }
        current.add(line.trim());
      }
    }
    if (seqId == null || current.isEmpty) {
      throw StateError('No sequence found in $path.');
    }
    return FastaGene._(seqId: seqId, sequence: current.join().toUpperCase());
  }
}
