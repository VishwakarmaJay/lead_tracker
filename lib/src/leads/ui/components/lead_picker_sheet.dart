import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

/// Lets the user pick one lead. Returns null when dismissed.
///
/// Public: used by the Calls tab and (Milestone 4) recording import.
Future<Lead?> showLeadPicker(
  BuildContext context, {
  String title = 'Choose a lead',
}) {
  return showModalBottomSheet<Lead>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LeadPicker(title: title),
  );
}

class _LeadPicker extends ConsumerStatefulWidget {
  const _LeadPicker({required this.title});

  final String title;

  @override
  ConsumerState<_LeadPicker> createState() => _LeadPickerState();
}

class _LeadPickerState extends ConsumerState<_LeadPicker> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => setState(() => _query = text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(leadSearchProvider(_query));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: context.text.title),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: _onChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Name, company, or phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.unfold(
                (leads) => leads.isEmpty
                    ? const AppEmptyWidget(
                        icon: Icons.person_search_outlined,
                        title: 'No matching leads',
                      )
                    : ListView.builder(
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          final lead = leads[index];
                          return ListTile(
                            key: ValueKey(lead.id),
                            leading: LeadAvatar(lead: lead),
                            title: Text(lead.name),
                            subtitle: Text(
                              [
                                lead.company,
                                lead.phone,
                              ].whereType<String>().join(' · '),
                            ),
                            onTap: () => Navigator.of(context).pop(lead),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
