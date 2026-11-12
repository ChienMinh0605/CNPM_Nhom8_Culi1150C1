/// Định dạng hiển thị theo NFR10.
library;

/// Tiền VNĐ, phân cách hàng nghìn bằng dấu chấm: 120000 -> "120.000 ₫".
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}$buffer ₫';
}

/// Ngày dạng dd/mm/yyyy.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
