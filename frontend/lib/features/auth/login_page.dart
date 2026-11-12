import 'package:flutter/material.dart';

import '../../core/placeholder_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Đăng nhập',
      stories: [
        'US01 – Đăng nhập và đăng xuất',
        'US02 – Quên mật khẩu',
        'US04 – Đăng ký tài khoản Thành viên',
      ],
    );
  }
}
