import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'otp_verify_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final controller = TextEditingController();
  String countryCode = '+966';
  bool loading = false;

//  Future<void> sendOtp() async {
//   String number = controller.text.trim();

//   if (number.isEmpty) return;

//   number = number.replaceAll(RegExp(r'\s+'), '');

//   if (number.startsWith('0')) {
//     number = number.substring(1);
//   }

//   final fullPhone = '$countryCode$number';

//   setState(() => loading = true);

//   await ref.read(authRepositoryProvider).verifyPhone(
//     phoneNumber: fullPhone,
//     codeSent: (verificationId) {
//       if (!mounted) return;

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OTPVerifyPage(
//             verificationId: verificationId,
//           ),
//         ),
//       );
//     },
//     failed: (msg) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(msg)),
//       );
//     },
//   );

//   if (mounted) {
//     setState(() => loading = false);
//   }
// }

Future<void> sendOtp() async {
  String number = controller.text.trim();

  if (number.isEmpty) return;

  number = number.replaceAll(RegExp(r'\D'), '');

  if (number.startsWith('0')) {
    number = number.substring(1);
  }

  if (number.length < 8 || number.length > 12) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter valid phone number'),
      ),
    );
    return;
  }

  final fullPhone = '$countryCode$number';

  setState(() => loading = true);

  await ref.read(authRepositoryProvider).verifyPhone(
    phoneNumber: fullPhone,
    codeSent: (verificationId) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerifyPage(
            verificationId: verificationId,
          ),
        ),
      );
    },
    failed: (msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    },
  );

  if (mounted) {
    setState(() => loading = false);
  }
}
     

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: countryCode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '+91', child: Text('India (+91)')),
                DropdownMenuItem(
                  value: '+966',
                  child: Text('Saudi Arabia (+966)'),
                ),
              ],
              onChanged: (v) {
                setState(() => countryCode = v!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Phone number',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : sendOtp,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
