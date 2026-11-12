import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';

/// Trang chủ cổng công khai (US12). Hiện tại chỉ kiểm tra kết nối backend.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _api = ApiClient();
  late Future<Map<String, dynamic>> _health;

  @override
  void initState() {
    super.initState();
    _health = _api.getJson('/api/health');
  }

  void _retry() {
    setState(() {
      _health = _api.getJson('/api/health');
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Bảo tàng Dòng chảy Sử Việt')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('DCSV Digital CMS', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Khung dự án. Nội dung trang chủ (US12) sẽ làm ở Sprint 2.',
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _health,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Text('Đang kiểm tra kết nối backend…');
                      }
                      final ok = !snapshot.hasError;
                      return Row(
                        children: [
                          Icon(
                            ok ? Icons.check_circle : Icons.error,
                            color: ok ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ok
                                  ? 'Đã kết nối backend tại ${AppConfig.apiBaseUrl}'
                                  : 'Chưa kết nối được backend tại ${AppConfig.apiBaseUrl}',
                            ),
                          ),
                          TextButton(
                            onPressed: _retry,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => context.go('/dang-nhap'),
                    child: const Text('Đăng nhập'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/quan-tri'),
                    child: const Text('Trang quản trị'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/soat-ve'),
                    child: const Text('Soát vé'),
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
