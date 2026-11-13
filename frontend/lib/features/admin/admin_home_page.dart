import 'package:material_ui/material_ui.dart';

import '../../core/placeholder_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Trang quản trị',
      stories: [
        'US03 – Quản lý tài khoản nhân viên và vai trò',
        'US05–US07 – Hồ sơ hiện vật, ảnh, khu trưng bày',
        'US08–US11 – Biên tập, gửi duyệt, duyệt, triển lãm',
        'US17–US18 – Loại vé, khung giờ, ngày đóng cửa',
        'US22 – Báo cáo doanh thu và lượt khách',
      ],
    );
  }
}
