import 'package:dcsv_frontend/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatVnd phân cách hàng nghìn bằng dấu chấm', () {
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(999), '999 ₫');
    expect(formatVnd(40000), '40.000 ₫');
    expect(formatVnd(1250000), '1.250.000 ₫');
  });

  test('formatDate trả về dd/mm/yyyy', () {
    expect(formatDate(DateTime(2026, 11, 3)), '03/11/2026');
  });
}
