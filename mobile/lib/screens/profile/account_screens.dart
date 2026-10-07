import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';
import '../auth/auth_screens.dart';

/// Account tab: sign-in prompt for guests, profile and shortcuts for signed-in users.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: EmptyView(
          icon: Icons.person_outline,
          message: 'Sign in to view your orders, wishlist and addresses.',
          action: Column(children: [
            FilledButton(onPressed: () => context.push('/login?from=/account'), child: const Text('Sign in')),
            TextButton(onPressed: () => context.push('/register?from=/account'), child: const Text('Create an account')),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          leading: CircleAvatar(radius: 28, child: Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(), style: theme.textTheme.titleLarge)),
          title: Text(user.fullName, style: theme.textTheme.titleMedium),
          subtitle: Text('${user.email}${user.phoneNumber == null ? '' : '\n${user.phoneNumber}'}'),
          isThreeLine: user.phoneNumber != null,
          trailing: user.role == UserRole.customer ? null : Chip(label: Text(user.role.label)),
        ),
        const Divider(),
        if (auth.isCustomer) ...[
          _MenuTile(Icons.location_on_outlined, 'Delivery addresses', '/addresses'),
        ],
        if (auth.isStaffOrAdmin) _MenuTile(Icons.dashboard_outlined, 'Admin Panel', '/admin', go: true),
        _MenuTile(Icons.edit_outlined, 'Edit profile', '/account/edit'),
        _MenuTile(Icons.lock_outline, 'Change password', '/account/password'),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text('Sign out', style: TextStyle(color: theme.colorScheme.error)),
          onTap: () async {
            if (await confirmDialog(context, title: 'Sign out', message: 'Do you want to sign out?', confirmLabel: 'Sign out')) {
              await ref.read(authProvider.notifier).logout();
            }
          },
        ),
      ]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.title, this.route, {this.go = false});

  final IconData icon;
  final String title;
  final String route;
  final bool go;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => go ? context.go(route) : context.push(route),
      );
}

// ---------- UC-008 Update own profile ----------

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: ref.read(authProvider).user?.fullName);
  late final _phone = TextEditingController(text: ref.read(authProvider).user?.phoneNumber);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(context, () => ref.read(authProvider.notifier).updateProfile(fullName: _name.text, phoneNumber: _phone.text),
        success: 'Profile updated');
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            initialValue: user?.email,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Email', helperText: 'Email cannot be changed here'),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => Validators.required(v, 'Full name')),
          const SizedBox(height: 16),
          TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone number'), keyboardType: TextInputType.phone, validator: Validators.phone),
          const SizedBox(height: 24),
          BusyButton(label: 'Save', onPressed: _save),
        ]),
      ),
    );
  }
}

// ---------- UC-006 Change password ----------

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  AppException? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).changePassword(_current.text, _next.text);
      if (!mounted) return;
      showMessage(context, 'Password changed. Other devices have been signed out.');
      context.pop();
    } catch (e) {
      setState(() => _error = AppException.from(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change password')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            FormErrorBanner(_error?.fieldErrors.isEmpty == true ? _error?.message : null),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current password', errorText: _error?.fieldError('currentPassword')),
              validator: (v) => Validators.required(v, 'Current password'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New password', errorText: _error?.fieldError('newPassword')),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (v) => v != _next.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Change password', onPressed: _save),
          ]),
        ),
      );
}
