import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lưu ảnh chụp từ camera vào bộ nhớ cục bộ của ứng dụng trên emulator
/// (thư mục `/data/data/<package>/app_flutter/` - Bài 6 & Bài 8)
class LocalStorageService {
  static const String _fileGhiNho = 'anh_nhom.txt';

  Future<Directory> get _thuMuc => getApplicationDocumentsDirectory();

  /// Copy ảnh tạm của camera vào thư mục ứng dụng và ghi nhớ đường dẫn vào file txt
  Future<File> luuAnh(File anhTam) async {
    final dir = await _thuMuc;
    final ten = 'anh_nhom_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final anhMoi = await anhTam.copy('${dir.path}/$ten');
    await File('${dir.path}/$_fileGhiNho').writeAsString(anhMoi.path);
    return anhMoi;
  }

  /// Đọc lại ảnh đã lưu ở lần trước (nếu có)
  Future<File?> docAnhDaLuu() async {
    try {
      final dir = await _thuMuc;
      final ghiNho = File('${dir.path}/$_fileGhiNho');
      if (!await ghiNho.exists()) return null;
      final anh = File((await ghiNho.readAsString()).trim());
      return await anh.exists() ? anh : null;
    } catch (_) {
      return null;
    }
  }
}
