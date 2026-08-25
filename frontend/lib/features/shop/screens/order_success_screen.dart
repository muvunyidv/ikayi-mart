import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_rules.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/auth_state.dart';
import '../../vendor/widgets/google_sign_in_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.trackingCode,
    required this.email,
    required this.totalRwfLabel,
  });

  final String orderId;
  final String trackingCode;
  final String email;
  final String totalRwfLabel;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  final _password = TextEditingController();
  bool _creating = false;
  bool _googleBusy = false;
  bool _converted = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimIfLoggedIn());
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _password.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  Future<void> _claimIfLoggedIn() async {
    final auth = context.read<AuthState>();
    if (!auth.isLoggedIn || widget.orderId.isEmpty) return;
    try {
      await auth.claimGuestOrder(widget.orderId);
      if (mounted) setState(() => _converted = true);
    } catch (_) {}
  }

  Future<void> _createAccount() async {
    final error = PasswordRules.validator(_password.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _creating = true);
    final auth = context.read<AuthState>();
    final ok = await auth.convertGuest(
      orderId: widget.orderId,
      email: widget.email,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _creating = false;
      _converted = ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Account created. This order is saved to your profile.'
              : auth.error ?? 'Could not create account',
        ),
      ),
    );
  }

  Future<void> _googleConvert() async {
    setState(() => _googleBusy = true);
    final auth = context.read<AuthState>();
    final ok = await auth.loginWithGoogle(orderId: widget.orderId);
    if (!mounted) return;
    setState(() {
      _googleBusy = false;
      _converted = ok;
    });
    if (!ok && auth.error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Account saved. This order is in your history.'
              : auth.error ?? 'Google sign-in failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final width = MediaQuery.sizeOf(context).width;
    final showConvert =
        !auth.isLoggedIn && !_converted && widget.orderId.isNotEmpty;

    return ShopScrollView(
      padding: EdgeInsets.all(width >= kDesktopBreakpoint ? 32 : 16),
      maxContentWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryOrange,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Payment confirmed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Test payment succeeded. Save your tracking code to follow this delivery.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  'YOUR TRACKING CODE',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.trackingCode,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primaryOrange,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Total: ${widget.totalRwfLabel}'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.trackingCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracking code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy code'),
                ),
              ],
            ),
          ),
          if (showConvert) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryOrange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Save your information',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to track this order in real-time and save your details for next time.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'For ${widget.email}',
                    ),
                  ),
                  PasswordStrengthMeter(password: _password.text),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _creating ? null : _createAccount,
                    child: _creating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  GoogleSignInButton(
                    busy: _googleBusy,
                    label: 'Sign in with Google',
                    onPressed: _creating ? null : _googleConvert,
                  ),
                ],
              ),
            ),
          ] else if (auth.isLoggedIn || _converted) ...[
            const SizedBox(height: 16),
            Text(
              'This order is saved to your IKAYIMART account.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.success),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.go('/tracking?code=${widget.trackingCode}'),
            child: const Text('Track order'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to shop'),
          ),
        ],
      ),
    );
  }
}
