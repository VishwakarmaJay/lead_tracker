import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/database/db_value.dart';

enum CallSource implements DbValue {
  manual('manual'),
  androidCallLog('android_call_log');

  const CallSource(this.dbValue);

  @override
  final String dbValue;
}

enum CallType implements DbValue {
  incoming('incoming'),
  outgoing('outgoing'),
  missed('missed'),
  rejected('rejected'),
  blocked('blocked'),
  unknown('unknown');

  const CallType(this.dbValue);

  @override
  final String dbValue;
}

/// What happened on the call, chosen by the user. Never inferred from call
/// type or duration.
enum CallDisposition implements DbValue {
  connected('connected'),
  interested('interested'),
  followUp('follow_up'),
  notInterested('not_interested'),
  noAnswer('no_answer'),
  busy('busy'),
  wrongNumber('wrong_number'),
  other('other');

  const CallDisposition(this.dbValue);

  @override
  final String dbValue;
}

/// A row in `call_logs`.
@immutable
class CallLog {
  const CallLog({
    required this.id,
    required this.source,
    required this.callType,
    required this.durationSeconds,
    required this.calledAt,
    required this.createdAt,
    required this.updatedAt,
    this.leadId,
    this.sourceRecordId,
    this.phone,
    this.phoneNormalized,
    this.displayName,
    this.disposition,
    this.summary,
  });

  factory CallLog.fromMap(Map<String, Object?> map) {
    return CallLog(
      id: map['id']! as int,
      leadId: map['lead_id'] as int?,
      source: enumFromDb(CallSource.values, map['source']),
      sourceRecordId: map['source_record_id'] as String?,
      phone: map['phone'] as String?,
      phoneNormalized: map['phone_normalized'] as String?,
      displayName: map['display_name'] as String?,
      callType: enumFromDb(CallType.values, map['call_type']),
      durationSeconds: map['duration_seconds']! as int,
      disposition: enumFromDbOrNull(CallDisposition.values, map['disposition']),
      summary: map['summary'] as String?,
      calledAt: dateFromDb(map['called_at']),
      createdAt: dateFromDb(map['created_at']),
      updatedAt: dateFromDb(map['updated_at']),
    );
  }

  final int id;

  /// Null for an unmatched system call; the user can link it later.
  final int? leadId;
  final CallSource source;

  /// Android call-log id for system calls; null for manual entries.
  final String? sourceRecordId;
  final String? phone;
  final String? phoneNormalized;
  final String? displayName;
  final CallType callType;
  final int durationSeconds;
  final CallDisposition? disposition;
  final String? summary;
  final DateTime calledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallLog copyWith({
    ValueGetter<int?>? leadId,
    ValueGetter<String?>? phone,
    ValueGetter<String?>? phoneNormalized,
    ValueGetter<String?>? displayName,
    CallType? callType,
    int? durationSeconds,
    ValueGetter<CallDisposition?>? disposition,
    ValueGetter<String?>? summary,
    DateTime? calledAt,
  }) {
    return CallLog(
      id: id,
      leadId: leadId != null ? leadId() : this.leadId,
      source: source,
      sourceRecordId: sourceRecordId,
      phone: phone != null ? phone() : this.phone,
      phoneNormalized: phoneNormalized != null
          ? phoneNormalized()
          : this.phoneNormalized,
      displayName: displayName != null ? displayName() : this.displayName,
      callType: callType ?? this.callType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      disposition: disposition != null ? disposition() : this.disposition,
      summary: summary != null ? summary() : this.summary,
      calledAt: calledAt ?? this.calledAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toEditableMap() => {
    'lead_id': leadId,
    'phone': phone,
    'phone_normalized': phoneNormalized,
    'display_name': displayName,
    'call_type': callType.dbValue,
    'duration_seconds': durationSeconds,
    'disposition': disposition?.dbValue,
    'summary': summary,
    'called_at': calledAt.toDb(),
  };
}

/// Data for a new call log.
@immutable
class CallLogDraft {
  const CallLogDraft({
    required this.calledAt,
    this.leadId,
    this.source = CallSource.manual,
    this.sourceRecordId,
    this.phone,
    this.phoneNormalized,
    this.displayName,
    this.callType = CallType.unknown,
    this.durationSeconds = 0,
    this.disposition,
    this.summary,
  });

  final int? leadId;
  final CallSource source;
  final String? sourceRecordId;
  final String? phone;
  final String? phoneNormalized;
  final String? displayName;
  final CallType callType;
  final int durationSeconds;
  final CallDisposition? disposition;
  final String? summary;
  final DateTime calledAt;

  Map<String, Object?> toMap() => {
    'lead_id': leadId,
    'source': source.dbValue,
    'source_record_id': sourceRecordId,
    'phone': phone,
    'phone_normalized': phoneNormalized,
    'display_name': displayName,
    'call_type': callType.dbValue,
    'duration_seconds': durationSeconds,
    'disposition': disposition?.dbValue,
    'summary': summary,
    'called_at': calledAt.toDb(),
  };
}
