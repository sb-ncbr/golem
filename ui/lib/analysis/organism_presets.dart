import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geneweb/analysis/organism.dart';
import 'package:geneweb/analysis/stage_and_color.dart';

/// Presets for organisms
///
/// See [Organism]
/// TODO private
class OrganismPresets {
  static final _arabidopsisStages = [
    // StageAndColor('tapetum_C', const Color(0xff993300)),
    // StageAndColor('EarlyPollen_C', const Color(0xffB71C1C), stroke: 4),
    // StageAndColor('UNM_C', const Color(0xffFF6D6D)),
    // StageAndColor('BCP_C', const Color(0xffC80002)),
    // StageAndColor('LatePollen_C', const Color(0xff0D47A1), stroke: 4),
    // StageAndColor('TCP_C', const Color(0xff21C5FF)),
    // StageAndColor('MPG_C', const Color(0xff305496)),
    // StageAndColor('SIV_C', const Color(0xffFF6600)),
    // StageAndColor('sperm_C', const Color(0xffFFC002)),
    // StageAndColor('leaves_C', const Color(0xff92D050)),
    // StageAndColor('seedling_C', const Color(0xffC6E0B4)),
    // StageAndColor('egg_C', const Color(0xff607D8B)),
    // StageAndColor('EarlyPollen_L', const Color(0xffB71C1C), stroke: 4),
    // StageAndColor('UNM_L', const Color(0xffFF6D6D)),
    // StageAndColor('BCP_L', const Color(0xffC80002)),
    // StageAndColor('LatePollen_L', const Color(0xff0D47A1), stroke: 4),
    // StageAndColor('TCP_L', const Color(0xff21C5FF)),
    // StageAndColor('MPG_L', const Color(0xff305496)),

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

    StageAndColor('Egg cell_Julca', Colors.orange, isCheckedByDefault: false),
    StageAndColor('Embryo', Colors.purpleAccent, isCheckedByDefault: false),
    StageAndColor('Endosperm', Colors.purple, isCheckedByDefault: false),

    // Chloroplast & Mitochondrion
    StageAndColor('Tapetum', const Color(0xff993300)),
    StageAndColor('EarlyPollen', const Color(0xffB71C1C)),
    StageAndColor('UNM', const Color(0xffFF6D6D)),
    StageAndColor('lerUNM', const Color(0xffFF6D6D)),
    StageAndColor('BCP', const Color(0xffC80002)),
    StageAndColor('lerBCP', const Color(0xffC80002)),
    StageAndColor('LatePollen', const Color(0xff0D47A1)),
    StageAndColor('TCP', const Color(0xff21C5FF)),
    StageAndColor('lerTCP', const Color(0xff21C5FF)),
    StageAndColor('MPG', const Color(0xff305496)),
    StageAndColor('lerMPG', const Color(0xff305496)),
    StageAndColor('SIV_PT', const Color(0xffFF6600)),
    StageAndColor('Sperm', const Color(0xffFFC002)),
    StageAndColor('Leaves', const Color(0xff92D050)),
    StageAndColor('Seedlings', const Color(0xffC6E0B4)),
    StageAndColor('Egg', const Color(0xff607D8B)),
  ];

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
      public: true,
      name: 'Chara braunii',
      filename: 'Chara_braunii.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Antheridia', Colors.indigo),
        StageAndColor('Oogonia', Colors.orange),
        StageAndColor('Zygotes', Colors.brown),
        StageAndColor('Vegetative_tissue', Colors.green),
      ],
      takeFirstTranscriptOnly: false,
    ),
    Organism(
      public: true,
      name: 'Marchantia polymorpha',
      filename: 'Marchantia_polymorpha-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridium', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Thallus', const Color(0xff548236)),
      ],
    ),
    Organism(
      name: 'Marchantia polymorpha',
      filename: 'Marchantia_polymorpha.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Antheridium', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Thallus', const Color(0xff548236)),
      ],
    ),
    Organism(
      name: 'Physcomitrium patens',
      filename: 'Physcomitrium_patens.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Antheridia_9DAI', const Color(0xff21C5FF)),
        StageAndColor('Antheridia_11DAI', const Color(0xff009ED6)),
        StageAndColor('Antheridia_14-15DAI_(mature)', const Color(0xff009AD0)),
