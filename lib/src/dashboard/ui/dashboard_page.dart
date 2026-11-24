import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Placeholder until Milestone 7.
@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const AppEmptyWidget(
        icon: Icons.dashboard_outlined,
        title: 'Coming soon',
        message: 'A summary of leads, calls, and follow-ups.',
      ),
    );
  }
}
