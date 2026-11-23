/// Descriptive information about a JASPAR matrix (everything except the
/// counts themselves). Parsed defensively because the backend forwards the
/// JASPAR REST payload and some fields are strings in one version and lists
/// in another.

class JasparSpecies {
  const JasparSpecies(this.name, {this.taxId});

  final String name;
  final String? taxId;

  String? get url => taxId == null
      ? null
      : 'https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$taxId';
}

class JasparMetadata {
  const JasparMetadata({
    this.name,
    this.matrixId,
    this.matrixClass,
    this.taxon,
    this.species = const [],
    this.uniprotIds = const [],
  });

  final String? name;
  final String? matrixId;
  final String? matrixClass;
  final String? taxon;
  final List<JasparSpecies> species;
  final List<String> uniprotIds;

  String? get matrixUrl =>
      matrixId == null ? null : 'https://jaspar.elixir.no/matrix/$matrixId/';

  factory JasparMetadata.fromJson(Map<String, dynamic> json) {
    return JasparMetadata(
      name: _text(json['name']),
      matrixId: _text(json['matrix_id']),
      matrixClass: _text(json['class']),
      taxon: _capitalize(_text(json['tax_group'] ?? json['taxon'])),
      species: _parseSpecies(json['species']),
      uniprotIds: _parseList(json['uniprot_ids'] ?? json['uniprot_id']),
    );
  }
}

String? _text(Object? value) {
  if (value == null) return null;
  if (value is Iterable) {
    final parts = value
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

String? _capitalize(String? s) =>
    (s == null || s.isEmpty) ? s : s[0].toUpperCase() + s.substring(1);

List<String> _parseList(Object? value) {
  if (value == null) return const [];
  final items = value is Iterable ? value : [value];
  return [
    for (final item in items)
      if (item.toString().trim().isNotEmpty) item.toString().trim(),
  ];
}

List<JasparSpecies> _parseSpecies(Object? raw) {
  if (raw == null) return const [];
  final items = raw is Iterable ? raw : [raw];
  final result = <JasparSpecies>[];
  for (final item in items) {
    if (item is Map) {
      final name = item['name']?.toString().trim();
      final taxId = (item['tax_id'] ?? item['taxId'])?.toString().trim();
      if (name != null && name.isNotEmpty) {
        result.add(JasparSpecies(
          name,
          taxId: (taxId == null || taxId.isEmpty) ? null : taxId,
        ));
      }
    } else if (item != null && item.toString().trim().isNotEmpty) {
      result.add(JasparSpecies(item.toString().trim()));
    }
  }
  return result;
}
