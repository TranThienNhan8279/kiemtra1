import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mon_hoc.dart';
import '../models/sinh_vien.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';

/// CONTROLLER danh sách sinh viên: chọn môn, nhập (tay / Excel) -> database, xuất PDF
class SinhVienController {
  final ApiService _api = ApiService();
  final PdfService _pdf = PdfService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController mssv = TextEditingController();
  final TextEditingController hoTen = TextEditingController();
  File? anhMoi;

  List<MonHoc> dsMonHoc = [];

  /// null = xem tất cả môn
  String? maMonDangChon;

  List<SinhVien> danhSach = [];

  /// Tải môn học + sinh viên từ SQL Server (gọi định kỳ để đồng bộ với SSMS)
  Future<void> taiDanhSach() async {
    dsMonHoc = await _api.layDanhSachMonHoc();
    if (maMonDangChon != null && !dsMonHoc.any((m) => m.maMon == maMonDangChon)) {
      maMonDangChon = null; // môn đã bị xóa trong SSMS
    }
    danhSach = await _api.layDanhSachSinhVien(maMon: maMonDangChon);
  }

  String tenMon(String? ma) {
    if (ma == null) return 'Chưa chọn môn';
    for (final m in dsMonHoc) {
      if (m.maMon == ma) return m.tenMon;
    }
    return ma;
  }

  Future<String?> chupAnh() async {
    final quyen = await Permission.camera.request();
    if (!quyen.isGranted) return 'Chưa cấp quyền camera';
    final XFile? chup = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      imageQuality: 70,
    );
    if (chup == null) return 'Chưa chụp ảnh';
    anhMoi = File(chup.path);
    return null;
  }

  String? kiemTra() {
    final ma = mssv.text.trim();
    if (ma.isEmpty) return 'MSSV không được để trống';
    if (!RegExp(r'^\d{10}$').hasMatch(ma)) return 'MSSV phải gồm 10 chữ số';
    if (hoTen.text.trim().isEmpty) return 'Họ tên không được để trống';
    if (maMonDangChon == null) return 'Hãy chọn môn học';
    return null;
  }

  /// Thêm (hoặc cập nhật nếu trùng MSSV) sinh viên vào SQL Server
  Future<void> themSinhVien() async {
    final loi = kiemTra();
    if (loi != null) throw Exception(loi);

    String? anhBase64;
    if (anhMoi != null) anhBase64 = base64Encode(await anhMoi!.readAsBytes());

    await _api.luuSinhVien(SinhVien(
      mssv: mssv.text.trim(),
      hoTen: hoTen.text.trim(),
      anhBase64: anhBase64,
      maMon: maMonDangChon,
    ));

    mssv.clear();
    hoTen.clear();
    anhMoi = null;
    await taiDanhSach();
  }

  /// Chọn file Excel (STT | MSSV | Họ và tên) và nhập vào SQL Server. Trả về số SV, null nếu hủy
  Future<int?> nhapTuExcel() async {
    if (maMonDangChon == null) throw Exception('Hãy chọn môn học trước khi nhập Excel');

    final kq = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (kq == null || kq.files.isEmpty) return null;

    final file = kq.files.single;
    List<int>? bytes = file.bytes;
    if (bytes == null && file.path != null) bytes = await File(file.path!).readAsBytes();
    if (bytes == null) throw Exception('Không đọc được file');

    final soLuong = await _api.nhapExcel(bytes, maMonDangChon);
    await taiDanhSach();
    return soLuong;
  }

  Future<void> xoaSinhVien(String ma) async {
    await _api.xoaSinhVien(ma);
    await taiDanhSach();
  }

  /// Xuất PDF danh sách sinh viên hiện tại (theo môn đang chọn)
  Future<File> xuatPdf() async {
    await taiDanhSach();
    if (danhSach.isEmpty) throw Exception('Danh sách sinh viên đang trống');
    return _pdf.xuatDanhSachSinhVien(danhSach, tieuDePhu: 'Môn: ${tenMon(maMonDangChon)}');
  }

  void dispose() {
    mssv.dispose();
    hoTen.dispose();
  }
}
