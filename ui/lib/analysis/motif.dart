/// Stores motif to search
///
/// Codes via https://www.genome.jp/kegg/catalog/codes1.html
class Motif {
  String get id => definitions.join(',');
  final bool isCustom;
  final String name;
  final List<String> definitions;

  static const supportedNucleotides = {
    'A',
    'G',
    'C',
    'T',
    'U',
    'R',
    'Y',
    'N',
    'W',
    'S',
    'M',
    'K',
    'B',
    'H',
    'D',
    'V',
  };

  static const reverseComplements = {
    'A': 'T',
    'G': 'C',
    'C': 'G',
    'T': 'A',
    'U': 'A',
    'R': 'Y',
    'Y': 'R',
    'N': 'N',
    'W': 'W',
    'S': 'S',
    'M': 'K',
    'K': 'M',
    'B': 'V',
    'H': 'D',
    'D': 'H',
    'V': 'B',
  };

  Motif({required this.name, required this.definitions, this.isCustom = false});

  static String? validate(List<String> definitions) {
    if (definitions.isEmpty) {
      return 'Definition cannot be empty';
    }
    if (definitions.where((definition) => !RegExp(r"^[AGCTURYNWSMKBHDV]+$").hasMatch(definition)).isNotEmpty) {
      return 'Motif definition contains invalid characters';
    }
    return null;
  }

  Map<String, RegExp> get regExp {
    return {
      for (final definition in definitions) definition: toRegExp(definition),
    };
  }

  static RegExp toRegExp(String def, [bool strict = false]) {
    final List<String> result = [
      if (strict) '^',
      for (int i = 0; i < def.length; i++) _nucleotideCodeToRegExpPart(def[i]),
      if (strict) '\$',
    ];
    return RegExp(result.join());
  }

  Map<String, RegExp> get reverseComplementRegExp {
    return {
      for (final definition in reverseDefinitions) definition: toRegExp(definition),
    };
  }

  List<String> get reverseDefinitions {
    List<String> complements = [];
    for (final definition in definitions) {
      final result = List<String>.generate(definition.length, (index) {
        final code = definition[index];
        final reverse = reverseComplements[code];
        if (reverse == null) {
          ArgumentError('Unsupported code `$code`');
        }
        return reverse!;
      });
      complements.add(result.reversed.join());
    }
    return complements;
  }

  static String _nucleotideCodeToRegExpPart(String code) {
    switch (code) {
      case 'A':
      case 'G':
      case 'C':
      case 'T':
      case 'U':
        return code;
      case 'R':
        return '[RAG]';
      case 'Y':
        return '[YCT]';
      case 'N':
        return '.';
      case 'W':
        return '[WAT]';
      case 'S':
        return '[SGC]';
      case 'M':
        return '[MAC]';
      case 'K':
        return '[KGT]';
      case 'B':
        return '[BSYKGCT]';
      case 'H':
        return '[HMYWACT]';
      case 'D':
        return '[DRKWAGT]';
      case 'V':
        return '[VRSMAGC]';
      default:
        throw ArgumentError('Unsupported code `$code`');
    }
  }

  static Set<String> drillDownCodes(String code) {
    switch (code) {
      case 'A':
      case 'G':
      case 'C':
      case 'T':
      case 'U':
        return {};
      case 'R':
        return {'A', 'G'};
      case 'Y':
        return {'C', 'T'};
      case 'N':
        return supportedNucleotides;
      case 'W':
        return {'A', 'T'};
      case 'S':
        return {'G', 'C'};
      case 'M':
        return {'A', 'C'};
      case 'K':
        return {'G', 'T'};
      case 'B':
        return {'S', 'Y', 'K', 'G', 'C', 'T'};
      case 'H':
        return {'M', 'Y', 'W', 'A', 'C', 'T'};
      case 'D':
        return {'R', 'K', 'W', 'A', 'G', 'T'};
      case 'V':
        return {'R', 'S', 'M', 'A', 'G', 'C'};
      default:
        throw ArgumentError('Unsupported code `$code`');
    }
  }
}
