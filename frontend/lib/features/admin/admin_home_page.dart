import 'package:material_ui/material_ui.dart';

import 'admin_shell.dart';

/// Trang đầu của khu quản trị. Hiện liệt kê các User Story còn phải làm.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const _stories = [
    'US03 – Quản lý tài khoản nhân viên và vai trò',
    'US05–US07 – Hồ sơ hiện vật, ảnh, khu trưng bày',
    'US08–US11 – Biên tập, gửi duyệt, duyệt, triển lãm',
    'US22 – Báo cáo doanh thu và lượt khách',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Tổng quan',
      path: '/quan-tri',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Phần này sẽ làm các User Story:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final story in _stories)
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(story),
            ),
        ],
      ),
    );
  }
}
