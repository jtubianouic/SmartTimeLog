import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/smart_time_log_api.dart';
import '../theme/app_theme.dart';
import 'ai_summary_screen.dart';

class ClockOutScreen extends StatefulWidget {
  const ClockOutScreen({super.key, this.initialProject, this.initialNotes});

  final String? initialProject;
  final String? initialNotes;

  @override
  State<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends State<ClockOutScreen> {
  late TextEditingController _projectController;
  late TextEditingController _notesController;
  String? _selectedProject;
  bool _isLoading = false;

  final List<String> _projects = [
    'Project A - Client Portal Redesign',
    'Project B - Mobile App Development',
    'Project C - Backend API Enhancement',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _projectController = TextEditingController();
    _notesController = TextEditingController(text: widget.initialNotes);
    _selectedProject = widget.initialProject;
  }

  @override
  void dispose() {
    _projectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedProject == null || _selectedProject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() => _isLoading = true);
    final employeeInput = [
      'Project: $_selectedProject',
      if (_notesController.text.trim().isNotEmpty)
        'Activities and notes: ${_notesController.text.trim()}',
    ].join('\n');

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
              project: _selectedProject!,
              notes: _notesController.text,
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock-out Log',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step 4 of 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
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
                          _buildDetailRow(context, 'Clock In', '9:00 AM'),
                          const SizedBox(height: 12.0),
                          Container(height: 1, color: AppTheme.border(context)),
                          const SizedBox(height: 12.0),
                          _buildDetailRow(
                            context,
                            'Clock Out',
                            'Pending confirmation',
                          ),
                          const SizedBox(height: 12.0),
                          Container(height: 1, color: AppTheme.border(context)),
                          const SizedBox(height: 12.0),
                          _buildDetailRow(
                            context,
                            'Total Duration',
                            'Calculated after clock-out',
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Project Selection
                    Text(
                      'Project/Client',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProject,
                      items: _projects.map((project) {
                        return DropdownMenuItem(
                          value: project,
                          child: Text(project),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedProject = value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Select a project...',
                        prefixIcon: Icon(Icons.folder),
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
                        hintText: 'Enter activities and notes...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border(context)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ShadButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Generate Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
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
