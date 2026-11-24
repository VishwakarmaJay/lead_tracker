import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Placeholder until Milestone 2.
@RoutePage()
class LeadsPage extends StatelessWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leads')),
      body: const AppEmptyWidget(
        icon: Icons.people_outline,
        title: 'Coming soon',
        message: 'Add, import, search, and call your leads.',
      ),
    );
  }
}
