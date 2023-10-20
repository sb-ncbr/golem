import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:golem_ui/analysis/organism.dart';
import 'package:golem_ui/analysis/stage_and_color.dart';

/// Presets for organisms
///
/// See [Organism]
class OrganismPresets {
  static final _arabidopsisStages = [
    StageAndColor('C_Tapetum', const Color(0xff993300)),
    StageAndColor('C_EarlyPollen', const Color(0xffB71C1C)),
    StageAndColor('C_UNM', const Color(0xffFF6D6D)),
    StageAndColor('C_BCP', const Color(0xffC80002)),
    StageAndColor('C_LatePollen', const Color(0xff0D47A1)),
    StageAndColor('C_TCP', const Color(0xff21C5FF)),
    StageAndColor('C_MPG', const Color(0xff305496)),
    StageAndColor('C_SIV_PT', const Color(0xffFF6600)),
    StageAndColor('C_Sperm_cell', const Color(0xffFFC002)),
    StageAndColor('C_Leaves_35d', const Color(0xff92D050)),
    StageAndColor('C_Seedlings_10d', const Color(0xffC6E0B4)),
    StageAndColor('C_Egg_cell', const Color(0xff607D8B)),
    StageAndColor('L_EarlyPollen', const Color(0xffB71C1C), isCheckedByDefault: false),
    StageAndColor('L_UNM', const Color(0xffFF6D6D), isCheckedByDefault: false),
    StageAndColor('L_BCP', const Color(0xffC80002), isCheckedByDefault: false),
    StageAndColor('L_LatePollen', const Color(0xff0D47A1), isCheckedByDefault: false),
    StageAndColor('L_TCP', const Color(0xff21C5FF), isCheckedByDefault: false),
    StageAndColor('L_MPG', const Color(0xff305496), isCheckedByDefault: false),
  ];

  /// Method will match the filename to the organism. This is useful for uploaded files.
  static Organism organismByFileName(String filename) {
    final preset = kOrganisms.firstWhereOrNull((element) => element.filename?.startsWith(filename) == true);
    if (preset != null) {
      return preset;
    }
    final name =
        RegExp(r'([A-Za-z0-9_]+).*').firstMatch(filename)?.group(1)?.replaceAll('_', ' ') ?? 'Unknown organism';
    return Organism(name: name, filename: filename);
  }

  static final List<Organism> kOrganisms = [
    Organism(
      name: 'Marchantia polymorpha',
      filename: 'Marchantia_polymorpha-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridium', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Thallus', const Color(0xff548236)),
      ],
    ),
    Organism(
      name: 'Physcomitrium patens',
      filename: 'Physcomitrium_patens-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridia_9DAI', const Color(0xff21C5FF)),
        StageAndColor('Antheridia_11DAI', const Color(0xff009ED6)),
        StageAndColor('Antheridia_14-15DAI_(mature)', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell_packages', const Color(0xffFFDB69)),
        StageAndColor('Leaflets', const Color(0xff548236)),
      ],
    ),
    Organism(
        name: 'Amborella trichopoda',
        filename: 'Amborella_trichopoda.fasta.zip',
        description: 'ATG',
        takeFirstTranscriptOnly: false,
        stages: [
          StageAndColor('UNM', const Color(0xffFF6D6D)),
          StageAndColor('Pollen', const Color(0xff0085B4)),
          StageAndColor('PT_bicellular', const Color(0xffE9A5D2)),
          StageAndColor('PT_tricellular', const Color(0xff77175C)),
          StageAndColor('Generative_cell', const Color(0xffB48502)),
          StageAndColor('Sperm_cell', const Color(0xffFFC002)),
          StageAndColor('Leaves', const Color(0xff92D050)),
        ]),
    Organism(
      name: 'Oryza sativa',
      filename: 'Oryza_sativa.fasta.zip',
      description: 'ATG',
      stages: [
        StageAndColor('TCP', const Color(0xff21C5FF)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Zea mays',
      filename: 'Zea_mays-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        //BCP missing
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Solanum lycopersicum',
      filename: 'Solanum_lycopersicum-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Microspore', const Color(0xffFF6D6D)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Pollen_grain', const Color(0xff305496)),
        StageAndColor('PT', const Color(0xffE9A5D2)),
        StageAndColor('PT_1,5h', const Color(0xffD75BAE)),
        StageAndColor('PT_3h', const Color(0xffAC2A81)),
        StageAndColor('PT_9h', const Color(0xff471234)),
        StageAndColor('Generative_cell', const Color(0xffB48502)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana-with-tss.fasta.zip',
      description: 'ATG, TSS',
      stages: _arabidopsisStages,
    ),
  ];
}
