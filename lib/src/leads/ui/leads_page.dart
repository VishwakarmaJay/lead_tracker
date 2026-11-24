import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_list_provider.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_filter_bar.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_tile.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';

@RoutePage()
class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(leadListFilterProvider).text ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    setState(() {}); // show/hide the clear button
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(leadListFilterProvider.notifier).setText(text),
    );
  }

  void _clearSearch() {
    _search.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(leadListProvider);
    final filter = ref.watch(leadListFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(
            tooltip: 'Import from Excel or CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.router.push(const ImportRoute()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-lead',
        onPressed: () => context.router.push(LeadFormRoute()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add lead'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search name, company, email, phone',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
              ),
            ),
          ),
          const LeadFilterBar(),
          Expanded(
            child: leads.unfold(
              (items) => items.isEmpty
                  ? _EmptyLeads(filtered: _isFiltered(filter))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final lead = items[index];
                        return LeadTile(key: ValueKey(lead.id), lead: lead);
                      },
                    ),
              onRetry: () => ref.invalidate(leadListProvider),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isFiltered(LeadQuery query) =>
      query.text != null || query.status != null || query.temperature != null;
}

class _EmptyLeads extends ConsumerWidget {
  const _EmptyLeads({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filtered) {
      return AppEmptyWidget(
        icon: Icons.filter_alt_off_outlined,
        title: 'No leads match',
        message: 'Try another search or clear the filters.',
        action: OutlinedButton(
          onPressed: () =>
              ref.read(leadListFilterProvider.notifier).clearFilters(),
          child: const Text('Clear filters'),
        ),
      );
    }
    return AppEmptyWidget(
      icon: Icons.people_outline,
      title: 'No leads yet',
      message: 'Add a prospect, or import a list from Excel or CSV.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: () => context.router.push(LeadFormRoute()),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add lead'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.router.push(const ImportRoute()),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
