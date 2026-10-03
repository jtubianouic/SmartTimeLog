import 'package:flutter/material.dart';

class OnboardingWalkthrough extends StatefulWidget {
  const OnboardingWalkthrough({super.key});

  @override
  State<OnboardingWalkthrough> createState() => _OnboardingWalkthroughState();
}

class _OnboardingWalkthroughState extends State<OnboardingWalkthrough> {
  int _step = 0;

  static const _steps = [
    (
      icon: Icons.location_on_outlined,
      title: 'Clock in with geofencing',
      description:
          'SmartTimeLog compares your device location with your assigned '
          'headquarters before recording attendance.',
    ),
    (
      icon: Icons.timer_outlined,
      title: 'Track shifts and breaks',
      description:
          'Your active shift keeps clock-in, break, and working durations '
          'visible so you always know your current status.',
    ),
    (
      icon: Icons.auto_awesome_outlined,
      title: 'Create an AI work summary',
      description:
          'At clock-out, enter your completed work and review the AI-generated '
          'summary before saving the attendance record.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return AlertDialog(
      icon: Icon(step.icon, size: 40),
      title: Text(step.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.description, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => Container(
                width: index == _step ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _step
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          ),
        FilledButton(
          onPressed: isLast
              ? () => Navigator.pop(context, true)
              : () => setState(() => _step++),
          child: Text(isLast ? 'Get started' : 'Next'),
        ),
      ],
    );
  }
}
