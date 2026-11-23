import 'package:flutter/material.dart';

import '../cavener_settings.dart';
import '../jaspar_info_texts.dart';
import 'section_card.dart';

/// Controls for the Cavener (1987) consensus method.
/// The surrounding title/"i" button live in the SectionCard;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingLabel(
          label: 'Single-base threshold: ${(settings.t1 * 100).round()}%',
          infoTitle: infoSingleBaseTitle,
          infoText: infoSingleBaseText,
        ),
        Slider(
          value: settings.t1,
          min: 0.5,
          max: 1.0,
          onChanged: (v) => onChanged(settings.copyWith(t1: v)),
        ),
        _SettingLabel(
          label: '2/3-base threshold: ${(settings.t2 * 100).round()}%',
          infoTitle: infoMultiBaseTitle,
          infoText: infoMultiBaseText,
        ),
        Slider(
          value: settings.t2,
          min: 0.5,
          max: 1.0,
          onChanged: (v) => onChanged(settings.copyWith(t2: v)),
        ),
        _SettingCheckbox(
          value: settings.icEnabled,
          onChanged: (v) => onChanged(settings.copyWith(icEnabled: v)),
          label: 'Set low-information positions to N',
          infoTitle: infoLowInfoTitle,
          infoText: infoLowInfoText,
        ),
        if (settings.icEnabled) ...[
          _SettingLabel(
            label: 'Information content threshold: '
                '${settings.icThreshold.toStringAsFixed(2)} bits',
            infoTitle: infoIcThresholdTitle,
            infoText: infoIcThresholdText,
          ),
          Slider(
            value: settings.icThreshold,
            min: 0,
            max: 2,
            divisions: 40,
            onChanged: (v) => onChanged(settings.copyWith(icThreshold: v)),
          ),
        ],
        _SettingCheckbox(
          value: settings.trim,
          onChanged: (v) => onChanged(settings.copyWith(trim: v)),
          label: 'Trim flanks',
          infoTitle: infoTrimTitle,
          infoText: infoTrimText,
        ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel({
    required this.label,
    required this.infoTitle,
    required this.infoText,
  });

  final String label;
  final String infoTitle;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        InfoButton(title: infoTitle, text: infoText),
      ],
    );
  }
}

class _SettingCheckbox extends StatelessWidget {
  const _SettingCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.infoTitle,
    required this.infoText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String infoTitle;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        InfoButton(title: infoTitle, text: infoText),
      ],
    );
  }
}
