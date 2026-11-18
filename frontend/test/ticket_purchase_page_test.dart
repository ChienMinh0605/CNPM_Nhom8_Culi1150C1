import 'dart:convert';

import 'package:dcsv_frontend/core/api_client.dart';
import 'package:dcsv_frontend/features/portal/ticket_purchase_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

const _types = [
  {'id': 1, 'name': 'Người lớn', 'audience': 'Từ 16 tuổi', 'price': 40000},
  {'id': 2, 'name': 'Sinh viên', 'audience': 'Có thẻ', 'price': 20000},
];

/// Máy chủ giả: [day] là kết quả /availability, [order] là kết quả POST.
MockClient _server({
  required Map<String, dynamic> day,
  http.Response? order,
  List<String>? sent,
}) {
  return MockClient((request) async {
    sent?.add('${request.method} ${request.url.path} ${request.body}');
    return switch (request.url.path) {
      '/api/v1/public/ticket-types' => _json({'items': _types, 'total': 2}),
      '/api/v1/public/availability' => _json(day),
      '/api/v1/orders' => order!,
      _ => _json({}, 404),
    };
  });
}

const _openDay = {
  'closed': false,
  'reason': '',
  'slots': [
    {'id': 7, 'startTime': '08:00', 'endTime': '10:00', 'remaining': 3},
    {'id': 8, 'startTime': '10:00', 'endTime': '12:00', 'remaining': 0},
  ],
};

Future<void> _pump(
  WidgetTester tester,
  MockClient client, {
  Future<void> Function(String url)? openPayment,
}) async {
  // Màn rộng để thấy cả các bước lẫn khung tóm tắt.
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: TicketPurchasePage(
        api: ApiClient(httpClient: client, baseUrl: ''),
        openPayment: openPayment ?? (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chọn khung giờ và vé, tính tổng rồi chuyển sang VNPay', (
    tester,
  ) async {
    final sent = <String>[];
    String? opened;
    await _pump(
      tester,
      _server(
        day: _openDay,
        sent: sent,
        order: _json({
          'code': 'ABC',
          'paymentUrl': 'https://vnpay.test/x',
        }, 201),
      ),
      openPayment: (url) async => opened = url,
    );

    expect(find.text('Hết chỗ'), findsOneWidget);
    expect(find.text('Còn 3 chỗ'), findsOneWidget);

    await tester.tap(find.text('08:00 – 10:00').first);
    await tester.tap(find.byTooltip('Thêm vé Người lớn'));
    await tester.tap(find.byTooltip('Thêm vé Người lớn'));
    await tester.tap(find.byTooltip('Thêm vé Sinh viên'));
    await tester.pump();

    expect(find.text('100.000 ₫'), findsOneWidget);
    // Khung giờ còn 3 chỗ nên không thêm được vé thứ tư.
    final add = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add).first,
    );
    expect(add.onPressed, isNull);

    await tester.tap(find.text('Thanh toán qua VNPay'));
    await tester.pumpAndSettle();

    expect(opened, 'https://vnpay.test/x');
    final post = sent.singleWhere((line) => line.startsWith('POST'));
    expect(post, contains('"timeSlotId":7'));
    expect(post, contains('{"ticketTypeId":1,"quantity":2}'));
    expect(post, contains('{"ticketTypeId":2,"quantity":1}'));
  });

  testWidgets('hết chỗ khi thanh toán thì báo lỗi và tải lại số chỗ', (
    tester,
  ) async {
    final sent = <String>[];
    await _pump(
      tester,
      _server(
        day: _openDay,
        sent: sent,
        order: _json({
          'error': {
            'code': 'SOLD_OUT',
            'message': 'Khung giờ này chỉ còn 0 chỗ',
          },
        }, 409),
      ),
    );
    await tester.tap(find.text('08:00 – 10:00').first);
    await tester.tap(find.byTooltip('Thêm vé Người lớn'));
    await tester.pump();
    await tester.tap(find.text('Thanh toán qua VNPay'));
    await tester.pumpAndSettle();

    expect(find.text('Khung giờ này chỉ còn 0 chỗ'), findsOneWidget);
    expect(sent.where((line) => line.contains('/availability')).length, 2);
  });

  testWidgets('ngày đóng cửa thì hiện lý do, không có khung giờ', (
    tester,
  ) async {
    await _pump(
      tester,
      _server(day: {'closed': true, 'reason': 'Bảo trì', 'slots': []}),
    );
    expect(find.textContaining('Bảo trì'), findsOneWidget);
    expect(find.text('Còn 3 chỗ'), findsNothing);
  });
}
