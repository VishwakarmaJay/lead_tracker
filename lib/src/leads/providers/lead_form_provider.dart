import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/utils/phone_normalizer.dart';
import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_refresh.dart';
import 'package:lead_tracker/src/shared/providers/phone_normalizer_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lead_form_provider.g.dart';

/// Raw text from the add/edit form.
@immutable
class LeadFormInput {
  const LeadFormInput({
    required this.name,
    required this.phone,
    this.company = '',
    this.email = '',
    this.website = '',
    this.source = '',
    this.notes = '',
    this.status = LeadStatus.newLead,
    this.temperature = LeadTemperature.unrated,
  });

  factory LeadFormInput.fromLead(Lead lead) => LeadFormInput(
    name: lead.name,
    phone: lead.phone,
    company: lead.company ?? '',
    email: lead.email ?? '',
    website: lead.website ?? '',
    source: lead.source ?? '',
    notes: lead.notes ?? '',
    status: lead.status,
    temperature: lead.temperature,
  );

  final String name;
  final String phone;
  final String company;
  final String email;
  final String website;
  final String source;
  final String notes;
  final LeadStatus status;
  final LeadTemperature temperature;
}

/// Form validation, shared by the form fields and tests.
const maxLeadNameLength = 120;
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _digitPattern = RegExp(r'\d');

String? validateLeadName(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Enter a name.';
  }
  if (text.length > maxLeadNameLength) {
    return 'Keep the name under $maxLeadNameLength characters.';
  }
  return null;
}

/// Required, and must contain digits. A number that can't be normalised is
/// still allowed — the form warns and asks before saving.
String? validateLeadPhone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Enter a phone number.';
  }
  if (!_digitPattern.hasMatch(text)) {
    return 'A phone number needs digits.';
  }
  return null;
}

String? validateLeadEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty || _emailPattern.hasMatch(text)) {
    return null;
  }
  return 'This email address looks incomplete.';
}

String? _optional(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

/// Turns form text into a draft: trims, empties → null, adds the normalised
/// phone (null when it can't be recognised).
LeadDraft leadDraftFromInput(LeadFormInput input, PhoneNormalizer normalizer) {
  final phone = input.phone.trim();
  return LeadDraft(
    name: input.name.trim(),
    phone: phone,
    phoneNormalized: normalizer.normalize(phone),
    company: _optional(input.company),
    email: _optional(input.email),
    website: _optional(input.website),
    source: _optional(input.source),
    status: input.status,
    temperature: input.temperature,
    notes: _optional(input.notes),
  );
}

/// Saves the add/edit lead form.
@riverpod
class LeadEditor extends _$LeadEditor {
  @override
  bool build() => false; // true while saving

  /// Other active leads with the same normalised number (for the
  /// "already have this number" warning). Empty when the number can't be
  /// normalised.
  Future<List<Lead>> findDuplicates(String phone, {int? exceptLeadId}) async {
    final normalized = ref.read(phoneNormalizerProvider).normalize(phone);
    if (normalized == null) {
      return const [];
    }
    final matches = await ref
        .read(leadRepositoryProvider)
        .findByNormalizedPhone(normalized);
    return [
      for (final lead in matches)
        if (lead.id != exceptLeadId) lead,
    ];
  }

  bool isPhoneRecognised(String phone) =>
      ref.read(phoneNormalizerProvider).isValid(phone);

  /// Creates a lead, or updates [existing]. Returns the lead id.
  Future<int> save(LeadFormInput input, {Lead? existing}) async {
    state = true;
    try {
      final draft = leadDraftFromInput(
        input,
        ref.read(phoneNormalizerProvider),
      );
      final repo = ref.read(leadRepositoryProvider);
      final int id;
      if (existing == null) {
        id = await repo.createLead(draft);
      } else {
        id = existing.id;
        await repo.updateLead(
          existing.copyWith(
            name: draft.name,
            phone: draft.phone,
            phoneNormalized: () => draft.phoneNormalized,
            company: () => draft.company,
            email: () => draft.email,
            website: () => draft.website,
            source: () => draft.source,
            status: draft.status,
            temperature: draft.temperature,
            notes: () => draft.notes,
          ),
        );
      }
      ref.refreshLeadViews(leadId: id);
      return id;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }
}
