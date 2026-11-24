import 'package:lead_tracker/core/database/app_database.dart';
import 'package:lead_tracker/core/database/schema.dart';
import 'package:lead_tracker/core/extension/future.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'app_database_instance.g.dart';

/// The open database for the whole session. `startupProvider` awaits it
/// before the home tabs open, so repositories can use `requireValue`.
@Riverpod(keepAlive: true)
Future<Database> appDatabase(Ref ref) async {
  final directory = await getDatabasesPath().guard();
  final db = await openAppDatabase(
    factory: databaseFactory,
    path: p.join(directory, databaseFileName),
  ).guard();
  ref.onDispose(db.close);
  return db;
}
