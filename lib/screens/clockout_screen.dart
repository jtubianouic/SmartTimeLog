import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ClockOutScreen extends StatefulWidget {
  const ClockOutScreen({super.key});

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
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _projectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_selectedProject == null || _selectedProject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/summary');
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkStatusSuccessBackground
                          : AppTheme.lightStatusSuccessBackground,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkStatusSuccessBorder
                            : AppTheme.lightStatusSuccessBorder),
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
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.darkStatusSuccessBorder
                                      : AppTheme.lightStatusSuccessBorder,
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
                                      'Clocked Out Successfully',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '4:30 PM - In Office Hub',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
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
                        color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkCardBackground
                          : AppTheme.lightCardBackground,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCardBorder
                            : AppTheme.lightCardBorder),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            'Clock In',
                            '9:00 AM',
                          ),
                          const SizedBox(height: 12.0),
                          Container(
                            height: 1,
                            color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardBorder
                              : AppTheme.lightCardBorder,
                          ),
                          const SizedBox(height: 12.0),
                          _buildDetailRow(
                            context,
                            'Clock Out',
                            '4:30 PM',
                          ),
                          const SizedBox(height: 12.0),
                          Container(
                            height: 1,
                            color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardBorder
                              : AppTheme.lightCardBorder,
                          ),
                          const SizedBox(height: 12.0),
                          _buildDetailRow(
                            context,
                            'Total Duration',
                            '7h 30m',
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
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                          'Submit Log',
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
        ),
      ],
    );
  }
}
