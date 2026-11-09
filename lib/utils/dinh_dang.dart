String _hai(int n) => n.toString().padLeft(2, '0');

/// Định dạng dd/MM/yyyy HH:mm
String dinhDangThoiGian(DateTime t) =>
    '${_hai(t.day)}/${_hai(t.month)}/${t.year} ${_hai(t.hour)}:${_hai(t.minute)}';

/// Bỏ chữ "Exception: " khi hiển thị lỗi
String thongDiepLoi(Object e) => e.toString().replaceFirst('Exception: ', '');
