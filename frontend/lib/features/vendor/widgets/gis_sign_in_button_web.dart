import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;
import 'package:provider/provider.dart';

import '../../../state/auth_state.dart';

/// Official Google Identity Services button. This returns an ID token and does
/// not call the People API (`signIn()` on web does, and fails when that API is
/// disabled).
Widget? gisWebSignInButton({
  VoidCallback? onPressed,
  bool busy = false,
}) {
  return _GisWebSignInButton(onPressed: onPressed, busy: busy);
}

class _GisWebSignInButton extends StatefulWidget {
  const _GisWebSignInButton({this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  State<_GisWebSignInButton> createState() => _GisWebSignInButtonState();
}

class _GisWebSignInButtonState extends State<_GisWebSignInButton> {
  StreamSubscription<GoogleSignInAccount?>? _sub;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _sub = auth.googleAccountChanges.listen((account) {
      if (!mounted || account == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPressed?.call();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 44,
          width: double.infinity,
          child: gsi.renderButton(
            configuration: gsi.GSIButtonConfiguration(
              type: gsi.GSIButtonType.standard,
              theme: gsi.GSIButtonTheme.outline,
              size: gsi.GSIButtonSize.large,
              text: gsi.GSIButtonText.signinWith,
              shape: gsi.GSIButtonShape.rectangular,
              logoAlignment: gsi.GSIButtonLogoAlignment.left,
              minimumWidth: 320,
            ),
          ),
        ),
        if (widget.busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xCCFFFFFF),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
