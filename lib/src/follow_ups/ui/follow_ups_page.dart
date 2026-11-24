import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Placeholder until Milestone 6.
@RoutePage()
class FollowUpsPage extends StatelessWidget {
  const FollowUpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-ups')),
      body: const AppEmptyWidget(
        icon: Icons.event_outlined,
        title: 'Coming soon',
        message: 'Follow-ups due today, overdue, and upcoming.',
      ),
    );
  }
}
