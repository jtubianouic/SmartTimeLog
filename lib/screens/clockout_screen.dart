import 'package:flutter/material.dart';
import '../services/smart_time_log_api.dart';
import '../theme/app_theme.dart';
import '../widgets/workflow_app_bar.dart';
import 'ai_summary_screen.dart';

class ClockOutScreen extends StatefulWidget {
  const ClockOutScreen({
    super.key,
    this.initialNotes,
    this.initialClockedInDurationSeconds = 0,
    this.initialBreakDurationSeconds = 0,
    this.initialClockInTime,
  });

  final String? initialNotes;
  final int initialClockedInDurationSeconds;
  final int initialBreakDurationSeconds;
  final DateTime? initialClockInTime;

  @override
  State<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends State<ClockOutScreen> {
  late TextEditingController _notesController;
  late int _clockedInDurationSeconds;
  late int _breakDurationSeconds;
  late DateTime _clockInTime;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _clockedInDurationSeconds = widget.initialClockedInDurationSeconds;
    _breakDurationSeconds = widget.initialBreakDurationSeconds;
    _clockInTime =
        widget.initialClockInTime ??
        DateTime.now().subtract(
          Duration(seconds: widget.initialClockedInDurationSeconds),
        );
    if (SmartTimeLogApi.instance.hasSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final status = await SmartTimeLogApi.instance.getAttendanceStatus();
      if (!mounted) return;
      setState(() {
        _clockedInDurationSeconds = status.clockedInDurationSeconds;
        _breakDurationSeconds =
            status.breakDurationSeconds + status.currentBreakDurationSeconds;
        _clockInTime = DateTime.now().subtract(
          Duration(seconds: status.clockedInDurationSeconds),
        );
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

  int get _activeDurationSeconds {
    final duration = _clockedInDurationSeconds - _breakDurationSeconds;
    return duration < 0 ? 0 : duration;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _handleSubmit() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the work you completed.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final employeeInput = 'Activities and notes: $notes';

    try {
      final summary = await SmartTimeLogApi.instance.summarizeWork(
        employeeInput,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AISummaryScreen(
              summary: summary,
              employeeInput: employeeInput,
              notes: _notesController.text,
              clockedInDurationSeconds: _clockedInDurationSeconds,
              breakDurationSeconds: _breakDurationSeconds,
              clockInTime: _clockInTime,
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WorkflowAppBar(title: 'Clock-out log', step: 4),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.successBackground(context),
                      border: Border.all(
                        color: AppTheme.successBorder(context),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.successBorder(context),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review Your Work Log',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Generate an AI summary before clocking out',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText(context),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Session Details
                  Text(
                    'Today\'s Session',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.surface(context),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          'Clocked in',
                          _formatTime(_clockInTime),
                        ),
                        const SizedBox(height: 12.0),
                        Container(height: 1, color: AppTheme.border(context)),
                        const SizedBox(height: 12.0),
                        _buildDetailRow(
                          context,
                          'Clock out',
                          'Pending confirmation',
                        ),
                        const SizedBox(height: 12.0),
                        Container(height: 1, color: AppTheme.border(context)),
                        const SizedBox(height: 12.0),
                        _buildDetailRow(
                          context,
                          'Shift duration',
                          _formatDuration(_clockedInDurationSeconds),
                          isHighlight: true,
                        ),
                        const SizedBox(height: 12.0),
                        Container(height: 1, color: AppTheme.border(context)),
                        const SizedBox(height: 12.0),
                        _buildDetailRow(
                          context,
                          'Break time',
                          _formatDuration(_breakDurationSeconds),
                        ),
                        const SizedBox(height: 12.0),
                        Container(height: 1, color: AppTheme.border(context)),
                        const SizedBox(height: 12.0),
                        _buildDetailRow(
                          context,
                          'Active time',
                          _formatDuration(_activeDurationSeconds),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Activities/Notes
                  Text(
                    'Activities & Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you completed today...',
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isLoading ? 'Generating summary...' : 'Generate summary',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText(context)),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
