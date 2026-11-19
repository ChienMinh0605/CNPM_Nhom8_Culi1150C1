import 'dart:convert';

import 'package:dcsv_frontend/core/api_client.dart';
import 'package:dcsv_frontend/features/checkin/check_in_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);

Future<List<String>> _pump(WidgetTester tester, Object reply) async {
  final sent = <String>[];
  // Màn cao để ô nhập mã nằm trong khung nhìn.
  tester.view.physicalSize = const Size(480, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CheckInPage(
        useCamera: false,
        api: ApiClient(
          baseUrl: '',
          httpClient: MockClient((request) async {
            sent.add('${request.method} ${request.url.path} ${request.body}');
            return _json(reply);
          }),
        ),
      ),
    ),
  );
  return sent;
}

Future<void> _enter(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.text('Kiểm tra'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vé hợp lệ hiện số khách theo loại vé', (tester) async {
    final sent = await _pump(tester, {
      'valid': true,
      'reason': '',
      'order': {
        'code': 'ABC',
        'startTime': '08:00',
        'endTime': '10:00',
        'items': [
          {'name': 'Người lớn', 'quantity': 2, 'unitPrice': 40000},
          {'name': 'Trẻ em', 'quantity': 1, 'unitPrice': 10000},
        ],
      },
    });
    await _enter(tester, 'abc');

    expect(sent.single, 'POST /api/v1/check-in {"code":"abc"}');
    expect(find.text('HỢP LỆ'), findsOneWidget);
    expect(find.text('3 khách'), findsOneWidget);
    expect(find.text('2 × Người lớn'), findsOneWidget);

    // Đang hiện kết quả thì không gửi thêm; bấm Quét vé tiếp để soát vé khác.
    await tester.tap(find.text('Quét vé tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('HỢP LỆ'), findsNothing);

    // Camera bỏ qua mã vừa soát, còn nhập tay thì vẫn soát lại được.
    await _enter(tester, 'abc');
    expect(sent, hasLength(2));
  });

  testWidgets('vé không hợp lệ hiện lý do', (tester) async {
    await _pump(tester, {
      'valid': false,
      'reason': 'Vé đã được sử dụng lúc 09:05 ngày 21/11/2026',
      'order': null,
    });
    await _enter(tester, 'XYZ');

    expect(find.text('KHÔNG HỢP LỆ'), findsOneWidget);
    expect(
      find.text('Vé đã được sử dụng lúc 09:05 ngày 21/11/2026'),
      findsOneWidget,
    );
  });
}
