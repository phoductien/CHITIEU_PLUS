import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:chitieu_plus/screens/terms_and_privacy_screen.dart';

class AuthFooterTerms extends StatelessWidget {
  const AuthFooterTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Bằng việc tiếp tục bạn chấp thuận với '),
            TextSpan(
              text: 'chính sách điều khoản',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 1), // 1 is Terms
                    ),
                  );
                },
            ),
            const TextSpan(text: ' và '),
            TextSpan(
              text: 'quyền riêng tư',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 0), // 0 is Privacy
                    ),
                  );
                },
            ),
            const TextSpan(text: ' của chúng tôi'),
          ],
        ),
      ),
    );
  }
}
