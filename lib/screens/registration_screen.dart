import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/smart_time_log_api.dart';
import '../services/registration_qr_decoder.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _registrationToken;
  DateTime? _currentQrExpiresAt;
  List<RegistrationHeadquarters> _headquarters = const [];
  int? _headquartersId;
  String? _error;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _lastScannedToken;

  bool get _canScan =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onScan(BarcodeCapture capture) {
    if (_busy || _registrationToken != null) return;
    final token = capture.barcodes
        .where((barcode) => barcode.format == BarcodeFormat.qrCode)
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (token == null || token == _lastScannedToken) return;
    _lastScannedToken = token;
    _acceptToken(token);
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final token = decodeRegistrationQrImage(await image.readAsBytes());
      if (mounted) await _acceptToken(token);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error = 'Could not read that image. Choose a clear QR code.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptToken(String token) async {
    final decoded = token.trim();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(decoded)) {
      setState(() {
        _registrationToken = null;
        _error = 'This is not a SmartTimeLog registration QR code.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _lastScannedToken = decoded;
      _registrationToken = null;
      _headquarters = const [];
      _headquartersId = null;
    });
    try {
      final api = SmartTimeLogApi.instance;
      final results = await Future.wait<Object>([
        api.getCurrentRegistrationQr(),
        api.getRegistrationHeadquarters(),
      ]);
      final currentQr = results[0] as CurrentRegistrationQr;
      final headquarters = results[1] as List<RegistrationHeadquarters>;
      if (!currentQr.expiresAt.isAfter(DateTime.now().toUtc())) {
        throw const ApiException(
          'The registration QR code has expired. Ask for a new one.',
        );
      }
      if (decodeRegistrationQrDataUrl(currentQr.dataUrl) != decoded) {
        throw const ApiException(
          'This QR code is expired or has been replaced. Ask for a new one.',
        );
      }
      if (mounted) {
        setState(() {
          _registrationToken = decoded;
          _currentQrExpiresAt = currentQr.expiresAt;
          _headquarters = headquarters;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'The server returned an unreadable QR image.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final token = _registrationToken;
    final headquartersId = _headquartersId;
    if (token == null || headquartersId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!(_currentQrExpiresAt?.isAfter(DateTime.now().toUtc()) ?? false)) {
        throw const ApiException(
          'The registration QR code has expired. Ask for a new one.',
        );
      }
      await SmartTimeLogApi.instance.register(
        registrationToken: token,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        headquartersId: headquartersId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration requested. An administrator must approve your account before you can log in.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.statusCode == 401
              ? 'This QR code is expired or invalid. Ask for a new one.'
              : error.message;
          if (error.statusCode == 401) _registrationToken = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _requiredName(String? value) {
    final length = value?.trim().length ?? 0;
    if (length == 0) return 'Required';
    if (length > 80) return 'Use 80 characters or fewer';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_registrationToken == null) ...[
                Text(
                  'Scan your registration QR code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Point your camera at the QR code from your administrator.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (_canScan)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: (MediaQuery.sizeOf(context).height * 0.43).clamp(
                        240.0,
                        320.0,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Semantics(
                            label: 'Live registration QR camera preview',
                            child: MobileScanner(
                              key: const ValueKey('registration-camera'),
                              onDetect: _onScan,
                            ),
                          ),
                          IgnorePointer(
                            child: Center(
                              child: CustomPaint(
                                size: const Size(220, 220),
                                painter: _ScanFramePainter(colorScheme.primary),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: Colors.black54,
                              child: const Text(
                                'Keep the QR code inside the frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Camera scanning is unavailable on this device. Upload a QR image instead.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload QR image'),
                  ),
                ),
              ] else ...[
                Text(
                  'Complete your registration',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _registrationToken = null;
                          _lastScannedToken = null;
                          _error = null;
                        }),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan another QR code'),
                ),
              ],
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (_registrationToken == null && _lastScannedToken != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _lastScannedToken = null),
                    child: const Text('Try scanning again'),
                  ),
              ],
              if (_registrationToken != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Current QR verified. The server will check it again when you submit.',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                        validator: _requiredName,
                      ),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                        validator: _requiredName,
                      ),
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          if (length < 3) return 'Use at least 3 characters';
                          if (length > 80) return 'Use 80 characters or fewer';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final length = value?.length ?? 0;
                          if (length < 8) return 'Use at least 8 characters';
                          if (length > 128) {
                            return 'Use 128 characters or fewer';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: _headquartersId,
                        decoration: const InputDecoration(
                          labelText: 'Headquarters',
                        ),
                        items: _headquarters
                            .map(
                              (hq) => DropdownMenuItem(
                                value: hq.id,
                                child: Text(
                                  hq.name?.isNotEmpty == true
                                      ? hq.name!
                                      : 'HQ ${hq.id}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (value) =>
                                  setState(() => _headquartersId = value),
                        validator: (value) =>
                            value == null ? 'Select a headquarters' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: const Text('Request registration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black54
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final accent = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const corner = 30.0;
    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(size.width - corner, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, corner)
      ..moveTo(size.width, size.height - corner)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - corner, size.height)
      ..moveTo(corner, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - corner);
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, accent);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
