import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../state/auth_state.dart';
import '../../vendor/widgets/google_sign_in_button.dart';

class CheckoutChoiceSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CheckoutChoiceBody(),
    );
  }
}

class _CheckoutChoiceBody extends StatefulWidget {
  const _CheckoutChoiceBody();

  @override
  State<_CheckoutChoiceBody> createState() => _CheckoutChoiceBodyState();
}

class _CheckoutChoiceBodyState extends State<_CheckoutChoiceBody> {
  bool _googleBusy = false;

  Future<void> _continueGuest() async {
    Navigator.of(context).pop();
    context.go('/checkout');
  }

  Future<void> _signInEmail() async {
    Navigator.of(context).pop();
    context.go('/login?next=/checkout');
  }

  Future<void> _googleThenCheckout() async {
    setState(() => _googleBusy = true);
    final auth = context.read<AuthState>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleBusy = false);
    if (!ok) {
      if (auth.error == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
      return;
    }
    Navigator.of(context).pop();
    context.go('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final loggedIn = auth.isLoggedIn;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to check out?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loggedIn
                  ? 'You are signed in as ${auth.user!.email}. Continue to checkout, or place this order as a guest.'
                  : 'Sign in to save addresses and track every order — or continue as a guest.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
            ),
            const SizedBox(height: 20),
            if (loggedIn)
              _ChoiceCard(
                icon: Icons.verified_user_outlined,
                title: 'Continue signed in',
                subtitle:
                    'Saved details, order history, and faster checkout next time.',
                emphasized: true,
                onTap: _continueGuest,
              )
            else ...[
              _ChoiceCard(
                icon: Icons.person_outline,
                title: 'Sign in / Register',
                subtitle:
                    'Saved addresses, order tracking history, and 1-click checkout next time.',
                emphasized: true,
                onTap: _signInEmail,
              ),
              const SizedBox(height: 12),
              GoogleSignInButton(
                busy: _googleBusy,
                onPressed: _googleThenCheckout,
              ),
            ],
            const SizedBox(height: 12),
            _ChoiceCard(
              icon: Icons.flash_on_outlined,
              title: 'Continue as Guest',
              subtitle:
                  'Fast checkout with email, phone, and delivery address only.',
              emphasized: false,
              onTap: _continueGuest,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized ? AppColors.primaryLight : AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasized
                  ? AppColors.primaryOrange
                  : AppColors.borderSubtle,
              width: emphasized ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: emphasized
                    ? AppColors.primaryOrange
                    : AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
