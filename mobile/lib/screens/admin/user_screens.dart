import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

/// User management list (UC-014). Admin only.
class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String? _keyword;
  UserRole? _role;
  int _version = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Users')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/admin/users/new');
            setState(() => _version++);
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('New user'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search name, email or phone', prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('All'), selected: _role == null, onSelected: (_) => setState(() => _role = null)),
              for (final r in UserRole.values) ChoiceChip(label: Text(r.label), selected: _role == r, onSelected: (_) => setState(() => _role = r)),
            ]),
          ),
          Expanded(
            child: PagedListView<AdminUser>(
              queryKey: (_keyword, _role, _version),
              fetch: (page) => ref.read(adminServiceProvider).users(keyword: _keyword, role: _role, page: page),
              emptyMessage: 'No users found.',
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              itemBuilder: (context, u, reload) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(u.fullName.isEmpty ? '?' : u.fullName[0].toUpperCase())),
                  title: Text(u.fullName),
                  subtitle: Text('${u.email} · ${u.role.label}'),
                  trailing: StatusChip.active(u.isActive),
                  onTap: () async {
                    await context.push('/admin/users/${u.id}');
                    reload();
                  },
                ),
              ),
            ),
          ),
        ]),
      );
}

final _userProvider = FutureProvider.autoDispose.family<AdminUser, int>((ref, id) => ref.watch(adminServiceProvider).user(id));

/// View/edit a user, change role and enable/disable (UC-014 – UC-017).
class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final int userId;

  Future<void> _edit(BuildContext context, WidgetRef ref, AdminUser user) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _EditUserDialog(user: user));
    if (saved == true) ref.invalidate(_userProvider(userId));
  }

  Future<void> _setRole(BuildContext context, WidgetRef ref, AdminUser user, UserRole role) async {
    if (role == user.role) return;
    if (!await confirmDialog(context,
        title: 'Change role',
        message: 'Make ${user.fullName} a ${role.label}? They will need to sign in again.',
        confirmLabel: 'Change role')) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(adminServiceProvider).setUserRole(user.id, role), success: 'Role updated');
    if (ok) ref.invalidate(_userProvider(userId));
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, AdminUser user) async {
    final disable = user.isActive;
    if (!await confirmDialog(context,
        title: disable ? 'Disable account' : 'Enable account',
        message: disable
            ? '${user.fullName} will be signed out and cannot sign in. Their orders are kept.'
            : '${user.fullName} will be able to sign in again.',
        confirmLabel: disable ? 'Disable' : 'Enable',
        destructive: disable)) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(adminServiceProvider).setUserActive(user.id, !disable),
        success: disable ? 'Account disabled' : 'Account enabled');
    if (ok) ref.invalidate(_userProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(_userProvider(userId));
    final isSelf = ref.watch(authProvider).user?.id == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: AsyncValueView(
        value: user,
        onRetry: () => ref.invalidate(_userProvider(userId)),
        data: (u) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(u.fullName, style: Theme.of(context).textTheme.titleLarge)),
                  StatusChip.active(u.isActive),
                ]),
                const SizedBox(height: 8),
                InfoRow('Email', u.email),
                InfoRow('Phone', u.phoneNumber ?? '-'),
                InfoRow('Member since', formatDate(u.createdAt)),
                InfoRow('Orders', '${u.orderCount ?? 0}'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(onPressed: () => _edit(context, ref, u), icon: const Icon(Icons.edit_outlined), label: const Text('Edit info')),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Role', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<UserRole>(
                  segments: [for (final r in UserRole.values) ButtonSegment(value: r, label: Text(r.label))],
                  selected: {u.role},
                  onSelectionChanged: isSelf ? null : (s) => _setRole(context, ref, u, s.first),
                ),
                if (isSelf) const Padding(padding: EdgeInsets.only(top: 8), child: Text('You cannot change your own role or status.', style: TextStyle(fontSize: 12))),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: u.isActive ? OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error) : null,
                  onPressed: isSelf ? null : () => _toggleActive(context, ref, u),
                  icon: Icon(u.isActive ? Icons.block : Icons.check_circle_outline),
                  label: Text(u.isActive ? 'Disable account' : 'Enable account'),
                ),
              ]),
            ),
          ),
          if (u.addresses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text('Addresses', style: Theme.of(context).textTheme.titleMedium)),
                for (final a in u.addresses)
                  ListTile(leading: const Icon(Icons.location_on_outlined), title: Text('${a.recipientName} · ${a.phoneNumber}'), subtitle: Text(a.fullAddress)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.user});

  final AdminUser user;

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phoneNumber);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(
      context,
      () => ref.read(adminServiceProvider).updateUser(widget.user.id, {
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'phoneNumber': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      }),
      success: 'User updated',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit user'),
        content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => Validators.required(v, 'Full name')),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: Validators.email),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: Validators.phone),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          BusyButton(label: 'Save', onPressed: _save),
        ],
      );
}

/// Create an account with any role (UC-013).
class UserCreateScreen extends ConsumerStatefulWidget {
  const UserCreateScreen({super.key});

  @override
  ConsumerState<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends ConsumerState<UserCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.staff;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await runGuarded(
      context,
      () => ref.read(adminServiceProvider).createUser({
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'phoneNumber': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'password': _password.text,
        'role': _role.apiName,
      }),
      success: 'User created',
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New user')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => Validators.required(v, 'Full name')),
            const SizedBox(height: 16),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: Validators.email),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone, validator: Validators.phone),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Initial password', helperText: 'Share it securely; the user can change it later'),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            Text('Role', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<UserRole>(
              segments: [for (final r in UserRole.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Create user', onPressed: _save),
          ]),
        ),
      );
}
