import 'dart:convert';

import 'package:dcsv_frontend/core/api_client.dart';
import 'package:dcsv_frontend/features/portal/payment_result_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

Map<String, dynamic> _order(String status, String responseCode) => {
  'code': 'ABC123',
  'status': status,
  'responseCode': responseCode,
  'visitDate': '2026-11-21',
  'startTime': '08:00',
  'endTime': '10:00',
  'totalAmount': 80000,
  'items': [
    {'name': 'Người lớn', 'quantity': 2, 'unitPrice': 40000},
  ],
};

Future<List<Uri>> _pump(WidgetTester tester, http.Response response) async {
  final requested = <Uri>[];
  await tester.pumpWidget(
    MaterialApp(
      home: PaymentResultPage(
        query: 'vnp_TxnRef=ABC123&vnp_SecureHash=ff',
        api: ApiClient(
          baseUrl: '',
          httpClient: MockClient((request) async {
            requested.add(request.url);
            return response;
          }),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requested;
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  testWidgets('đã thanh toán thì hiện mã QR và chi tiết đơn', (tester) async {
    final requested = await _pump(tester, _json(_order('PAID', '00')));

    expect(requested.single.path, '/api/v1/payment/return');
    expect(requested.single.query, 'vnp_TxnRef=ABC123&vnp_SecureHash=ff');
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Mã đơn ABC123'), findsOneWidget);
    expect(find.text('21/11/2026'), findsOneWidget);
    expect(find.text('80.000 ₫'), findsNWidgets(2));
  });

  testWidgets('VNPay báo thất bại thì mời đặt lại, không có QR', (
    tester,
  ) async {
    await _pump(tester, _json(_order('PENDING', '24')));
    expect(find.text('Thanh toán chưa thành công'), findsOneWidget);
    expect(find.text('Đặt vé lại'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('chờ IPN thì có nút Kiểm tra lại', (tester) async {
    await _pump(tester, _json(_order('PENDING', '00')));
    expect(find.text('Đang xác nhận thanh toán'), findsOneWidget);
    expect(find.text('Kiểm tra lại'), findsOneWidget);
  });

  testWidgets('sai chữ ký thì báo lỗi', (tester) async {
    await _pump(
      tester,
      _json({
        'error': {
          'code': 'INVALID_SIGNATURE',
          'message': 'Kết quả thanh toán không hợp lệ',
        },
      }, 400),
    );
    expect(find.text('Kết quả thanh toán không hợp lệ'), findsOneWidget);
  });
}
