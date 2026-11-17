import 'package:material_ui/material_ui.dart';

import '../../core/api_client.dart';

typedef Item = Map<String, dynamic>;

String errorText(Object error) => error is ApiException
    ? error.message
    : 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';

/// Một khối thiết lập: tiêu đề, nút thêm và danh sách tải từ [path].
/// Tự lo các trạng thái đang tải, lỗi và rỗng.
class SettingsSection extends StatefulWidget {
  const SettingsSection({
    super.key,
    required this.api,
    required this.path,
    required this.title,
    required this.description,
    required this.addLabel,
    required this.emptyText,
    required this.onAdd,
    required this.rowBuilder,
    this.onChanged,
  });

  final ApiClient api;
  final String path;
  final String title;
  final String description;
  final String addLabel;
  final String emptyText;

  /// Mở hộp thoại thêm; trả về true nếu đã lưu.
  final Future<bool?> Function(BuildContext context) onAdd;
  final Widget Function(BuildContext context, Item item, VoidCallback reload)
  rowBuilder;

  /// Gọi sau mỗi lần danh sách được tải lại (thêm, sửa, xóa).
  final VoidCallback? onChanged;

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late Future<List<Item>> _items = _load();

  Future<List<Item>> _load() async {
    final json = await widget.api.getJson(widget.path);
    return (json['items'] as List).cast<Item>();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _items = _load();
    });
    widget.onChanged?.call();
  }

  Future<void> _add() async {
    if (await widget.onAdd(context) == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: EdgeInsets.all(narrow ? 16 : 32),
          children: [
            // Màn hẹp: nút thêm xuống dưới phần mô tả để chữ không bị bóp.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: narrow ? double.infinity : 560,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(widget.addLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: FutureBuilder<List<Item>>(
                future: _items,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _Message(
                      icon: Icons.cloud_off_outlined,
                      text: errorText(snapshot.error!),
                      action: OutlinedButton(
                        onPressed: _reload,
                        child: const Text('Thử lại'),
                      ),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return _Message(
                      icon: Icons.inbox_outlined,
                      text: widget.emptyText,
                    );
                  }
                  return Column(
                    children: [
                      for (final (index, item) in items.indexed) ...[
                        if (index > 0) const Divider(height: 1),
                        widget.rowBuilder(context, item, _reload),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Một dòng trong danh sách: tên, dòng phụ và các nút ở bên phải.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle = '',
    this.dimmed = false,
    this.badge,
    this.trailing = const [],
  });

  final String title;
  final String subtitle;
  final bool dimmed;

  /// Nhãn trạng thái đứng ngay sau tên.
  final Widget? badge;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: dimmed ? secondary : null,
                        ),
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 8), badge!],
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ...trailing,
        ],
      ),
    );
  }
}

/// Hộp thoại thêm hoặc sửa. Lỗi máy chủ trả về (ví dụ chồng khung giờ) hiện
/// ngay trong hộp thoại để người dùng sửa rồi lưu lại.
class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final List<Widget> fields;
  final Future<void> Function() onSubmit;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                for (final field in widget.fields) ...[
                  field,
                  const SizedBox(height: 16),
                ],
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
        ),
      ],
    );
  }
}

/// Hỏi lại trước khi xóa, rồi gọi DELETE [path]. Lỗi (ví dụ loại vé đã có
/// người mua) hiện ở thanh thông báo cuối màn hình.
Future<void> confirmDelete(
  BuildContext context, {
  required ApiClient api,
  required String path,
  required String title,
  required String message,
  required VoidCallback onDone,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await api.send('DELETE', path);
    onDone();
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(errorText(error))));
  }
}

String? requiredText(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Không được để trống' : null;

/// Nhãn trạng thái nhỏ: xanh lá khi đang bật, xám khi đã tắt.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE6F4EA) : const Color(0xFFEEF0F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: active ? const Color(0xFF1B6E3C) : const Color(0xFF5B6270),
        ),
      ),
    );
  }
}
