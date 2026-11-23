import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../jaspar_metadata.dart';

const jasparDatabaseUrl = 'https://jaspar.elixir.no/';

/// Header action of the import card: opens the logo's JASPAR page, or the
/// JASPAR database itself while nothing has been downloaded.
class JasparOpenButton extends StatelessWidget {
  const JasparOpenButton({
    super.key,
    required this.metadata,
    required this.fallbackId,
  });

  final JasparMetadata? metadata;
  final String fallbackId;

  @override
  Widget build(BuildContext context) {
    final meta = metadata;
    final id = meta?.matrixId ?? fallbackId;
    final url = meta == null
        ? jasparDatabaseUrl
        : (meta.matrixUrl ?? 'https://jaspar.elixir.no/matrix/$id/');

    return TextButton.icon(
      onPressed: () => launchUrl(Uri.parse(url)),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(meta == null ? 'JASPAR database' : 'Open $id in JASPAR'),
    );
  }
}

/// Compact "Label: value" list of the downloaded logo. Wraps instead of
/// stacking one row per field, so the import card is hopefully short enough.
class JasparMetadataView extends StatelessWidget {
  const JasparMetadataView({
    super.key,
    required this.metadata,
    required this.fallbackId,
  });

  final JasparMetadata? metadata;

  /// Used when the backend did not return a matrix ID.
  final String fallbackId;

  @override
  Widget build(BuildContext context) {
    final meta = metadata;
    if (meta == null) return const SizedBox.shrink();

    final id = meta.matrixId ?? fallbackId;

    return Wrap(
      spacing: 28,
      runSpacing: 6,
      children: [
        _Item('Name', _plain(meta.name)),
        _Item('Matrix ID', _plain(id)),
        _Item('Class', _plain(meta.matrixClass)),
        _Item('Taxon', _plain(meta.taxon)),
        _Item('Species', _species(meta.species)),
        _Item('Uniprot ID', _uniprot(meta.uniprotIds)),
      ],
    );
  }

  Widget _plain(String? value) =>
      Text((value == null || value.isEmpty) ? '—' : value);

  Widget _species(List<JasparSpecies> species) {
    if (species.isEmpty) return const Text('—');
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        for (final s in species)
          s.url == null
              ? Text(s.name)
              : _ExternalLink(label: s.name, url: s.url!),
      ],
    );
  }

  Widget _uniprot(List<String> ids) {
    if (ids.isEmpty) return const Text('—');
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        for (final id in ids)
          _ExternalLink(
            label: id,
            url: 'https://www.uniprot.org/uniprot/$id',
          ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Flexible(child: value),
      ],
    );
  }
}

class _ExternalLink extends StatelessWidget {
  const _ExternalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        label,
        style: TextStyle(color: color, decoration: TextDecoration.underline),
      ),
    );
  }
}
