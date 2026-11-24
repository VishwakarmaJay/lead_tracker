import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';

/// Display text and colors for lead enums. Public: used by other features'
/// screens that show leads (see leads/MODULE.md).
extension LeadStatusLabel on LeadStatus {
  String get label => switch (this) {
    LeadStatus.newLead => 'New',
    LeadStatus.contacted => 'Contacted',
    LeadStatus.qualified => 'Qualified',
    LeadStatus.proposalSent => 'Proposal sent',
    LeadStatus.won => 'Won',
    LeadStatus.lost => 'Lost',
  };
}

extension LeadTemperatureLabel on LeadTemperature {
  String get label => switch (this) {
    LeadTemperature.unrated => 'Unrated',
    LeadTemperature.hot => 'Hot',
    LeadTemperature.warm => 'Warm',
    LeadTemperature.cold => 'Cold',
  };

  Color color(BuildContext context) => switch (this) {
    LeadTemperature.unrated => context.colors.mutedText,
    LeadTemperature.hot => context.colors.hot,
    LeadTemperature.warm => context.colors.warm,
    LeadTemperature.cold => context.colors.cold,
  };

  IconData get icon => switch (this) {
    LeadTemperature.unrated => Icons.radio_button_unchecked,
    LeadTemperature.hot => Icons.local_fire_department,
    LeadTemperature.warm => Icons.wb_sunny_outlined,
    LeadTemperature.cold => Icons.ac_unit,
  };
}

/// Circle with the lead's initial, ringed in its temperature color.
class LeadAvatar extends StatelessWidget {
  const LeadAvatar({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final color = lead.temperature.color(context);
    final initial = lead.name.trim().isEmpty
        ? '?'
        : lead.name.trim().characters.first.toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(initial, style: context.text.label.copyWith(color: color)),
    );
  }
}

/// Small rounded label, e.g. the status on a list row.
class LabelPill extends StatelessWidget {
  const LabelPill({required this.text, this.color, this.icon, super.key});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: 4),
          ],
          Text(text, style: context.text.caption.copyWith(color: tint)),
        ],
      ),
    );
  }
}
