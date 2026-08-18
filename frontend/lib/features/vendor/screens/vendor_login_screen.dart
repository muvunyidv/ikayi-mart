import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/auth_state.dart';
import '../../../state/navigation_state.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _storeName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _registering = false;

  @override
  void dispose() {
    _name.dispose();
    _storeName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _registering = !_registering;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final ok = _registering
        ? await auth.register(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            storeName: _storeName.text.trim(),
          )
        : await auth.login(
            email: _email.text.trim(),
            password: _password.text,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? (_registering ? 'Registration failed' : 'Login failed'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImigongoBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Vendor Central'),
          actions: [
            TextButton(
              onPressed: () =>
                  context.read<NavigationState>().setMode(AppMode.shopper),
              child: const Text('Shop'),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _registering ? 'Create vendor account' : 'Vendor login',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _registering
                                ? 'Register your store to list products and manage orders.'
                                : 'Sign in to manage inventory, orders, and payouts.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondary,
                                ),
                          ),
                          const SizedBox(height: 24),
                          if (_registering) ...[
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Your name',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Enter your name'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _storeName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.organizationName,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Store name',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Enter a store name'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              _registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            onFieldSubmitted:
                                _registering || _busy ? null : (_) => _submit(),
                            validator: (v) => (v == null || v.length < 8)
                                ? 'Min 8 characters'
                                : null,
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                              ),
                              onFieldSubmitted: _busy ? null : (_) => _submit(),
                              validator: (v) => v != _password.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _registering ? 'Create account' : 'Sign in',
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _registering
                                    ? 'Already have an account?'
                                    : "Don't have an account?",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                              TextButton(
                                onPressed: _busy ? null : _toggleMode,
                                child: Text(
                                  _registering
                                      ? 'Sign in'
                                      : 'Create an account',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
