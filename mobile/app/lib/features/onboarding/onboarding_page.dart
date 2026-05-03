import 'package:flutter/material.dart';

import 'permission_page.dart';

/// Three-slide intro. Slide 2 wording is the verbatim Play Store
/// disclosure language and MUST stay in sync with the data-safety form.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int page = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      title: 'Automatic expense tracking',
      subtitle:
          'TrackE organises your spending automatically, processed locally on your device.',
    ),
    _SlideData(
      title: 'Only your bank notifications',
      subtitle:
          'TrackE reads transaction notifications from selected financial apps only. Other notifications (chats, OTPs, news, system) are ignored on-device.',
    ),
    _SlideData(
      title: 'Your messages stay on your phone',
      subtitle:
          'Raw bank messages are never uploaded. Only structured transaction data — amount, merchant, category — syncs across your devices.',
    ),
  ];

  void next() {
    if (page < _slides.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PermissionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (v) => setState(() => page = v),
                children: _slides.map((s) => _Slide(data: s)).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: page == i ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: next,
                  child: Text(page == _slides.length - 1 ? 'Continue' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String subtitle;
  const _SlideData({required this.title, required this.subtitle});
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
