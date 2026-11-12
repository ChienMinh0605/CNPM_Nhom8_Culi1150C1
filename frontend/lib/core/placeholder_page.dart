import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Trang giữ chỗ cho phần chưa làm; liệt kê các User Story sẽ nằm ở đây.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.stories,
  });

  final String title;
  final List<String> stories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Trang chủ',
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Phần này sẽ làm các User Story:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final story in stories)
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(story),
            ),
        ],
      ),
    );
  }
}
