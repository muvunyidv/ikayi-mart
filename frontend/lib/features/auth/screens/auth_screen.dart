import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/password_rules.dart';
import '../../../core/utils/rwanda_phone.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/auth_state.dart';
import '../../../state/navigation_state.dart';
import '../../vendor/widgets/google_sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.vendorContext = false});

  /// When true, registration creates a vendor store account.
  final bool vendorContext;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _storeName = TextEditingController();
  final _storeDescription = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;
  bool _registering = false;
  late bool _vendorRegister;

  @override
  void initState() {
    super.initState();
    _vendorRegister = widget.vendorContext;
    _password.addListener(_onPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfLoggedIn());
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _name.dispose();
    _storeName.dispose();
    _storeDescription.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (_registering) setState(() {});
  }

  void _redirectIfLoggedIn() {
    if (!mounted) return;
    final auth = context.read<AuthState>();
    if (!auth.isLoggedIn) return;
    _routeAfterAuth(auth);
  }

  void _toggleMode() {
    setState(() {
      _registering = !_registering;
      _vendorRegister = widget.vendorContext;
      _formKey.currentState?.reset();
    });
  }

  void _routeAfterAuth(AuthState auth) {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (auth.user?.isVendorStaff == true) {
      context.read<NavigationState>().setMode(AppMode.vendor);
      context.go('/vendor');
      return;
    }
    context.read<NavigationState>().setMode(AppMode.shopper);
    if (next != null && next.startsWith('/') && next != '/login') {
      context.go(next);
      return;
    }
    context.go('/');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final ok = _registering
        ? _vendorRegister
              ? await auth.registerVendor(
                  email: _email.text.trim(),
                  password: _password.text,
                  name: _name.text.trim(),
                  storeName: _storeName.text.trim(),
                  phone:
                      normalizeRwandaPhone(_phone.text) ?? _phone.text.trim(),
                  description: _storeDescription.text.trim().isEmpty
                      ? null
                      : _storeDescription.text.trim(),
                )
              : await auth.register(
                  email: _email.text.trim(),
                  password: _password.text,
                  name: _name.text.trim(),
                  phone:
                      normalizeRwandaPhone(_phone.text) ?? _phone.text.trim(),
                )
        : await auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ??
                (_registering ? 'Registration failed' : 'Login failed'),
          ),
        ),
      );
      return;
    }
    _routeAfterAuth(auth);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleBusy = true);
    final auth = context.read<AuthState>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (!ok) {
      if (auth.error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
      return;
    }
    _routeAfterAuth(auth);
  }

  @override
  Widget build(BuildContext context) {
    final title = _registering
        ? (_vendorRegister ? 'Create vendor account' : 'Create account')
        : (widget.vendorContext ? 'Vendor login' : 'Sign in');
    final subtitle = _registering
        ? (_vendorRegister
              ? 'Register your store to list products and manage orders.'
              : 'Save addresses, track orders, and check out faster next time.')
        : (widget.vendorContext
              ? 'Sign in to manage inventory, orders, and payouts.'
              : 'Sign in to track orders and use saved checkout details.');

    return ImigongoBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.vendorContext
            ? AppBar(
                title: const Text('Vendor Central'),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.read<NavigationState>().setMode(AppMode.shopper);
                      context.go('/');
                    },
                    child: const Text('Shop'),
                  ),
                ],
              )
            : null,
        body: Center(
          child: SingleChildScrollView(
            primary: true,
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
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.secondary),
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
                            if (_vendorRegister && widget.vendorContext) ...[
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
                              TextFormField(
                                controller: _storeDescription,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                maxLines: 3,
                                maxLength: 400,
                                decoration: const InputDecoration(
                                  labelText: 'Store bio (optional)',
                                  hintText:
                                      'Tell shoppers what your store is known for.',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                hintText: '+250 7XX XXX XXX',
                                helperText:
                                    'Rwandan mobile (MTN 78/79, Airtel 72/73)',
                              ),
                              validator: rwandaPhoneValidator,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
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
                            onFieldSubmitted: _registering || _busy
                                ? null
                                : (_) => _submit(),
                            validator: _registering
                                ? PasswordRules.validator
                                : (v) => (v == null || v.length < 8)
                                      ? 'Min 8 characters'
                                      : null,
                          ),
                          if (_registering)
                            PasswordStrengthMeter(password: _password.text),
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
                            if (!widget.vendorContext) ...[
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _vendorRegister,
                                onChanged: (v) => setState(
                                  () => _vendorRegister = v ?? false,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  'I want to sell on IKAYIMART',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (_vendorRegister) ...[
                                TextFormField(
                                  controller: _storeName,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
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
                                TextFormField(
                                  controller: _storeDescription,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  maxLines: 3,
                                  maxLength: 400,
                                  decoration: const InputDecoration(
                                    labelText: 'Store bio (optional)',
                                    hintText:
                                        'Tell shoppers what your store is known for.',
                                  ),
                                ),
                              ],
                            ],
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _busy || _googleBusy ? null : _submit,
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.secondary),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GoogleSignInButton(
                            busy: _googleBusy,
                            onPressed: _busy ? null : _signInWithGoogle,
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
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                              TextButton(
                                onPressed: _busy || _googleBusy
                                    ? null
                                    : _toggleMode,
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
