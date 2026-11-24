import 'package:lead_tracker/src/leads/data/lead_repository.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inserts a lead and returns its id.
Future<int> insertLead(Database db, {String name = 'Asha'}) {
  return LeadRepository(db).createLead(
    LeadDraft(
      name: name,
      phone: '9876543210',
      phoneNormalized: '+919876543210',
    ),
  );
}

/// Hard-deletes a lead with raw SQL, to exercise the foreign-key rules.
/// The app itself only soft-deletes.
Future<int> hardDeleteLead(Database db, int id) =>
    db.delete('leads', where: 'id = ?', whereArgs: [id]);
