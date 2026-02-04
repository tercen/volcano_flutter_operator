import 'package:flutter/material.dart';

/// Slider with label and value display
class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedValue =
        valueFormatter?.call(value) ?? value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              formattedValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Range slider with label and value display
class LabeledRangeSlider extends StatelessWidget {
  final String label;
  final double startValue;
  final double endValue;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double, double)? valueFormatter;

  const LabeledRangeSlider({
    super.key,
    required this.label,
    required this.startValue,
    required this.endValue,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedValue = valueFormatter?.call(startValue, endValue) ??
        '${startValue.toStringAsFixed(1)} to ${endValue.toStringAsFixed(1)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              formattedValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: RangeSlider(
            values: RangeValues(
              startValue.clamp(min, max),
              endValue.clamp(min, max),
            ),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
