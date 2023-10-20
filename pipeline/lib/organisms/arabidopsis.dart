import 'package:pipeline/organisms/base_organism.dart';

abstract class Arabidopsis extends BaseOrganism {
  Arabidopsis({
    required super.name,
    super.ignoredFeatures = const ['chromosome', 'gene', 'transcript'],
    super.triggerFeatures = const ['mRNA'],
    super.allowMissingStartCodon = false,
    super.useSelfInsteadOfStartCodon = false,
    super.useAtg = true,
    super.deltaBases = BaseOrganism.kDefaultDeltaBases,
  });

  @override
  String? stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^[0-9]+\.\s*Arabidopsis_([^.]*)')
        .firstMatch(filename)
        ?.group(1);
    return key;
  }

  @override
  String seqIdTransformer(String seqId) => seqId.replaceAll('Chr', '');

  @override
  String sequenceIdentifier(List<String> line) {
    // All names in GFF have .1, but TPM files do not have it
    return '${line[0]}.1';
  }
}

class ArabidopsisThaliana extends Arabidopsis {
  ArabidopsisThaliana() : super(name: 'Arabidopsis thaliana');
  @override
  String stageNameFromTpmFilePath(String path) {
    final filename = path.split('/').last;
    final key = RegExp(r'^Arabidopsis_([^.]*)').firstMatch(filename)!.group(1)!;
    return key;
  }
}
