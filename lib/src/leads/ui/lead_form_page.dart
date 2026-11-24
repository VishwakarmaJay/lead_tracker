import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lead_tracker/core/error/app_exception.dart';
import 'package:lead_tracker/core/extension/async_value.dart';
import 'package:lead_tracker/core/extension/context.dart';
import 'package:lead_tracker/src/leads/data/models/lead.dart';
import 'package:lead_tracker/src/leads/providers/lead_detail_provider.dart';
import 'package:lead_tracker/src/leads/providers/lead_form_provider.dart';
import 'package:lead_tracker/src/leads/ui/components/lead_labels.dart';
import 'package:lead_tracker/src/routes/app_router.gr.dart';
import 'package:lead_tracker/src/shared/components/app_confirmation.dart';
import 'package:lead_tracker/src/shared/components/app_empty_widget.dart';
import 'package:lead_tracker/src/shared/components/app_snack_bar.dart';
import 'package:lead_tracker/src/shared/providers/phone_normalizer_provider.dart';

/// Add a lead (no [leadId]) or edit one.
@RoutePage()
class LeadFormPage extends ConsumerWidget {
  const LeadFormPage({this.leadId, super.key});

  final int? leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = leadId;
    if (id == null) {
      return const _LeadForm();
    }
    return ref
        .watch(leadDetailProvider(id))
        .unfold(
          (lead) => lead == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const AppEmptyWidget(
                    icon: Icons.person_off_outlined,
                    title: 'This lead no longer exists',
                  ),
                )
              : _LeadForm(existing: lead),
        );
  }
}

class _LeadForm extends ConsumerStatefulWidget {
  const _LeadForm({this.existing});

  final Lead? existing;

  @override
  ConsumerState<_LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends ConsumerState<_LeadForm> {
  final _formKey = GlobalKey<FormState>();
  late final LeadFormInput _initial;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _source;
  late final TextEditingController _notes;
  late LeadStatus _status;
  late LeadTemperature _temperature;

  /// Set once saved, so leaving the screen doesn't ask to discard.
  bool _saved = false;

  /// After the first Save attempt, fields re-check as the user types so
  /// errors clear as soon as they're fixed.
  bool _triedToSave = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _initial = existing == null
        ? const LeadFormInput(name: '', phone: '')
        : LeadFormInput.fromLead(existing);
    _name = TextEditingController(text: _initial.name);
    _phone = TextEditingController(text: _initial.phone);
    _company = TextEditingController(text: _initial.company);
    _email = TextEditingController(text: _initial.email);
    _website = TextEditingController(text: _initial.website);
    _source = TextEditingController(text: _initial.source);
    _notes = TextEditingController(text: _initial.notes);
    _status = _initial.status;
    _temperature = _initial.temperature;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _company,
      _email,
      _website,
      _source,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  LeadFormInput get _input => LeadFormInput(
    name: _name.text,
    phone: _phone.text,
    company: _company.text,
    email: _email.text,
    website: _website.text,
    source: _source.text,
    notes: _notes.text,
    status: _status,
    temperature: _temperature,
  );

  bool get _isDirty {
    final now = _input;
    return now.name != _initial.name ||
        now.phone != _initial.phone ||
        now.company != _initial.company ||
        now.email != _initial.email ||
        now.website != _initial.website ||
        now.source != _initial.source ||
        now.notes != _initial.notes ||
        now.status != _initial.status ||
        now.temperature != _initial.temperature;
  }

  Future<void> _save() async {
    if (!_triedToSave) {
      setState(() => _triedToSave = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final editor = ref.read(leadEditorProvider.notifier);
    final phone = _phone.text;

    if (!editor.isPhoneRecognised(phone)) {
      final keep = await showAppConfirmation(
        context,
        title: "Can't recognise this number",
        message:
            "The lead will be saved as typed, but it won't be matched "
            'to calls or recordings automatically.',
        confirmLabel: 'Save anyway',
      );
      if (!keep) {
        return;
      }
    } else if (phone.trim() != _initial.phone.trim() || !_isEdit) {
      final duplicates = await editor.findDuplicates(
        phone,
        exceptLeadId: widget.existing?.id,
      );
      if (duplicates.isNotEmpty && mounted) {
        final names = duplicates.map((l) => l.name).take(3).join(', ');
        final keep = await showAppConfirmation(
          context,
          title: 'Number already saved',
          message:
              'This number belongs to: $names. Save another lead with '
              'the same number?',
          confirmLabel: 'Save anyway',
        );
        if (!keep) {
          return;
        }
      }
    }

    try {
      final id = await editor.save(_input, existing: widget.existing);
      if (!mounted) {
        return;
      }
      setState(() => _saved = true);
      if (_isEdit) {
        await context.router.maybePop();
      } else {
        await context.router.replace(LeadDetailRoute(leadId: id));
      }
    } on AppException catch (e) {
      e.message.showSnackBar();
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAppConfirmation(
      context,
      title: 'Discard changes?',
      message: 'Your changes to this lead will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(leadEditorProvider);
    final normalizer = ref.watch(phoneNormalizerProvider);

    return PopScope(
      canPop: _saved || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit lead' : 'Add lead'),
          actions: [
            TextButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _triedToSave
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          onChanged: () => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: maxLeadNameLength,
                validator: validateLeadName,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: validateLeadPhone,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  border: const OutlineInputBorder(),
                  helperText: _phoneHelper(normalizer.normalize(_phone.text)),
                  helperStyle:
                      normalizer.isValid(_phone.text) ||
                          _phone.text.trim().isEmpty
                      ? null
                      : TextStyle(color: context.colors.warning),
                ),
              ),
              const SizedBox(height: 16),
              _field(_company, 'Company', TextCapitalization.words),
              _field(
                _email,
                'Email',
                TextCapitalization.none,
                keyboard: TextInputType.emailAddress,
                validator: validateLeadEmail,
              ),
              _field(
                _website,
                'Website',
                TextCapitalization.none,
                keyboard: TextInputType.url,
              ),
              _field(
                _source,
                'Source',
                TextCapitalization.sentences,
                hint: 'Where you found them, e.g. LinkedIn',
              ),
              Text('Status', style: context.text.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<LeadStatus>(
                initialValue: _status,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final status in LeadStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 16),
              Text('Temperature', style: context.text.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final temperature in LeadTemperature.values)
                    ChoiceChip(
                      avatar: Icon(
                        temperature.icon,
                        size: 18,
                        color: temperature.color(context),
                      ),
                      label: Text(temperature.label),
                      selected: _temperature == temperature,
                      onSelected: (_) =>
                          setState(() => _temperature = temperature),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String? _phoneHelper(String? normalized) {
    if (_phone.text.trim().isEmpty) {
      return null;
    }
    return normalized == null
        ? "Can't recognise this number — it won't be matched automatically."
        : 'Saved for matching as $normalized';
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextCapitalization capitalization, {
    TextInputType? keyboard,
    String? hint,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: capitalization,
        textInputAction: TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
