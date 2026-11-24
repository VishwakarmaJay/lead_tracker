import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/database/db_value.dart';

enum LeadStatus implements DbValue {
  newLead('new'),
  contacted('contacted'),
  qualified('qualified'),
  proposalSent('proposal_sent'),
  won('won'),
  lost('lost');

  const LeadStatus(this.dbValue);

  @override
  final String dbValue;
}

enum LeadTemperature implements DbValue {
  unrated('unrated'),
  hot('hot'),
  warm('warm'),
  cold('cold');

  const LeadTemperature(this.dbValue);

  @override
  final String dbValue;
}

/// A saved lead (row in `leads`).
@immutable
class Lead {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.temperature,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNormalized,
    this.company,
    this.email,
    this.website,
    this.source,
    this.notes,
    this.deletedAt,
  });

  factory Lead.fromMap(Map<String, Object?> map) {
    return Lead(
      id: map['id']! as int,
      name: map['name']! as String,
      phone: map['phone']! as String,
      phoneNormalized: map['phone_normalized'] as String?,
      company: map['company'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      source: map['source'] as String?,
      status: enumFromDb(LeadStatus.values, map['status']),
      temperature: enumFromDb(LeadTemperature.values, map['temperature']),
      notes: map['notes'] as String?,
      createdAt: dateFromDb(map['created_at']),
      updatedAt: dateFromDb(map['updated_at']),
      deletedAt: dateFromDbOrNull(map['deleted_at']),
    );
  }

  final int id;
  final String name;

  /// Exactly as typed or imported.
  final String phone;

  /// E.164 lookup key; null when the number couldn't be normalised.
  final String? phoneNormalized;
  final String? company;
  final String? email;
  final String? website;
  final String? source;
  final LeadStatus status;
  final LeadTemperature temperature;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when soft-deleted.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Nullable fields take a getter so they can be cleared:
  /// `lead.copyWith(company: () => null)`.
  Lead copyWith({
    String? name,
    String? phone,
    ValueGetter<String?>? phoneNormalized,
    ValueGetter<String?>? company,
    ValueGetter<String?>? email,
    ValueGetter<String?>? website,
    ValueGetter<String?>? source,
    LeadStatus? status,
    LeadTemperature? temperature,
    ValueGetter<String?>? notes,
  }) {
    return Lead(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneNormalized: phoneNormalized != null
          ? phoneNormalized()
          : this.phoneNormalized,
      company: company != null ? company() : this.company,
      email: email != null ? email() : this.email,
      website: website != null ? website() : this.website,
      source: source != null ? source() : this.source,
      status: status ?? this.status,
      temperature: temperature ?? this.temperature,
      notes: notes != null ? notes() : this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Editable columns (timestamps are set by the repository).
  Map<String, Object?> toEditableMap() => {
    'name': name,
    'phone': phone,
    'phone_normalized': phoneNormalized,
    'company': company,
    'email': email,
    'website': website,
    'source': source,
    'status': status.dbValue,
    'temperature': temperature.dbValue,
    'notes': notes,
  };
}

/// Data for a new lead.
@immutable
class LeadDraft {
  const LeadDraft({
    required this.name,
    required this.phone,
    this.phoneNormalized,
    this.company,
    this.email,
    this.website,
    this.source,
    this.status = LeadStatus.newLead,
    this.temperature = LeadTemperature.unrated,
    this.notes,
  });

  final String name;
  final String phone;
  final String? phoneNormalized;
  final String? company;
  final String? email;
  final String? website;
  final String? source;
  final LeadStatus status;
  final LeadTemperature temperature;
  final String? notes;

  Map<String, Object?> toMap() => {
    'name': name,
    'phone': phone,
    'phone_normalized': phoneNormalized,
    'company': company,
    'email': email,
    'website': website,
    'source': source,
    'status': status.dbValue,
    'temperature': temperature.dbValue,
    'notes': notes,
  };
}

/// Search/filter for the leads list. Value-equal so it can be a provider
/// `family` key.
@immutable
class LeadQuery {
  const LeadQuery({
    this.text,
    this.status,
    this.temperature,
    this.includeDeleted = false,
    this.limit,
    this.offset = 0,
  });

  /// Matches name, company, email, and phone (original or normalised).
  final String? text;
  final LeadStatus? status;
  final LeadTemperature? temperature;
  final bool includeDeleted;
  final int? limit;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is LeadQuery &&
      other.text == text &&
      other.status == status &&
      other.temperature == temperature &&
      other.includeDeleted == includeDeleted &&
      other.limit == limit &&
      other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(text, status, temperature, includeDeleted, limit, offset);
}
