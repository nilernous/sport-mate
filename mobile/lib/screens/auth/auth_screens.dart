import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.sports_soccer, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                child,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error banner for forms.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.error_outline, color: scheme.onErrorContainer),
        const SizedBox(width: 8),
        Expanded(child: Text(message!, style: TextStyle(color: scheme.onErrorContainer))),
      ]),
    );
  }
}

// ---------- UC-002 Sign in ----------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      // The router redirects to `from` (or the role's home) once the session changes.
      await ref.read(authProvider.notifier).login(_email.text, _password.text);
    } catch (e) {
      setState(() => _error = AppException.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from == null ? '' : '?from=${Uri.encodeComponent(widget.from!)}';
    return _AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to shop, track orders and save favourites.',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FormErrorBanner(_error),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => Validators.required(v, 'Password'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Forgot password?')),
            ),
            const SizedBox(height: 8),
            BusyButton(label: 'Sign in', onPressed: _submit),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account?"),
              TextButton(onPressed: () => context.pushReplacement('/register$from'), child: const Text('Create one')),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ---------- UC-001 Register ----------

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  AppException? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await ref.read(authProvider.notifier).register(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            phoneNumber: _phone.text,
          );
    } catch (e) {
      setState(() => _error = AppException.from(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from == null ? '' : '?from=${Uri.encodeComponent(widget.from!)}';
    return _AuthScaffold(
      title: 'Create your account',
      subtitle: 'Join Sport Mate to start shopping.',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FormErrorBanner(_error?.message),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: 'Full name', prefixIcon: const Icon(Icons.person_outline), errorText: _error?.fieldError('fullName')),
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Full name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), errorText: _error?.fieldError('email')),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: 'At least 8 characters with a letter and a digit',
              errorText: _error?.fieldError('password'),
            ),
            obscureText: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true,
            validator: (v) => v != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          BusyButton(label: 'Create account', onPressed: _submit),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account?'),
            TextButton(onPressed: () => context.pushReplacement('/login$from'), child: const Text('Sign in')),
          ]),
        ]),
      ),
    );
  }
}

// ---------- UC-004 Request password reset ----------

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _sentMessage;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    try {
      final message = await ref.read(authServiceProvider).forgotPassword(_email.text);
      setState(() => _sentMessage = message);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Forgot password',
        subtitle: 'Enter your email and we will send you a reset code.',
        child: _sentMessage != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_sentMessage!))),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => context.pushReplacement('/reset-password'), child: const Text('I have a reset code')),
              ])
            : Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),
                  BusyButton(label: 'Send reset code', onPressed: _submit),
                  TextButton(onPressed: () => context.pushReplacement('/reset-password'), child: const Text('I already have a code')),
                ]),
              ),
      );
}

// ---------- UC-005 Reset password with token ----------

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final message = await ref.read(authServiceProvider).resetPassword(_token.text, _password.text);
      if (!mounted) return;
      showMessage(context, message);
      context.go('/login');
    } catch (e) {
      setState(() => _error = AppException.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        title: 'Reset password',
        subtitle: 'Enter the reset code you received and choose a new password.',
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FormErrorBanner(_error),
            TextFormField(
              controller: _token,
              decoration: const InputDecoration(labelText: 'Reset code', prefixIcon: Icon(Icons.key_outlined)),
              validator: (v) => Validators.required(v, 'Reset code'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Reset password', onPressed: _submit),
          ]),
        ),
      );
}
