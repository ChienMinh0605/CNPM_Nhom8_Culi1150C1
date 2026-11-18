import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';

/// Trang VNPay chuyển khách về sau khi thanh toán (FR40). [query] là nguyên
/// chuỗi tham số vnp_* VNPay gắn vào đường dẫn, gửi lại cho backend kiểm chữ
/// ký. Trạng thái đơn do IPN cập nhật, trang này chỉ đọc.
class PaymentResultPage extends StatefulWidget {
  const PaymentResultPage({super.key, required this.query, this.api});

  final String query;
  final ApiClient? api;

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  late final ApiClient _api = widget.api ?? ApiClient();
  late Future<Map<String, dynamic>> _result = _load();

  Future<Map<String, dynamic>> _load() =>
      _api.getJson('/api/v1/payment/return?${widget.query}');

  void _reload() {
    setState(() {
      _result = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Trang chủ',
          onPressed: () => context.go('/'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _result,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return _Outcome(
                          icon: Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          title: 'Không đọc được kết quả thanh toán',
                          message: errorText(snapshot.error!),
                          action: _homeButton(context),
                        );
                      }
                      return _content(context, snapshot.data!);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> order) {
    final retry = FilledButton(
      onPressed: () => context.go('/mua-ve'),
      child: const Text('Đặt vé lại'),
    );
    switch (order['status']) {
      case 'PAID' || 'USED':
        return _Outcome(
          icon: Icons.check_circle,
          color: const Color(0xFF1B6E3C),
          title: 'Thanh toán thành công',
          message: 'Xuất trình mã QR này ở cổng vào. Một mã dùng cho cả đoàn.',
          action: _homeButton(context),
          children: [
            Center(
              child: QrImageView(
                data: order['code'] as String,
                size: 200,
                semanticsLabel: 'Mã QR của đơn ${order['code']}',
              ),
            ),
            Center(
              child: Text(
                'Mã đơn ${order['code']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 32),
            _OrderDetails(order: order),
          ],
        );
      case 'PENDING' when order['responseCode'] == '00':
        return _Outcome(
          icon: Icons.hourglass_top,
          color: dcsvAmber,
          title: 'Đang xác nhận thanh toán',
          message:
              'VNPay báo đã nhận tiền, hệ thống đang chờ xác nhận. '
              'Bạn bấm Kiểm tra lại sau ít giây.',
          action: FilledButton(
            onPressed: _reload,
            child: const Text('Kiểm tra lại'),
          ),
          children: [_OrderDetails(order: order)],
        );
      case 'PENDING':
        return _Outcome(
          icon: Icons.cancel_outlined,
          color: Theme.of(context).colorScheme.error,
          title: 'Thanh toán chưa thành công',
          message:
              'Giao dịch bị hủy hoặc không thành công. Bạn có thể đặt vé lại.',
          action: retry,
        );
      default:
        return _Outcome(
          icon: Icons.timer_off_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          title: 'Đơn đã hết hạn giữ chỗ',
          message: 'Đơn quá 15 phút chưa thanh toán nên đã bị hủy.',
          action: retry,
        );
    }
  }

  Widget _homeButton(BuildContext context) => OutlinedButton(
    onPressed: () => context.go('/'),
    child: const Text('Về trang chủ'),
  );
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.action,
    this.children = const [],
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        ...children,
        const SizedBox(height: 20),
        Center(child: action),
      ],
    );
  }
}

/// Ngày, khung giờ, các dòng vé và tổng tiền của đơn.
class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget line(String left, String right, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(left, style: style)),
          Text(right, style: style),
        ],
      ),
    );
    return Column(
      children: [
        line(
          'Ngày tham quan',
          formatDate(DateTime.parse(order['visitDate'] as String)),
          style: TextStyle(color: muted),
        ),
        line(
          'Khung giờ',
          '${order['startTime']} – ${order['endTime']}',
          style: TextStyle(color: muted),
        ),
        for (final item
            in (order['items'] as List).cast<Map<String, dynamic>>())
          line(
            '${item['quantity']} × ${item['name']}',
            formatVnd((item['quantity'] as int) * (item['unitPrice'] as int)),
          ),
        line(
          'Tổng cộng',
          formatVnd(order['totalAmount'] as int),
          style: const TextStyle(fontWeight: FontWeight.w600, color: dcsvNavy),
        ),
      ],
    );
  }
}
