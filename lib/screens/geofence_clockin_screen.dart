import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GeofenceClockInScreen extends StatefulWidget {
  const GeofenceClockInScreen({super.key});

  @override
  State<GeofenceClockInScreen> createState() => _GeofenceClockInScreenState();
}

class _GeofenceClockInScreenState extends State<GeofenceClockInScreen> {
  final bool _isWithinGeofence = true;
  bool _isLoading = false;

  void _handleClockIn() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/active-shift');
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
                        'Geofence Clock-in',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step 2 of 5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Map Placeholder
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCardBackground
                            : AppTheme.lightCardBackground,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardBorder
                              : AppTheme.lightCardBorder,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Map background
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                    Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.darkSummaryGradientStart
                                      : AppTheme.lightSummaryGradientStart,
                                    Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.darkCardBackground
                                      : AppTheme.lightCardBackground,
                                ],
                              ),
                            ),
                          ),
                          // Center marker
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your Location',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Geofence Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _isWithinGeofence
                          ? (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkStatusSuccessBackground
                            : AppTheme.lightStatusSuccessBackground)
                          : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkStatusErrorBackground
                            : AppTheme.lightStatusErrorBackground),
                        border: Border.all(
                          color: _isWithinGeofence
                            ? (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkStatusSuccessBorder
                              : AppTheme.lightStatusSuccessBorder)
                            : (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkStatusErrorBorder
                              : AppTheme.lightStatusErrorBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                                color: _isWithinGeofence
                                  ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkStatusSuccessBorder
                                    : AppTheme.lightStatusSuccessBorder)
                                  : (Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkStatusErrorBorder
                                    : AppTheme.lightStatusErrorBorder),
                            ),
                            child: Icon(
                              _isWithinGeofence
                                  ? Icons.check_circle
                                  : Icons.cancel,
                                color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isWithinGeofence
                                      ? 'Within Geofence'
                                      : 'Outside Geofence',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isWithinGeofence
                                      ? 'You are within the office geofence'
                                      : 'You are outside the office geofence',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Location Details
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Details',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 12.0),
                          _buildLocationDetail(
                              context, 'Address', '123 Business Street'),
                          const SizedBox(height: 8),
                          _buildLocationDetail(context, 'Coordinates',
                              '37.7749° N, 122.4194° W'),
                          const SizedBox(height: 8),
                          _buildLocationDetail(
                              context, 'Accuracy', '5m'),
                        ],
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
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkCardBorder
                        : AppTheme.lightCardBorder),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isWithinGeofence && !_isLoading
                      ? _handleClockIn
                      : null,
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
                          'Clock In',
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

  Widget _buildLocationDetail(
      BuildContext context, String label, String value) {
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
