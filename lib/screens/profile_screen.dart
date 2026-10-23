import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/mock_api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/view_state.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _edit(UserProfile p) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _EditDialog(profile: p));
    if (saved == true && mounted) showSnack(context, 'Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();
    final bp = context.watch<BookingsProvider>();

    Widget body;
    if (pp.state == ViewState.error) {
      body = ErrorView(message: pp.error ?? 'Please try again.', onRetry: pp.load);
    } else if (pp.profile == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final p = pp.profile!;
      body = ContentWidth(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.teal,
                child: Text(p.initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(p.email, style: const TextStyle(color: Colors.white70)),
                  Text('+91 ${p.phone}', style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              IconButton(
                onPressed: () => _edit(p),
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                tooltip: 'Edit profile',
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Stat(label: 'Total bookings', value: '${bp.bookings.length}')),
            const SizedBox(width: 12),
            Expanded(child: _Stat(label: 'Upcoming', value: '${bp.upcoming.length}')),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              SwitchListTile(
                value: MockApiClient.instance.simulateFailure,
                onChanged: (v) {
                  setState(() => MockApiClient.instance.simulateFailure = v);
                  showSnack(context, v ? 'Every request will now fail (503)' : 'Network back to normal');
                },
                title: const Text('Simulate network errors', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Developer option: test error and retry states'),
                activeColor: AppColors.teal,
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('Mock API documentation'),
                subtitle: Text('See docs/API.md in the repository'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('StayScape'),
                subtitle: Text('Version 1.0.0'),
              ),
            ]),
          ),
        ]),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        ),
        Expanded(child: body),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ]),
      );
}

class _EditDialog extends StatefulWidget {
  final UserProfile profile;
  const _EditDialog({required this.profile});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _phone = TextEditingController(text: widget.profile.phone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final pp = context.read<ProfileProvider>();
    final err = await pp.save(UserProfile(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim()));
    if (!mounted) return;
    if (err != null) {
      showSnack(context, err, error: true);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileProvider>().saving;
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: Validators.name),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'Mobile number', counterText: ''),
              validator: Validators.phone,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}
