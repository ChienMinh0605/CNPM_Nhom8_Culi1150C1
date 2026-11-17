import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';

typedef _Json = Map<String, dynamic>;

const _maxTicketsPerOrder = 10;
const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String _isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Mở trang thanh toán VNPay ngay trong tab hiện tại.
Future<void> _openInSameTab(String url) async {
  await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
}

/// US19 – Mua vé online (FR38, FR39): chọn ngày, khung giờ, loại vé và số
/// lượng, rồi chuyển sang VNPay.
///
/// shortcut: chưa bắt đăng nhập Thành viên, thêm khi US01 và US04 xong.
class TicketPurchasePage extends StatefulWidget {
  const TicketPurchasePage({super.key, this.api, this.openPayment});

  final ApiClient? api;

  /// Mở đường dẫn thanh toán; test truyền hàm khác để không rời trang.
  final Future<void> Function(String url)? openPayment;

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  late final ApiClient _api = widget.api ?? ApiClient();

  // Hôm nay và 30 ngày tới (FR38).
  final List<DateTime> _days = () {
    final now = DateTime.now();
    return [
      for (var i = 0; i <= 30; i++) DateTime(now.year, now.month, now.day + i),
    ];
  }();
  late DateTime _date = _days.first;

  List<_Json>? _types;
  Object? _typesError;
  _Json? _day;
  Object? _dayError;

