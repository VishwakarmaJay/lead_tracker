import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ProviderScope(
      // Same as hedged: no automatic provider retries. Failures surface as
      // error states with an explicit Retry.
      retry: (retryCount, error) => null,
      child: const App(),
    ),
  );
}
