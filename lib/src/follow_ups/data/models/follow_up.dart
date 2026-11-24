import 'package:flutter/foundation.dart';
import 'package:lead_tracker/core/database/db_value.dart';

enum FollowUpStatus implements DbValue {
  pending('pending'),
  completed('completed'),
  cancelled('cancelled');

  const FollowUpStatus(this.dbValue);

  @override
  final String dbValue;
}

/// A row in `follow_ups`.
@immutable
class FollowUp {
  const FollowUp({
    required this.id,
    required this.leadId,
    required this.title,
    required this.dueAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.notificationId,
    this.completedAt,
  });

  factory FollowUp.fromMap(Map<String, Object?> map) {
    return FollowUp(
      id: map['id']! as int,
      leadId: map['lead_id']! as int,
      title: map['title']! as String,
      note: map['note'] as String?,
      dueAt: dateFromDb(map['due_at']),
      status: enumFromDb(FollowUpStatus.values, map['status']),
      notificationId: map['notification_id'] as int?,
      createdAt: dateFromDb(map['created_at']),
      updatedAt: dateFromDb(map['updated_at']),
      completedAt: dateFromDbOrNull(map['completed_at']),
    );
  }

  final int id;
  final int leadId;
  final String title;
  final String? note;
  final DateTime dueAt;
  final FollowUpStatus status;

  /// Id of the scheduled local notification (Milestone 6).
  final int? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool isOverdueAt(DateTime now) =>
      status == FollowUpStatus.pending && dueAt.isBefore(now);

  FollowUp copyWith({
    String? title,
    ValueGetter<String?>? note,
    DateTime? dueAt,
  }) {
    return FollowUp(
      id: id,
      leadId: leadId,
      title: title ?? this.title,
      note: note != null ? note() : this.note,
      dueAt: dueAt ?? this.dueAt,
      status: status,
      notificationId: notificationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}

/// Data for a new follow-up.
@immutable
class FollowUpDraft {
  const FollowUpDraft({
    required this.leadId,
    required this.title,
    required this.dueAt,
    this.note,
  });

  final int leadId;
  final String title;
  final String? note;
  final DateTime dueAt;

  Map<String, Object?> toMap() => {
    'lead_id': leadId,
    'title': title,
    'note': note,
    'due_at': dueAt.toDb(),
  };
}
