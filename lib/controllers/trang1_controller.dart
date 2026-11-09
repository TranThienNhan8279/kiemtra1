import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../models/sinh_vien.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

/// CONTROLLER Trang 1: thông tin nhóm + chụp ảnh camera + lưu cục bộ
class Trang1Controller {
  final ImagePicker _picker = ImagePicker();
  final LocalStorageService _local = LocalStorageService();
  final ApiService _api = ApiService();

  File? anh;

  List<SinhVien> get nhom => AppConfig.nhom;

  Future<void> taiAnhDaLuu() async {
    anh = await _local.docAnhDaLuu();
  }

  /// Chụp ảnh từ camera của emulator và lưu cục bộ. Trả về thông báo lỗi (null nếu thành công)
  Future<String?> chupAnh() async {
    final quyen = await Permission.camera.request();
    if (!quyen.isGranted) return 'Chưa cấp quyền camera';

    final XFile? chup = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (chup == null) return 'Chưa chụp ảnh';

    anh = await _local.luuAnh(File(chup.path));
    return null;
  }

  /// Lưu 2 sinh viên của nhóm (kèm ảnh) vào SQL Server qua API
  Future<void> luuNhomVaoCsdl() async {
    final String? anhBase64 = anh != null ? base64Encode(await anh!.readAsBytes()) : null;
    for (final sv in nhom) {
      await _api.luuSinhVien(SinhVien(mssv: sv.mssv, hoTen: sv.hoTen, anhBase64: anhBase64));
    }
  }
}
