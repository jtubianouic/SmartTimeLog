import 'package:flutter/material.dart';
import '../services/device_location_service.dart';
import '../services/smart_time_log_api.dart';
import '../theme/app_theme.dart';
import '../widgets/workflow_app_bar.dart';
import 'clockout_screen.dart';
import 'session_gate.dart';

class AISummaryScreen extends StatefulWidget {
  const AISummaryScreen({
    super.key,
    this.summary,
    this.employeeInput,
    this.notes,
    this.clockedInDurationSeconds = 0,
    this.breakDurationSeconds = 0,
    this.clockInTime,
  });

  final String? summary;
  final String? employeeInput;
  final String? notes;
  final int clockedInDurationSeconds;
  final int breakDurationSeconds;
  final DateTime? clockInTime;

  @override
  State<AISummaryScreen> createState() => _AISummaryScreenState();
}

class _AISummaryScreenState extends State<AISummaryScreen> {
  bool _isConfirming = false;

  Future<void> _handleConfirm() async {
    final employeeInput = widget.employeeInput;
    final aiSummary = widget.summary?.trim();
    if (employeeInput == null || employeeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The work input is missing.')),
      );
      return;
    }
    if (aiSummary == null || aiSummary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The AI summary is missing.')),
      );
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final position = await DeviceLocationService.getCurrentPosition();
      await SmartTimeLogApi.instance.clockOut(
        latitude: position.latitude,
        longitude: position.longitude,
        employeeInput: employeeInput,
        aiSummary: aiSummary,
      );
      if (mounted) {
        await SessionGate.routeAuthenticatedSession(context);
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
        setState(() => _isConfirming = false);
      }
    }
  }

  void _handleEdit() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ClockOutScreen(
          initialNotes: widget.notes,
          initialClockedInDurationSeconds: widget.clockedInDurationSeconds,
          initialBreakDurationSeconds: widget.breakDurationSeconds,
          initialClockInTime: widget.clockInTime,
        ),
      ),
    );
  }

  int get _activeDurationSeconds {
    final duration =
        widget.clockedInDurationSeconds - widget.breakDurationSeconds;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WorkflowAppBar(
        title: 'Review summary',
        step: 5,
        actions: [
          Chip(
            avatar: Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text('AI generated'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth >= 620
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatCard(
                            context,
                            width: cardWidth,
                            label: 'Total duration',
                            value: _formatDuration(
                              widget.clockedInDurationSeconds,
                            ),
                            icon: Icons.schedule_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _buildStatCard(
                            context,
                            width: cardWidth,
                            label: 'Break time',
                            value: _formatDuration(widget.breakDurationSeconds),
                            icon: Icons.coffee_rounded,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          _buildStatCard(
                            context,
                            width: cardWidth,
                            label: 'Active time',
                            value: _formatDuration(_activeDurationSeconds),
                            icon: Icons.trending_up_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // AI Summary
                  Text(
                    'Generated AI summary',
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
                      color: AppTheme.mutedSurface(context),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SmartTimeLog AI',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready for your review',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Container(height: 1, color: AppTheme.border(context)),
                        const SizedBox(height: 12.0),
                        Text(
                          widget.summary ?? 'No summary was generated.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
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
                    child: OutlinedButton.icon(
                      onPressed: _isConfirming ? null : _handleEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit work log'),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isConfirming ? null : _handleConfirm,
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.task_alt_rounded),
                      label: Text(
                        _isConfirming
                            ? 'Confirming...'
                            : 'Confirm and clock out',
                      ),
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

  Widget _buildStatCard(
    BuildContext context, {
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: AppTheme.appMonoFontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
