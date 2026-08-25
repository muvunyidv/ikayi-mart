import 'package:flutter/material.dart';

import '../../auth/screens/auth_screen.dart';

class VendorLoginScreen extends StatelessWidget {
  const VendorLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthScreen(vendorContext: true);
}
