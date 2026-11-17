import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_client.dart';
import '../../core/formatters.dart';
import 'admin_shell.dart';
import 'settings_section.dart';

/// Thiết lập bán vé cho Quản lý bảo tàng: loại vé (US17), khung giờ và
/// ngày đóng cửa (US18).
class TicketSettingsPage extends StatefulWidget {
  const TicketSettingsPage({super.key, this.api});

  final ApiClient? api;

  @override
  State<TicketSettingsPage> createState() => _TicketSettingsPageState();
}

class _TicketSettingsPageState extends State<TicketSettingsPage> {
  late final ApiClient _api = widget.api ?? ApiClient();

  /// Tăng lên mỗi khi một danh sách đổi, để hàng số liệu tải lại.
  final _changes = ValueNotifier<int>(0);

  void _changed() => _changes.value++;

  @override
  void dispose() {
    _changes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AdminShell(
        title: 'Thiết lập bán vé',
        path: '/quan-tri/ve',
        tabs: const ['Loại vé', 'Khung giờ', 'Ngày đóng cửa'],
        body: Column(
          children: [
            _Summary(api: _api, changes: _changes),
            Expanded(
              child: TabBarView(
                children: [
                  _ticketTypes(_api, _changed),
                  _timeSlots(_api, _changed),
                  _closedDays(_api, _changed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ba ô số liệu phía trên các tab: loại vé đang bán, tổng sức chứa mỗi ngày
/// và ngày đóng cửa sắp tới.
class _Summary extends StatefulWidget {
  const _Summary({required this.api, required this.changes});

  final ApiClient api;
  final ValueNotifier<int> changes;

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  static const _labels = [
    'Loại vé đang bán',
    'Sức chứa mỗi ngày',
    'Ngày đóng cửa sắp tới',
  ];

  late Future<List<String>> _values = _load();

  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_reload);
  }

  @override
  void dispose() {
    widget.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _values = _load();
    });
  }

  Future<List<String>> _load() async {
    final results = await Future.wait([
      for (final path in [_typesPath, _slotsPath, _daysPath])
        widget.api.getJson(path),
    ]);
    List<Item> items(int index) =>
        (results[index]['items'] as List).cast<Item>();

    final types = items(0);
    final today = DateUtils.dateOnly(DateTime.now());
    // Máy chủ trả ngày đóng cửa đã xếp tăng dần.
    final next = items(2)
        .map((day) => DateTime.parse(day['date'] as String))
        .where((day) => !day.isBefore(today))
        .firstOrNull;
    return [
      '${types.where((type) => type['active'] == true).length}/${types.length}',
      '${items(1).fold<int>(0, (sum, slot) => sum + (slot['capacity'] as int))} khách',
      next == null ? 'Chưa có' : formatDate(next),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 32.0;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child: FutureBuilder<List<String>>(
            future: _values,
            builder: (context, snapshot) {
              // Đang tải hoặc lỗi thì để gạch; lỗi đã báo ở danh sách bên dưới.
              final values = snapshot.data ?? const ['–', '–', '–'];
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, label) in _labels.indexed) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    values[index],
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Loại vé (FR34, FR35) ----------

const _typesPath = '/api/v1/ticket-types';

Widget _ticketTypes(ApiClient api, VoidCallback onChanged) {
  return SettingsSection(
    api: api,
    onChanged: onChanged,
    path: _typesPath,
    title: 'Loại vé',
    description: 'Loại vé đang tắt không hiện ở trang mua vé.',
    addLabel: 'Thêm loại vé',
    emptyText: 'Chưa có loại vé nào. Thêm loại vé đầu tiên để bắt đầu bán.',
    onAdd: (context) => _showTicketTypeDialog(context, api),
    rowBuilder: (context, item, reload) {
      final active = item['active'] as bool;
      return SettingsRow(
        title: item['name'] as String,
        subtitle: item['audience'] as String,
        dimmed: !active,
        // Màn hẹp không đủ chỗ cho nhãn cạnh tên; công tắc đã cho biết trạng thái.
        badge: MediaQuery.sizeOf(context).width < 600
            ? null
            : StatusBadge(
                label: active ? 'Đang bán' : 'Đã tắt',
                active: active,
              ),
        trailing: [
          Text(
            formatVnd(item['price'] as int),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: active ? 'Đang bán, bấm để tắt' : 'Đã tắt, bấm để bật',
            child: Switch(
              value: active,
              onChanged: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await api.send('PUT', '$_typesPath/${item['id']}', {
                    ...item,
                    'active': value,
                  });
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(errorText(error))),
                  );
                }
                reload();
              },
            ),
          ),
          _RowMenu(
            onEdit: () async {
              if (await _showTicketTypeDialog(context, api, item) == true) {
                reload();
              }
            },
            onDelete: () => confirmDelete(
              context,
              api: api,
              path: '$_typesPath/${item['id']}',
              title: 'Xóa loại vé «${item['name']}»?',
              message:
                  'Loại vé đã có người mua thì không xóa được, chỉ tắt được.',
              onDone: reload,
            ),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showTicketTypeDialog(
  BuildContext context,
  ApiClient api, [
  Item? item,
]) {
  final name = TextEditingController(text: item?['name'] as String? ?? '');
  final audience = TextEditingController(
    text: item?['audience'] as String? ?? '',
  );
  final price = TextEditingController(text: item?['price']?.toString() ?? '');
  return showDialog<bool>(
    context: context,
    builder: (context) => FormDialog(
      title: item == null ? 'Thêm loại vé' : 'Sửa loại vé',
      fields: [
        TextFormField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên loại vé'),
          validator: requiredText,
        ),
        TextFormField(
          controller: audience,
          decoration: const InputDecoration(labelText: 'Đối tượng áp dụng'),
          validator: requiredText,
        ),
        TextFormField(
          controller: price,
          decoration: const InputDecoration(
            labelText: 'Giá vé',
            suffixText: '₫',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          validator: requiredText,
        ),
      ],
      onSubmit: () {
        final body = {
          'name': name.text.trim(),
          'audience': audience.text.trim(),
          'price': int.parse(price.text),
          'active': item?['active'] ?? true,
        };
        return item == null
            ? api.send('POST', _typesPath, body)
            : api.send('PUT', '$_typesPath/${item['id']}', body);
      },
    ),
  );
}

// ---------- Khung giờ (FR36) ----------

const _slotsPath = '/api/v1/time-slots';

Widget _timeSlots(ApiClient api, VoidCallback onChanged) {
  return SettingsSection(
    api: api,
    onChanged: onChanged,
    path: _slotsPath,
    title: 'Khung giờ tham quan',
    description:
        'Áp dụng cho mọi ngày mở cửa. Sức chứa là số khách tối đa bán vé '
        'cho mỗi khung giờ.',
    addLabel: 'Thêm khung giờ',
    emptyText: 'Chưa có khung giờ nào. Chưa có khung giờ thì chưa bán được vé.',
    onAdd: (context) => _showTimeSlotDialog(context, api),
    rowBuilder: (context, item, reload) => SettingsRow(
      title: '${item['startTime']} – ${item['endTime']}',
      trailing: [
        Text('${item['capacity']} khách'),
        const SizedBox(width: 4),
        _RowMenu(
          onEdit: () async {
            if (await _showTimeSlotDialog(context, api, item) == true) {
              reload();
            }
          },
          onDelete: () => confirmDelete(
            context,
            api: api,
            path: '$_slotsPath/${item['id']}',
            title: 'Xóa khung giờ ${item['startTime']} – ${item['endTime']}?',
            message: 'Khung giờ đã có đơn vé thì không xóa được.',
            onDone: reload,
          ),
        ),
      ],
    ),
  );
}

Future<bool?> _showTimeSlotDialog(
  BuildContext context,
  ApiClient api, [
  Item? item,
]) {
  final start = TextEditingController(
    text: item?['startTime'] as String? ?? '',
  );
  final end = TextEditingController(text: item?['endTime'] as String? ?? '');
  final capacity = TextEditingController(
    text: item?['capacity']?.toString() ?? '',
  );
  return showDialog<bool>(
    context: context,
    builder: (context) => FormDialog(
      title: item == null ? 'Thêm khung giờ' : 'Sửa khung giờ',
      fields: [
        _TimeField(controller: start, label: 'Giờ bắt đầu'),
        _TimeField(
          controller: end,
          label: 'Giờ kết thúc',
          // Giờ dạng HH:MM nên so sánh chuỗi cũng là so sánh giờ.
          validator: (value) =>
              requiredText(value) ??
              (value!.compareTo(start.text) <= 0
                  ? 'Phải sau giờ bắt đầu'
                  : null),
        ),
        TextFormField(
          controller: capacity,
          decoration: const InputDecoration(
            labelText: 'Sức chứa',
            suffixText: 'khách',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          validator: (value) =>
              requiredText(value) ??
              (int.parse(value!) == 0 ? 'Phải lớn hơn 0' : null),
        ),
      ],
      onSubmit: () {
        final body = {
          'startTime': start.text,
          'endTime': end.text,
          'capacity': int.parse(capacity.text),
        };
        return item == null
            ? api.send('POST', _slotsPath, body)
            : api.send('PUT', '$_slotsPath/${item['id']}', body);
      },
    ),
  );
}

/// Ô chọn giờ: bấm vào mở đồng hồ 24 giờ, kết quả ghi dạng HH:MM.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.controller,
    required this.label,
    this.validator = requiredText,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.schedule),
      ),
      validator: validator,
      onTap: () async {
        final parts = controller.text.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: parts.length == 2
              ? TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                )
              : const TimeOfDay(hour: 8, minute: 0),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked == null) return;
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      },
    );
  }
}

// ---------- Ngày đóng cửa (FR37) ----------

const _daysPath = '/api/v1/closed-days';

Widget _closedDays(ApiClient api, VoidCallback onChanged) {
  return SettingsSection(
    api: api,
    onChanged: onChanged,
    path: _daysPath,
    title: 'Ngày đóng cửa',
    description: 'Không bán vé cho những ngày này.',
    addLabel: 'Thêm ngày',
    emptyText: 'Chưa đánh dấu ngày đóng cửa nào.',
    onAdd: (context) => _showClosedDayDialog(context, api),
    rowBuilder: (context, item, reload) {
      final date = formatDate(DateTime.parse(item['date'] as String));
      return SettingsRow(
        title: date,
        subtitle: item['reason'] as String,
        trailing: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Bỏ ngày đóng cửa',
            onPressed: () => confirmDelete(
              context,
              api: api,
              path: '$_daysPath/${item['date']}',
              title: 'Bỏ ngày đóng cửa $date?',
              message: 'Ngày này sẽ mở bán vé trở lại.',
              onDone: reload,
            ),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showClosedDayDialog(BuildContext context, ApiClient api) {
  final shown = TextEditingController();
  final reason = TextEditingController();
  DateTime? day;
  return showDialog<bool>(
    context: context,
    builder: (context) => FormDialog(
      title: 'Thêm ngày đóng cửa',
      fields: [
        TextFormField(
          controller: shown,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Ngày',
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          validator: requiredText,
          onTap: () async {
            final today = DateUtils.dateOnly(DateTime.now());
            final picked = await showDatePicker(
              context: context,
              initialDate: day ?? today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 730)),
            );
            if (picked == null) return;
            day = picked;
            shown.text = formatDate(picked);
          },
        ),
        TextFormField(
          controller: reason,
          decoration: const InputDecoration(
            labelText: 'Lý do (không bắt buộc)',
          ),
        ),
      ],
      onSubmit: () => api.send('POST', _daysPath, {
        'date': day!.toIso8601String().substring(0, 10),
        'reason': reason.text.trim(),
      }),
    ),
  );
}

// ---------- Dùng chung ----------

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Thao tác',
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(value: onEdit, child: const Text('Sửa')),
        PopupMenuItem(
          value: onDelete,
          child: Text(
            'Xóa',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
