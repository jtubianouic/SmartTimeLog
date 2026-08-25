import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

class GeofenceClockInScreen extends StatefulWidget {
  const GeofenceClockInScreen({super.key});

  @override
  State<GeofenceClockInScreen> createState() => _GeofenceClockInScreenState();
}

class _GeofenceClockInScreenState extends State<GeofenceClockInScreen> {
  final bool _isWithinGeofence = true;
  bool _isLoading = false;
 // Store the controller to handle camera movements or add overlays later

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
                ],
              ),
            ),

            // Content
           
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Map Container
                    SizedBox(
                      height: 250.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: const MapOptions(
                            // Centered exactly on your Location Details coordinates
                            initialCenter: LatLng(37.7749, -122.4194), 
                            initialZoom: 16.0, // Zoomed in closer to see the fence boundary clearly
                          ),
                          children: [
                            // Layer 1: Base Map Tiles
                            TileLayer(
                              // OpenStreetMap tiles
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.smarttimelog',
                            ),
                            
                            // NEW Layer 2: Visual Geofence Boundary
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: const LatLng(37.7749, -122.4194),
                                  radius: 100, // Defines the geofence radius size in METERS
                                  useRadiusInMeter: true, // Forces calculations to match world meters
                                  color: _isWithinGeofence
                                      ? Colors.green.withAlpha((0.2 * 255).toInt()) // Safe translucent green
                                      : Colors.red.withAlpha((0.15 * 255).toInt()), // Alert translucent red
                                  borderColor: _isWithinGeofence 
                                      ? Colors.green.withAlpha((0.8 * 255).toInt()) 
                                      : Colors.red.withAlpha((0.8 * 255).toInt()),
                                  borderStrokeWidth: 2.0,
                                ),
                              ],
                            ),
                            
                            // Layer 3: Central Location Pin
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: const LatLng(37.7749, -122.4194),
                                  width: 50,
                                  height: 50,
                                  child: Icon(
                                    Icons.location_on,
                                    color: _isWithinGeofence ? Colors.green : Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Geofence Status Card (Unchanged)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _isWithinGeofence
                          ? AppTheme.successBackground(context)
                          : Theme.of(context).colorScheme.errorContainer,
                        border: Border.all(
                          color: _isWithinGeofence
                            ? AppTheme.successBorder(context)
                            : Theme.of(context).colorScheme.error,
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
                                  ? AppTheme.successBorder(context)
                                  : Theme.of(context).colorScheme.error,
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
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
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
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withAlpha((0.7 * 255).toInt())
                                            : Colors.black.withAlpha((0.7 * 255).toInt()),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Location Details (Unchanged)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.surface(context),
                        border: Border.all(
                          color: AppTheme.border(context)),
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
                      color: AppTheme.border(context)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ShadButton(
                  onPressed: _isWithinGeofence && !_isLoading
                      ? _handleClockIn
                      : null,
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
                color: AppTheme.mutedText(context),
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
