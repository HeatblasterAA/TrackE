import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

class OTPVerifyPage extends ConsumerStatefulWidget {
  final String verificationId;

  const OTPVerifyPage({
    super.key,
    required this.verificationId,
  });

  @override
  ConsumerState<OTPVerifyPage> createState() =>
      _OTPVerifyPageState();
}

class _OTPVerifyPageState
    extends ConsumerState<OTPVerifyPage> {
  final controller = TextEditingController();
  bool loading = false;

  Future<void> verify() async {
  setState(() => loading = true);

  try {
    await ref.read(authRepositoryProvider).verifyOtp(
      verificationId: widget.verificationId,
      otp: controller.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP'),
        ),
      );
    }
  }

  if (mounted) {
    setState(() => loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter OTP',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : verify,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}