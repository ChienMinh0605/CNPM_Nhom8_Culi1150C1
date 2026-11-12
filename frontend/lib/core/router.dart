import 'package:go_router/go_router.dart';

import '../features/admin/admin_home_page.dart';
import '../features/auth/login_page.dart';
import '../features/checkin/check_in_page.dart';
import '../features/portal/home_page.dart';

/// Ba khu vực giao diện: cổng công khai, trang quản trị, màn hình soát vé.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/dang-nhap', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/quan-tri',
      builder: (context, state) => const AdminHomePage(),
    ),
    GoRoute(path: '/soat-ve', builder: (context, state) => const CheckInPage()),
  ],
);
