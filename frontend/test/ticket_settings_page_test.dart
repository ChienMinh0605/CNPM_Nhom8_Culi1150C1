import 'dart:convert';

import 'package:dcsv_frontend/core/api_client.dart';
import 'package:dcsv_frontend/features/admin/ticket_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Future<void> _pump(WidgetTester tester, MockClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TicketSettingsPage(
        api: ApiClient(httpClient: client, baseUrl: ''),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện loại vé với giá VNĐ và đổi trạng thái khi gạt công tắc', (
    tester,
  ) async {
    final sent = <String>[];
    final client = MockClient((request) async {
      sent.add('${request.method} ${request.url.path} ${request.body}');
      final items = switch (request.url.path) {
        '/api/v1/ticket-types' => [
          {
            'id': 1,
            'name': 'Người lớn',
            'audience': 'Khách từ 16 tuổi',
            'price': 40000,
            'active': true,
          },
        ],
        '/api/v1/time-slots' => [
          {'id': 1, 'startTime': '08:00', 'endTime': '10:00', 'capacity': 50},
          {'id': 2, 'startTime': '10:00', 'endTime': '12:00', 'capacity': 70},
        ],
        _ => [],
      };
      return _json({'items': items, 'total': items.length});
    });
    await _pump(tester, client);

    expect(find.text('Người lớn'), findsOneWidget);
    expect(find.text('40.000 ₫'), findsOneWidget);
    expect(find.text('Đang bán'), findsOneWidget);
    // Hàng số liệu: 1 trên 1 loại vé đang bán, tổng sức chứa hai khung giờ.
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('120 khách'), findsOneWidget);
    expect(find.text('Chưa có'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      sent.any(
        (line) =>
            line.startsWith('PUT /api/v1/ticket-types/1') &&
            line.contains('"active":false'),
      ),
      isTrue,
    );
  });

  testWidgets('danh sách rỗng có lời nhắc', (tester) async {
    await _pump(
      tester,
      MockClient((request) async => _json({'items': [], 'total': 0})),
    );
    expect(find.textContaining('Chưa có loại vé nào'), findsOneWidget);
  });

  testWidgets('lỗi máy chủ hiện thông báo và nút Thử lại', (tester) async {
    await _pump(
      tester,
      MockClient(
        (request) async => _json({
          'error': {'code': 'X', 'message': 'Máy chủ đang bận'},
        }, 500),
      ),
    );
    expect(find.text('Máy chủ đang bận'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