//        StageAndColor('Antheridia', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell_packages', const Color(0xffFFDB69)),
        StageAndColor('Leaflets', const Color(0xff548236)),
        StageAndColor('Archegonia (mature)', Colors.orange),
        StageAndColor('Sporophyte (9 DAF)', Colors.teal),
      ],
    ),
    Organism(
      public: true,
      name: 'Physcomitrium patens',
      filename: 'Physcomitrium_patens-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Antheridia_9DAI', const Color(0xff21C5FF)),
        StageAndColor('Antheridia_11DAI', const Color(0xff009ED6)),
        StageAndColor('Antheridia_14-15DAI_(mature)', const Color(0xff0085B4)),
//        StageAndColor('Antheridia', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell_packages', const Color(0xffFFDB69)),
        StageAndColor('Leaflets', const Color(0xff548236)),
        StageAndColor('Archegonia (mature)', Colors.orange),
        StageAndColor('Sporophyte (9 DAF)', Colors.teal),
      ],
    ),
    Organism(
      name: 'Azolla filiculoides',
      filename: 'Azolla_filiculoides.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Leaves', const Color(0xff92D050)),
        StageAndColor('Spores', const Color(0xffFFC002)),
      ],
      takeFirstTranscriptOnly: false,
      public: true,
    ),
    Organism(
      name: 'Azolla filiculoides',
      filename: 'Azolla_filiculoides-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Leaves', const Color(0xff92D050)),
        StageAndColor('Spores', const Color(0xffFFC002)),
      ],
      takeFirstTranscriptOnly: false,
    ),
    Organism(
      name: 'Ceratopteris richardii',
      filename: 'Ceratopteris_richardii.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Gametophyte', const Color(0xff2980B9)),
        StageAndColor('Male_gametophyte', const Color(0xff5DADE2)),
        StageAndColor('Hermaphrodite_gametophyte', const Color(0xff8E44AD)),
        StageAndColor('Sporophyte', const Color(0xff229954)),
      ],
    ),
    Organism(
      name: 'Ceratopteris richardii',
      filename: 'Ceratopteris_richardii-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Gametophyte', const Color(0xff2980B9)),
        StageAndColor('Male_gametophyte', const Color(0xff5DADE2)),
        StageAndColor('Hermaphrodite_gametophyte', const Color(0xff8E44AD)),
        StageAndColor('Sporophyte', const Color(0xff229954)),
      ],
      public: true,
    ),
    Organism(
        public: true,
        name: 'Amborella trichopoda',
        filename: 'Amborella_trichopoda.fasta',
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
      public: true,
      name: 'Oryza sativa',
      filename: 'Oryza_sativa.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('TCP', const Color(0xff21C5FF)),
        StageAndColor('Pollen', const Color(0xff0085B4)),
        StageAndColor('Sperm_cell', const Color(0xffFFC002)),
        StageAndColor('Leaves', const Color(0xff92D050)),
      ],
    ),
    Organism(
      name: 'Hordeum vulgare',
      filename: 'Hordeum_vulgare.fasta',
      description: 'ATG',
      stages: [
        StageAndColor('Embryo_8_DAP', const Color(0xff6E2C00)),
        StageAndColor('Embryo_16_DAP', const Color(0xffA04000)),
        StageAndColor('Embryo_24_DAP', const Color(0xffD35400)),
        StageAndColor('Embryo_32_DAP', const Color(0xffE59866)),
        StageAndColor('Endosperm_4_DAP', const Color(0xff7D6608)),
        StageAndColor('Endosperm_8_DAP', const Color(0xff9A7D0A)),
        StageAndColor('Endosperm_16_DAP', const Color(0xffB7950B)),
        StageAndColor('Endosperm_24_DAP', const Color(0xffF1C40F)),
        StageAndColor('Endosperm_32_DAP', const Color(0xffF7DC6F)),
        StageAndColor('Seed_maternal_tissues_4_DAP', const Color(0xff1B4F72)),
        StageAndColor('Seed_maternal_tissues_8_DAP', const Color(0xff2874A6)),
        StageAndColor('Seed_maternal_tissues_16_DAP', const Color(0xff3498DB)),
        StageAndColor('Seed_maternal_tissues_24_DAP', const Color(0xff85C1E9)),
        StageAndColor('Leaf_non-infested_30_DAP', const Color(0xff82E0AA)),
      ],
    ),
    Organism(
      name: 'Hordeum vulgare',
      filename: 'Hordeum_vulgare-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [
        StageAndColor('Embryo_8_DAP', const Color(0xff6E2C00)),
        StageAndColor('Embryo_16_DAP', const Color(0xffA04000)),
        StageAndColor('Embryo_24_DAP', const Color(0xffD35400)),
        StageAndColor('Embryo_32_DAP', const Color(0xffE59866)),
        StageAndColor('Endosperm_4_DAP', const Color(0xff7D6608)),
        StageAndColor('Endosperm_8_DAP', const Color(0xff9A7D0A)),
        StageAndColor('Endosperm_16_DAP', const Color(0xffB7950B)),
        StageAndColor('Endosperm_24_DAP', const Color(0xffF1C40F)),
        StageAndColor('Endosperm_32_DAP', const Color(0xffF7DC6F)),
        StageAndColor('Seed_maternal_tissues_4_DAP', const Color(0xff1B4F72)),
        StageAndColor('Seed_maternal_tissues_8_DAP', const Color(0xff2874A6)),
        StageAndColor('Seed_maternal_tissues_16_DAP', const Color(0xff3498DB)),
        StageAndColor('Seed_maternal_tissues_24_DAP', const Color(0xff85C1E9)),
        StageAndColor('Leaf_non-infested_30_DAP', const Color(0xff82E0AA)),
      ],
      public: true,
    ),
    Organism(
      name: 'Zea mays',
      filename: 'Zea_mays.fasta',
      description: 'ATG',
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
      public: true,
      name: 'Zea mays',
      filename: 'Zea_mays-with-tss.fasta',
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
      filename: 'Solanum_lycopersicum.fasta',
      description: 'ATG',
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
      public: true,
      name: 'Solanum lycopersicum',
      filename: 'Solanum_lycopersicum-with-tss.fasta',
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
      filename: 'Arabidopsis_thaliana.fasta',
      description: 'ATG only',
      stages: _arabidopsisStages,
    ),
    Organism(
      public: true,
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana-with-tss.fasta',
      description: 'ATG, TSS',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis-variants.fasta',
      description: 'TSS, ATG, all splicing variants',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_mitochondrion.fasta',
      description: 'Mitochondrion dataset',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_chloroplast.fasta',
      description: 'Chloroplast dataset',
      stages: _arabidopsisStages,
    ),
    Organism(
      name: 'Arabidopsis thaliana',
      filename: 'Arabidopsis_thaliana_small_rna.fasta',
      description: 'Small RNA dataset',
      stages: [],
    ),
    Organism(
      name: 'Allium cepa',
      filename: 'Allium_cepa.fasta',
      description: 'ATG',
      stages: [],
    ),
    Organism(
      name: 'Silene vulgaris',
      filename: 'Silene_vulgaris.fasta',
      description: 'ATG',
      stages: [],
    ),
    Organism(
      name: 'Silene vulgaris',
      filename: 'Silene_vulgaris-with-tss.fasta',
      description: 'ATG, TSS',
      stages: [],
    ),
  ];
}
