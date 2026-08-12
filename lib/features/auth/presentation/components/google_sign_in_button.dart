import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

class MyGoogleSignInButton extends StatelessWidget {
  const MyGoogleSignInButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/google.png', height: 22),
            const SizedBox(width: 12),
            Text(context.l10n.continueWithGoogle),
          ],
        ),
      ),
    );
  }
}
