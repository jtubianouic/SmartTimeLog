import 'package:flutter/material.dart';

import '../services/smart_time_log_api.dart';
import '../widgets/theme_toggle_button.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key, this.loadTimelogs});

  final Future<List<AttendanceTimelog>> Function()? loadTimelogs;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late Future<List<AttendanceTimelog>> _timelogs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _timelogs = (widget.loadTimelogs ?? _loadTimelogsFromApi)().then(
      (timelogs) =>
          [...timelogs]..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    );
  }

  Future<List<AttendanceTimelog>> _loadTimelogsFromApi() async {
    final status = await SmartTimeLogApi.instance.getAttendanceStatus();
    return status.timelogs;
  }

  Future<void> _refresh() async {
    setState(_load);
    await _timelogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance history'),
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: FutureBuilder<List<AttendanceTimelog>>(
        future: _timelogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Unable to load attendance history.';
            return _HistoryMessage(
              icon: Icons.error_outline,
              title: 'History unavailable',
              message: message,
              actionLabel: 'Retry',
              onAction: () => setState(_load),
            );
          }
          final events = snapshot.data ?? const [];
          if (events.isEmpty) {
            return const _HistoryMessage(
              icon: Icons.history_toggle_off,
              title: 'No attendance history yet',
              message:
                  'Clock-ins, breaks, and clock-outs returned by the server '
                  'will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _AttendanceEventTile(event: events[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceEventTile extends StatelessWidget {
  const _AttendanceEventTile({required this.event});

  final AttendanceTimelog event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(_iconFor(event.type)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDate(event.timestamp)} at '
                    '${_formatTime(event.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (event.latitude != null && event.longitude != null)
                    Text(
                      '${event.latitude!.toStringAsFixed(5)}, '
                      '${event.longitude!.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AttendanceTimelogType type) => switch (type) {
    AttendanceTimelogType.clockIn => Icons.login_rounded,
    AttendanceTimelogType.breakStart => Icons.free_breakfast_outlined,
    AttendanceTimelogType.breakEnd => Icons.play_arrow_rounded,
    AttendanceTimelogType.clockOut => Icons.logout_rounded,
  };

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
