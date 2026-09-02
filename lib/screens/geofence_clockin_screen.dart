import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/device_location_service.dart';
import '../services/smart_time_log_api.dart';
import '../theme/app_theme.dart';

class GeofenceClockInScreen extends StatefulWidget {
  const GeofenceClockInScreen({super.key, this.headquarters});

  final Headquarters? headquarters;

  @override
  State<GeofenceClockInScreen> createState() => _GeofenceClockInScreenState();
}

class _GeofenceClockInScreenState extends State<GeofenceClockInScreen> {
  static const double _geofenceRadiusMeters = 100;

  final MapController _mapController = MapController();
  Position? _currentPosition;
  double? _distanceMeters;
  String? _locationError;
  bool _isLocating = false;
  bool _isClockingIn = false;
  bool _isMapReady = false;

  bool get _isWithinGeofence =>
      _distanceMeters != null && _distanceMeters! <= _geofenceRadiusMeters;

  @override
  void initState() {
    super.initState();
    if (widget.headquarters != null) {
      _refreshLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<Position?> _refreshLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final position = await DeviceLocationService.getCurrentPosition();
      final headquarters = widget.headquarters;
      if (headquarters == null) {
        return null;
      }
      final distance = DeviceLocationService.distanceBetween(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: headquarters.latitude,
        endLongitude: headquarters.longitude,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceMeters = distance;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapToLocations();
        });
      }
      return position;
    } on LocationException catch (error) {
      if (mounted) {
        setState(() => _locationError = error.message);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _fitMapToLocations() {
    final headquarters = widget.headquarters;
    final position = _currentPosition;
    if (!_isMapReady || headquarters == null || position == null) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [
          LatLng(headquarters.latitude, headquarters.longitude),
          LatLng(position.latitude, position.longitude),
        ],
        padding: const EdgeInsets.fromLTRB(52, 112, 52, 72),
        maxZoom: 17,
        minZoom: 4,
      ),
    );
  }

  Future<void> _handleClockIn() async {
    setState(() => _isClockingIn = true);
    try {
      final position = await _refreshLocation();
      if (position == null || !_isWithinGeofence) {
        return;
      }
      await SmartTimeLogApi.instance.clockIn(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/active-shift');
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
        setState(() => _isClockingIn = false);
      }
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.round()} m';
    }
    return '${(distance / 1000).toStringAsFixed(2)} km';
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geofence Clock-in',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step 2 of 5',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLocating ? null : _refreshLocation,
                    tooltip: 'Refresh location',
                    icon: const Icon(Icons.my_location, color: Colors.white),
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
                    if (widget.headquarters == null)
                      _buildMessageCard(
                        context,
                        'No headquarters assigned',
                        'Contact an administrator before clocking in.',
                        Icons.location_off_outlined,
                      )
                    else
                      _buildHeadquartersMap(context),
                    if (_locationError != null) ...[
                      const SizedBox(height: 12),
                      _buildMessageCard(
                        context,
                        'Location unavailable',
                        _locationError!,
                        Icons.gps_off_outlined,
                      ),
                    ],
                    const SizedBox(height: 24.0),

                    if (widget.headquarters != null &&
                        _distanceMeters != null) ...[
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
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDistance(_distanceMeters!)} from ${widget.headquarters!.name ?? 'headquarters'}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withAlpha(
                                                  (0.7 * 255).toInt(),
                                                )
                                              : Colors.black.withAlpha(
                                                  (0.7 * 255).toInt(),
                                                ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                    ],

                    if (widget.headquarters != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.surface(context),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Details',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12.0),
                            _buildLocationDetail(
                              context,
                              'Headquarters',
                              widget.headquarters!.name ??
                                  'HQ ${widget.headquarters!.id}',
                            ),
                            const SizedBox(height: 8),
                            _buildLocationDetail(
                              context,
                              'Coordinates',
                              '${widget.headquarters!.latitude.toStringAsFixed(6)}, ${widget.headquarters!.longitude.toStringAsFixed(6)}',
                            ),
                            const SizedBox(height: 8),
                            _buildLocationDetail(
                              context,
                              'GPS accuracy',
                              _currentPosition == null
                                  ? 'Waiting...'
                                  : '${_currentPosition!.accuracy.round()} m',
                            ),
                            const SizedBox(height: 8),
                            _buildLocationDetail(
                              context,
                              'Allowed radius',
                              '${_geofenceRadiusMeters.round()} m',
                            ),
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
                  top: BorderSide(color: AppTheme.border(context)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ShadButton(
                  onPressed: _isWithinGeofence && !_isClockingIn && !_isLocating
                      ? _handleClockIn
                      : null,
                  child: _isClockingIn
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
    BuildContext context,
    String label,
    String value,
  ) {
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHeadquartersMap(BuildContext context) {
    final headquarters = widget.headquarters!;
    final headquartersPoint = LatLng(
      headquarters.latitude,
      headquarters.longitude,
    );
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: headquartersPoint,
                initialZoom: 17,
                minZoom: 4,
                maxZoom: 19,
                onMapReady: () {
                  _isMapReady = true;
                  _fitMapToLocations();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smarttimelog',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: headquartersPoint,
                      radius: _geofenceRadiusMeters,
                      useRadiusInMeter: true,
                      color: primary.withValues(alpha: 0.16),
                      borderColor: primary.withValues(alpha: 0.9),
                      borderStrokeWidth: 3,
                    ),
                    CircleMarker(
                      point: headquartersPoint,
                      radius: 10,
                      useRadiusInMeter: true,
                      color: primary.withValues(alpha: 0.22),
                      borderColor: primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: headquartersPoint,
                      width: 132,
                      height: 92,
                      alignment: Alignment.topCenter,
                      child: _HeadquartersPin(
                        name: headquarters.name ?? 'Headquarters',
                        color: primary,
                      ),
                    ),
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 34,
                        height: 34,
                        child: _EmployeeLocationMarker(
                          isWithinGeofence: _isWithinGeofence,
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 28,
              child: _MapLegend(
                radiusMeters: _geofenceRadiusMeters,
                color: primary,
              ),
            ),
            if (_isLocating)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HeadquartersPin extends StatelessWidget {
  const _HeadquartersPin({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.location_pin, color: color, size: 46),
      ],
    );
  }
}

class _EmployeeLocationMarker extends StatelessWidget {
  const _EmployeeLocationMarker({required this.isWithinGeofence});

  final bool isWithinGeofence;

  @override
  Widget build(BuildContext context) {
    final color = isWithinGeofence ? const Color(0xFF16A34A) : Colors.red;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
        ],
      ),
      child: Icon(Icons.person, color: color, size: 18),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.radiusMeters, required this.color});

  final double radiusMeters;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${radiusMeters.round()} m headquarters zone',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
