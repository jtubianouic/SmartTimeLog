import 'package:flutter/material.dart';

import '../services/smart_time_log_api.dart';

class WorkflowAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkflowAppBar({
    super.key,
    required this.title,
    required this.step,
    this.actions = const [],
  });

  final String title;
  final int step;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 84,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 3),
          Text(
            'Step $step of 5',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        IconButton(
          onPressed: () => _confirmLogout(context),
          tooltip: 'Log out',
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: step / 5,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access SmartTimeLog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;
    await SmartTimeLogApi.instance.clearSession();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}
