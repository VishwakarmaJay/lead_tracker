import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Placeholder until Milestone 2.
@RoutePage()
class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: const AppEmptyWidget(
        icon: Icons.call_outlined,
        title: 'Coming soon',
        message: 'Your call history and notes.',
      ),
    );
  }
}
