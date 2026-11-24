import 'package:flutter/material.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';

/// Contact details and notes.
class LeadInfoSection extends StatelessWidget {
  const LeadInfoSection({required this.lead, super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _Row(
                icon: Icons.phone_outlined,
                value: lead.phone,
                note: lead.phoneNormalized == null
                    ? "Not recognised — won't be matched automatically"
                    : null,
              ),
              if (lead.email != null)
                _Row(icon: Icons.email_outlined, value: lead.email!),
              if (lead.website != null)
                _Row(icon: Icons.language, value: lead.website!),
              if (lead.source != null)
                _Row(icon: Icons.place_outlined, value: lead.source!),
              if (lead.notes != null)
                _Row(icon: Icons.notes, value: lead.notes!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.value, this.note});

  final IconData icon;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: context.colors.mutedText),
      title: SelectableText(value, style: context.text.body),
      subtitle: note == null
          ? null
          : Text(
              note!,
              style: context.text.caption.copyWith(
                color: context.colors.warning,
              ),
            ),
    );
  }
}
