import 'package:pipeline/organisms/base_organism.dart';

class Amborella extends BaseOrganism {
  Amborella()
      : super(
          name: 'Amborella trichopoda',

          /// Turn off removing other "transcripts", Amborella does not use dot notation.
          oneTranscriptPerGene: false,
        );

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Amborella_([^.]*)').firstMatch(filename)?.group(1);
    return key;
  }

  @override
  String? transcriptParser(Map<String, String> attributes) {
    // Convert `evm_27.model.AmTr_v1.0_scaffold00001.1` to `evm_27.TU.AmTr_v1.0_scaffold00001.1`
    final original = attributes['Name'];
    if (original == null) return null;
    final parts = original.split('.');
    return [parts[0], 'TU', ...parts.sublist(2)].join('.');
  }

  @override
  String sequenceIdentifier(List<String> line) {
    // It's in the Alias field
    return line[1];
  }

  @override

  /// In case of Amborella, the dot notation does not mean transcripts
  String? fallbackTranscriptParser(Map<String, String> attributes) => null;
}
