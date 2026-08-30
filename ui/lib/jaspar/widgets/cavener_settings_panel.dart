// cavener_settings_panel.dart
//
// Another StatelessWidget: it holds no state itself, just displays
// `settings` and reports every change upward via `onChanged`. This
// "controlled component" pattern (parent owns the data, child only
// renders + reports) will look familiar if you've used React.

import 'package:flutter/material.dart';

import '../cavener_settings.dart';

class CavenerSettingsPanel extends StatelessWidget {
  const CavenerSettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final CavenerSettings settings;
  final ValueChanged<CavenerSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cavener (1987) method',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Single-base threshold: ${(settings.t1 * 100).round()}%'),
            Slider(
              value: settings.t1,
              min: 0.5,
              max: 1.0,
              onChanged: (v) => onChanged(settings.copyWith(t1: v)),
            ),
            Text('2/3-base threshold: ${(settings.t2 * 100).round()}%'),
            Slider(
              value: settings.t2,
              min: 0.5,
              max: 1.0,
              onChanged: (v) => onChanged(settings.copyWith(t2: v)),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.icEnabled,
              onChanged: (v) =>
                  onChanged(settings.copyWith(icEnabled: v ?? false)),
              title: const Text('Set low-information positions to N'),
            ),
            if (settings.icEnabled) ...[
              Text(
                'Information content threshold: '
                '${settings.icThreshold.toStringAsFixed(2)} bits',
              ),
              Slider(
                value: settings.icThreshold,
                min: 0,
                max: 2,
                divisions: 40,
                onChanged: (v) => onChanged(settings.copyWith(icThreshold: v)),
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trim,
              onChanged: (v) => onChanged(settings.copyWith(trim: v ?? false)),
              title: const Text('Trim insignificant flanks (display only)'),
            ),
          ],
        ),
      ),
    );
  }
}