  int? _slotId;
  final Map<int, int> _quantities = {};
  bool _paying = false;
  String? _payError;

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _loadDay();
  }

  Future<void> _loadTypes() async {
    setState(() => _typesError = null);
    try {
      final json = await _api.getJson('/api/v1/public/ticket-types');
      if (mounted) setState(() => _types = (json['items'] as List).cast());
    } catch (error) {
      if (mounted) setState(() => _typesError = error);
    }
  }

  Future<void> _loadDay() async {
    final date = _date;
    setState(() {
      _day = null;
      _dayError = null;
    });
    try {
      final day = await _api.getJson(
        '/api/v1/public/availability?date=${_isoDate(date)}',
      );
      if (mounted && date == _date) setState(() => _day = day);
    } catch (error) {
      if (mounted && date == _date) setState(() => _dayError = error);
    }
  }

  void _selectDate(DateTime date) {
    if (date == _date) return;
    _date = date;
    _slotId = null;
    _payError = null;
    _loadDay();
  }

  List<_Json> get _slots =>
      ((_day?['slots'] as List?) ?? const []).cast<_Json>();

  _Json? get _slot {
    for (final slot in _slots) {
      if (slot['id'] == _slotId) return slot;
    }
    return null;
  }

  int get _count => _quantities.values.fold(0, (a, b) => a + b);

  int get _total {
    var total = 0;
    for (final type in _types ?? const <_Json>[]) {
      total += (type['price'] as int) * (_quantities[type['id']] ?? 0);
    }
    return total;
  }

  /// Số vé tối đa còn chọn được: không quá 10 vé và không quá số chỗ trống.
  int get _limit => min(
    _maxTicketsPerOrder,
    (_slot?['remaining'] as int?) ?? _maxTicketsPerOrder,
  );

  void _changeQuantity(int typeId, int delta) {
    setState(() {
      _payError = null;
      final next = (_quantities[typeId] ?? 0) + delta;
      if (next <= 0) {
        _quantities.remove(typeId);
      } else {
        _quantities[typeId] = next;
      }
    });
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _payError = null;
    });
    try {
      final order = await _api.send('POST', '/api/v1/orders', {
        'visitDate': _isoDate(_date),
        'timeSlotId': _slotId,
        'items': [
          for (final entry in _quantities.entries)
            {'ticketTypeId': entry.key, 'quantity': entry.value},
        ],
      });
      await (widget.openPayment ?? _openInSameTab)(
        order['paymentUrl'] as String,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _payError = errorText(error);
      });
      // Hết chỗ: tải lại số chỗ để khách thấy đúng tình trạng mới nhất.
      if (error is ApiException && error.statusCode == 409) _loadDay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final steps = [
      _Step(number: 1, title: 'Chọn ngày tham quan', child: _dateStrip()),
      _Step(number: 2, title: 'Chọn khung giờ', child: _slotPicker()),
      _Step(number: 3, title: 'Chọn loại vé', child: _typePicker()),
    ];
    final summary = _Summary(
      date: _date,
      slot: _slot,
      types: _types ?? const [],
      quantities: _quantities,
      total: _total,
      error: _payError ?? _blockReason(),
      paying: _paying,
      onPay: _canPay ? _pay : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua vé tham quan'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Trang chủ',
          onPressed: () => context.go('/'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(32),
                        children: steps,
                      ),
                    ),
                    SizedBox(
                      width: 360,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
                        children: [summary],
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [...steps, summary],
                ),
        ),
      ),
    );
  }

  bool get _canPay =>
      _slot != null && _count > 0 && _blockReason() == null && !_paying;

  /// Lý do chưa bấm thanh toán được, hiện ngay trên nút.
  String? _blockReason() {
    final slot = _slot;
    if (slot != null && _count > (slot['remaining'] as int)) {
      return 'Khung giờ này chỉ còn ${slot['remaining']} chỗ';
    }
    return null;
  }

  Widget _dateStrip() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final selected = day == _date;
          return _SelectBox(
            width: 64,
            selected: selected,
            onTap: () => setState(() => _selectDate(day)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  index == 0 ? 'Hôm nay' : _weekdays[day.weekday - 1],
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${day.day}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('Th ${day.month}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slotPicker() {
    if (_dayError != null) {
      return _Notice(
        icon: Icons.cloud_off_outlined,
        text: errorText(_dayError!),
        action: TextButton(onPressed: _loadDay, child: const Text('Thử lại')),
      );
    }
    final day = _day;
    if (day == null) return const _Loading();
    if (day['closed'] == true) {
      final reason = day['reason'] as String;
      return _Notice(
        icon: Icons.event_busy_outlined,
        text:
            'Bảo tàng đóng cửa ngày ${formatDate(_date)}'
            '${reason.isEmpty ? '' : ': $reason'}. Bạn chọn ngày khác nhé.',
      );
    }
    if (_slots.isEmpty) {
      return const _Notice(
        icon: Icons.schedule_outlined,
        text: 'Ngày này không còn khung giờ nào. Bạn chọn ngày khác nhé.',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in _slots)
          _SelectBox(
            width: 148,
            selected: slot['id'] == _slotId,
            onTap: (slot['remaining'] as int) > 0
                ? () => setState(() {
                    _slotId = slot['id'] as int;
                    _payError = null;
                  })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    '${slot['startTime']} – ${slot['endTime']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (slot['remaining'] as int) > 0
                        ? 'Còn ${slot['remaining']} chỗ'
                        : 'Hết chỗ',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _typePicker() {
    if (_typesError != null) {
      return _Notice(
        icon: Icons.cloud_off_outlined,
        text: errorText(_typesError!),
        action: TextButton(onPressed: _loadTypes, child: const Text('Thử lại')),
      );
    }
    final types = _types;
    if (types == null) return const _Loading();
    if (types.isEmpty) {
      return const _Notice(
        icon: Icons.confirmation_number_outlined,
        text: 'Hiện chưa mở bán vé.',
      );
    }
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          for (final (index, type) in types.indexed) ...[
            if (index > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type['name'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          type['audience'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatVnd(type['price'] as int),
                          style: const TextStyle(
                            color: dcsvAmber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Stepper(
                    label: type['name'] as String,
                    value: _quantities[type['id']] ?? 0,
                    canAdd: _count < _limit,
                    onChanged: (delta) =>
                        _changeQuantity(type['id'] as int, delta),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Một bước có số thứ tự và tiêu đề.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.child});

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: dcsvAmber,
                foregroundColor: Colors.white,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Ô chọn được: viền xám, chọn thì nền navy chữ trắng, khóa thì mờ.
class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.width,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return SizedBox(
      width: width,
      child: Material(
        color: selected ? dcsvNavy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? dcsvNavy : const Color(0xFFE2E5EB),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : disabled
                  ? const Color(0xFFA0A6B1)
                  : dcsvNavy,
            ),
            textAlign: TextAlign.center,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Nút trừ, số lượng, nút cộng.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.canAdd,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool canAdd;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Bớt vé $label',
          onPressed: value > 0 ? () => onChanged(-1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton.filled(
          tooltip: 'Thêm vé $label',
          onPressed: canAdd ? () => onChanged(1) : null,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

/// Tóm tắt đơn và nút thanh toán.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.date,
    required this.slot,
    required this.types,
    required this.quantities,
    required this.total,
    required this.error,
    required this.paying,
    required this.onPay,
  });

  final DateTime date;
  final Map<String, dynamic>? slot;
  final List<Map<String, dynamic>> types;
  final Map<int, int> quantities;
  final int total;
  final String? error;
  final bool paying;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget line(String left, String right, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(left, style: style)),
          Text(right, style: style),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đơn của bạn', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            line(
              'Ngày',
              '${_weekdays[date.weekday - 1]}, ${formatDate(date)}',
              style: TextStyle(color: muted),
            ),
            line(
              'Khung giờ',
              slot == null
                  ? 'Chưa chọn'
                  : '${slot!['startTime']} – ${slot!['endTime']}',
              style: TextStyle(color: muted),
            ),
            const Divider(height: 24),
            if (quantities.isEmpty)
              Text('Chưa chọn vé', style: TextStyle(color: muted)),
            for (final type in types)
              if ((quantities[type['id']] ?? 0) > 0)
                line(
                  '${quantities[type['id']]} × ${type['name']}',
                  formatVnd((type['price'] as int) * quantities[type['id']]!),
                ),
            const Divider(height: 24),
            line(
              'Tổng cộng',
              formatVnd(total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: dcsvNavy,
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Text(error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: onPay,
              style: FilledButton.styleFrom(
                backgroundColor: dcsvAmber,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                paying ? 'Đang chuyển sang VNPay…' : 'Thanh toán qua VNPay',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chỗ được giữ 15 phút sau khi bấm thanh toán. '
              'Tối đa $_maxTicketsPerOrder vé mỗi đơn.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: color)),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );
}
