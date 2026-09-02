import 'package:flutter/material.dart';
import 'dart:async';
import '../services/device_location_service.dart';
import '../services/smart_time_log_api.dart';
import '../theme/app_theme.dart';
import '../widgets/workflow_app_bar.dart';
import 'clockout_screen.dart';
import 'session_gate.dart';

class ActiveShiftScreen extends StatefulWidget {
  const ActiveShiftScreen({
    super.key,
    this.initiallyOnBreak = false,
    this.hasTakenBreak = false,
    this.initialClockedInDurationSeconds = 0,
    this.initialBreakDurationSeconds = 0,
    this.initialCurrentBreakDurationSeconds = 0,
  });

  final bool initiallyOnBreak;
  final bool hasTakenBreak;
  final int initialClockedInDurationSeconds;
  final int initialBreakDurationSeconds;
  final int initialCurrentBreakDurationSeconds;

  @override
  State<ActiveShiftScreen> createState() => _ActiveShiftScreenState();
}

class _ActiveShiftScreenState extends State<ActiveShiftScreen>
    with WidgetsBindingObserver {
  late Timer _timer;
  late int _clockedInDurationSeconds;
  late int _breakDurationSeconds;
  late int _currentBreakDurationSeconds;
  late bool _isOnBreak;
  late bool _hasTakenBreak;
  bool _isUpdatingBreak = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isOnBreak = widget.initiallyOnBreak;
    _hasTakenBreak = widget.hasTakenBreak || widget.initiallyOnBreak;
    _clockedInDurationSeconds = widget.initialClockedInDurationSeconds;
    _breakDurationSeconds = widget.initialBreakDurationSeconds;
    _currentBreakDurationSeconds = widget.initialCurrentBreakDurationSeconds;
    _startTimer();
    if (SmartTimeLogApi.instance.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        SmartTimeLogApi.instance.hasSession) {
      _refreshStatus();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _clockedInDurationSeconds++;
        if (_isOnBreak) {
          _currentBreakDurationSeconds++;
        }
      });
    });
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing || !mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final status = await SmartTimeLogApi.instance.getAttendanceStatus();
      if (!mounted) return;
      if (status.state != AttendanceState.clockedIn &&
          status.state != AttendanceState.onBreak) {
        await SessionGate.routeAuthenticatedSession(context);
        return;
      }
      setState(() {
        _isOnBreak = status.state == AttendanceState.onBreak;
        _hasTakenBreak = status.hasTakenBreak;
        _clockedInDurationSeconds = status.clockedInDurationSeconds;
        _breakDurationSeconds = status.breakDurationSeconds;
        _currentBreakDurationSeconds = status.currentBreakDurationSeconds;
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  int get _totalBreakDurationSeconds =>
      _breakDurationSeconds + _currentBreakDurationSeconds;

  int get _activeWorkDurationSeconds {
    final duration = _clockedInDurationSeconds - _totalBreakDurationSeconds;
    return duration < 0 ? 0 : duration;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleTakeBreak() async {
    setState(() => _isUpdatingBreak = true);
    try {
      final position = await DeviceLocationService.getCurrentPosition();
      if (_isOnBreak) {
        await SmartTimeLogApi.instance.endBreak(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        await SmartTimeLogApi.instance.takeBreak(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      if (mounted) {
        setState(() {
          if (_isOnBreak) {
            _breakDurationSeconds += _currentBreakDurationSeconds;
            _currentBreakDurationSeconds = 0;
          }
          _isOnBreak = !_isOnBreak;
          _hasTakenBreak = true;
        });
        await _refreshStatus();
      }
    } on LocationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBreak = false);
      }
    }
  }

  void _handleClockOut() {
    if (!_hasTakenBreak || _isOnBreak) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ClockOutScreen(
          initialClockedInDurationSeconds: _clockedInDurationSeconds,
          initialBreakDurationSeconds: _totalBreakDurationSeconds,
          initialClockInTime: DateTime.now().subtract(
            Duration(seconds: _clockedInDurationSeconds),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: WorkflowAppBar(
        title: 'Active shift',
        step: 3,
        actions: [
          Chip(
            avatar: const Icon(Icons.circle, size: 10),
            label: Text(_isOnBreak ? 'On break' : 'Clocked in'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            color: colorScheme.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isOnBreak
                                            ? Icons.coffee_rounded
                                            : Icons.timer_outlined,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isOnBreak
                                            ? 'Break in progress'
                                            : 'Shift elapsed',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                      const Spacer(),
                                      if (_isRefreshing)
                                        SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatDuration(
                                        _clockedInDurationSeconds,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontFamily:
                                                AppTheme.appMonoFontFamily,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Synced with today\'s attendance record',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer
                                              .withValues(alpha: 0.75),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DurationCard(
                                  label: 'Active work',
                                  value: _formatDuration(
                                    _activeWorkDurationSeconds,
                                  ),
                                  icon: Icons.work_outline_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DurationCard(
                                  label: 'Total break',
                                  value: _formatDuration(
                                    _totalBreakDurationSeconds,
                                  ),
                                  icon: Icons.free_breakfast_outlined,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: _isOnBreak
                                ? colorScheme.tertiaryContainer
                                : colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _isOnBreak
                                          ? colorScheme.tertiary
                                          : colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _hasTakenBreak
                                          ? Icons.task_alt_rounded
                                          : Icons.coffee_rounded,
                                      color: _isOnBreak
                                          ? colorScheme.onTertiary
                                          : colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isOnBreak
                                              ? 'Break in progress'
                                              : _hasTakenBreak
                                              ? 'Break completed'
                                              : 'One break required',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isOnBreak
                                              ? 'End your break before clocking out'
                                              : _hasTakenBreak
                                              ? 'Break completed for today'
                                              : 'Take your break before clocking out',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        if (_isOnBreak) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            _formatDuration(
                                              _currentBreakDurationSeconds,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontFamily: AppTheme
                                                      .appMonoFontFamily,
                                                  color: colorScheme.tertiary,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _isUpdatingBreak || (_hasTakenBreak && !_isOnBreak)
                          ? null
                          : _handleTakeBreak,
                      icon: _isUpdatingBreak
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              _isOnBreak
                                  ? Icons.play_arrow_rounded
                                  : Icons.coffee_rounded,
                            ),
                      label: Text(
                        _isOnBreak
                            ? 'End break'
                            : _hasTakenBreak
                            ? 'Break completed'
                            : 'Take break',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: !_hasTakenBreak || _isOnBreak
                          ? null
                          : _handleClockOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Clock out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.appMonoFontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
