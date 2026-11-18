import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';

const _validColor = Color(0xFF1B6E3C);
const _invalidColor = Color(0xFFB3261E);

/// US21 – Soát vé bằng mã QR (FR43–FR45). Nhân viên quầy vé quét mã QR bằng
/// camera điện thoại, hoặc nhập tay mã vé khi không quét được.
///
/// shortcut: chưa bắt đăng nhập Nhân viên quầy vé, thêm khi US01 xong.
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key, this.api, this.useCamera = true});

  final ApiClient? api;

  /// Test tắt camera vì môi trường test không có camera.
  final bool useCamera;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late final ApiClient _api = widget.api ?? ApiClient();
  late final MobileScannerController? _scanner = widget.useCamera
      ? MobileScannerController(formats: const [BarcodeFormat.qrCode])
      : null;
  final _codeField = TextEditingController();

  bool _checking = false;
  Map<String, dynamic>? _result;
  String? _error;

  /// Mã vừa soát. Camera bỏ qua mã này để khi bấm «Quét vé tiếp» mà khách
  /// chưa cất vé thì không báo nhầm «đã sử dụng»; nhập tay thì vẫn soát được.
  String? _lastCode;

  @override
  void dispose() {
    _scanner?.dispose();
    _codeField.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code != _lastCode) _check(code);
  }

  Future<void> _check(String code) async {
    // Đang hiện kết quả thì bỏ qua mã quét được, tránh quét lại đúng vé vừa
    // soát và báo "đã sử dụng".
    if (_checking || _result != null || code.trim().isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
      _lastCode = code;
    });
    try {
      final result = await _api.send('POST', '/api/v1/check-in', {
        'code': code,
      });
      if (mounted) setState(() => _result = result);
    } catch (error) {
      // Lỗi mạng thì chưa soát được, cho camera quét lại đúng mã này.
      if (mounted) {
        setState(() {
          _error = errorText(error);
          _lastCode = null;
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _next() {
    setState(() {
      _result = null;
      _error = null;
      _codeField.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Soát vé')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_scanner case final scanner?)
                        MobileScanner(
                          controller: scanner,
                          onDetect: _onDetect,
                          errorBuilder: (context, error) => const _CameraOff(
                            text:
                                'Không mở được camera. Bạn cho phép trình '
                                'duyệt dùng camera, hoặc nhập mã vé ở dưới.',
                          ),
                        )
                      else
                        const _CameraOff(text: 'Camera đang tắt.'),
                      if (result != null)
                        _ResultPanel(result: result, onNext: _next)
                      else if (_checking)
                        const ColoredBox(
                          color: Colors.black54,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đưa mã QR trên vé vào khung camera. Mỗi đơn soát một lần cho '
                'cả đoàn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeField,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _check,
                      decoration: InputDecoration(
                        labelText: 'Nhập tay mã vé',
                        hintText: 'Mã in dưới mã QR',
                        errorText: _error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _checking || result != null
                          ? null
                          : () => _check(_codeField.text),
                      child: const Text('Kiểm tra'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraOff extends StatelessWidget {
  const _CameraOff({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dcsvNavy,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phủ lên khung camera: xanh «HỢP LỆ» kèm số khách, đỏ «KHÔNG HỢP LỆ» kèm
/// lý do.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.onNext});

  final Map<String, dynamic> result;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final valid = result['valid'] == true;
    final order = result['order'] as Map<String, dynamic>?;
    final items = valid
        ? (order!['items'] as List).cast<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    final guests = items.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));
    const white = TextStyle(color: Colors.white);

    return ColoredBox(
      color: valid ? _validColor : _invalidColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              valid ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 56,
            ),
            const SizedBox(height: 8),
            Text(
              valid ? 'HỢP LỆ' : 'KHÔNG HỢP LỆ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (valid) ...[
              Text(
                '$guests khách',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final item in items)
                Text('${item['quantity']} × ${item['name']}', style: white),
              const SizedBox(height: 4),
              Text(
                'Khung giờ ${order!['startTime']} – ${order['endTime']}',
                style: const TextStyle(color: Colors.white70),
              ),
            ] else
              Text(
                result['reason'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: valid ? _validColor : _invalidColor,
              ),
              child: const Text('Quét vé tiếp'),
            ),
          ],
        ),
      ),
    );
  }
}
