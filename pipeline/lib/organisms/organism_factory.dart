import 'package:pipeline/organisms/amborella.dart';
import 'package:pipeline/organisms/arabidopsis.dart';
import 'package:pipeline/organisms/base_organism.dart';
import 'package:pipeline/organisms/marchantia.dart';
import 'package:pipeline/organisms/oryza.dart';
import 'package:pipeline/organisms/physcomitrium.dart';
import 'package:pipeline/organisms/solanum.dart';
import 'package:pipeline/organisms/zea.dart';

/// Factory to get an organism by name
class OrganismFactory {
  static BaseOrganism getOrganism(String organism) {
    switch (organism) {
      case 'Amborella_trichopoda':
        return Amborella();
      case 'Arabidopsis_thaliana':
        return ArabidopsisThaliana();
      case 'Marchantia_polymorpha':
        return Marchantia();
      case 'Oryza_sativa':
        return Oryza();
      case 'Physcomitrium_patens':
        return Physcomitrium();
      case 'Solanum_lycopersicum':
        return Solanum();
      case 'Zea_mays':
        return Zea();

      default:
        throw ArgumentError('Unknown organism: $organism');
    }
  }
}
