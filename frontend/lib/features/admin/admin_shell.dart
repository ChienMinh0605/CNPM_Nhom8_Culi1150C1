import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Các mục của trang quản trị. Mục chưa có đường dẫn là phần chưa làm, hiện mờ.
/// Làm xong màn nào thì điền đường dẫn của màn đó vào đây.
const _navItems = <(IconData, String, String?)>[
  (Icons.dashboard_outlined, 'Tổng quan', '/quan-tri'),
  (Icons.museum_outlined, 'Hiện vật', null),
  (Icons.edit_note_outlined, 'Biên tập và duyệt', null),
  (Icons.confirmation_number_outlined, 'Bán vé', '/quan-tri/ve'),
  (Icons.bar_chart_outlined, 'Báo cáo', null),
  (Icons.group_outlined, 'Tài khoản', null),
];

/// Khung chung của mọi màn quản trị: sidebar bên trái, tên trang và các tab
/// ở trên, nội dung bên dưới. Màn hẹp thì sidebar thành ngăn kéo.
///
/// Có [tabs] thì màn dùng khung phải bọc trong DefaultTabController.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.path,
    required this.body,
    this.tabs,
  });

  final String title;

  /// Đường dẫn của màn hiện tại, để tô mục đang chọn ở sidebar.
  final String path;
  final Widget body;
  final List<String>? tabs;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final tabBar = tabs == null
        ? null
        : TabBar(
            isScrollable: wide,
            tabAlignment: wide ? TabAlignment.start : TabAlignment.fill,
            padding: wide ? const EdgeInsets.symmetric(horizontal: 16) : null,
            // Hẹp hơn mặc định để các nhãn vừa màn hình điện thoại.
            labelPadding: wide
                ? null
                : const EdgeInsets.symmetric(horizontal: 8),
            tabs: [for (final tab in tabs!) Tab(text: tab)],
          );

    if (!wide) {
      return Scaffold(
        appBar: AppBar(title: Text(title), bottom: tabBar),
        drawer: Drawer(
          backgroundColor: dcsvNavy,
          child: _Sidebar(path: path),
        ),
        body: body,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 248, child: _Sidebar(path: path)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          32,
                          24,
                          32,
                          tabBar == null ? 24 : 8,
                        ),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      tabBar ?? const Divider(height: 1),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dcsvNavy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dcsvAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dòng chảy Sử Việt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Quản trị nội dung',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final (icon, label, target) in _navItems)
              _NavItem(
                icon: icon,
                label: label,
                target: target,
                selected: target == path,
              ),
            const Spacer(),
            const _NavItem(
              icon: Icons.public,
              label: 'Cổng công khai',
              target: '/',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.target,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? target;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : target == null
        ? Colors.white38
        : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: target == null ? null : () => context.go(target!),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? const Color(0xFFE0A84A) : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (target == null)
                  const Text(
                    'Sắp có',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
