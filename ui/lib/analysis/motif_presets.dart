import 'package:golem_ui/analysis/motif.dart';

/// Presets for motifs that are used in the UI
///
/// See [Motif]
class MotifPresets {
  static final List<Motif> presets = [
    Motif(name: 'ABRE', definitions: ['ACGTG']),
    Motif(name: 'ARR10_core', definitions: ['GATY']),
    Motif(name: 'BR_response element', definitions: ['CGTGYG']),
    Motif(name: 'CAAT-box', definitions: ['CCAATT']),
    Motif(name: 'DOF_core motif', definitions: ['AAAG']),
    Motif(name: 'DRE/CRT element', definitions: ['CCGAC']),
    Motif(name: 'E-box', definitions: ['CANNTG']),
    Motif(name: 'G-box', definitions: ['CACGTG']),
    Motif(name: 'GCC-box', definitions: ['GCCGCC']),
    Motif(name: 'GTGA motif', definitions: ['GTGA']),
    Motif(name: 'I-box', definitions: ['GATAAG']),
    Motif(name: 'pollen Q-element', definitions: ['AGGTCA']),
    Motif(name: 'POLLEN1_LeLAT52', definitions: ['AGAAA']),
    Motif(name: 'TATA-box', definitions: ['TATAWA']),
  ]..sort(((a, b) => a.name.compareTo(b.name)));
}
