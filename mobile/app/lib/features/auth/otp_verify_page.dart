import 'dart:async';

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
  final controller =
      TextEditingController();

  bool loading = false;

  int seconds = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    seconds = 30;

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (seconds <= 1) {
          t.cancel();

          setState(() {
            seconds = 0;
          });

          return;
        }

        setState(() {
          seconds--;
        });
      },
    );
  }

  Future<void> verify() async {
    final otp =
        controller.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Enter 6 digit OTP'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(
            verificationId:
                widget.verificationId,
            otp: otp,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text('OTP incorrect'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Verify OTP'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            const Text(
              'Enter verification code',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'We sent a 6-digit OTP',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
                hintText:
                    '123456',
                counterText: '',
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : verify,
                child:
                    loading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                                strokeWidth:
                                    2.4,
                              ),
                        )
                        : const Text(
                          'Verify',
                        ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child:
                  seconds > 0
                      ? Text(
                        'Resend in ${seconds}s',
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      )
                      : TextButton(
                        onPressed: () {
                          startTimer();

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Resend from login screen for now',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Resend OTP',
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}