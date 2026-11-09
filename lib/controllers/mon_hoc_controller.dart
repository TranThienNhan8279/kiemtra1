import 'package:flutter/material.dart';

import '../models/co_so.dart';
import '../models/mon_hoc.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/dinh_dang.dart';

/// CONTROLLER Trang 2: môn học, cơ sở, giờ học + thông báo
class MonHocController {
  final ApiService _api = ApiService();
  final NotificationService _thongBao = NotificationService.instance;

  final TextEditingController maMon = TextEditingController(text: '1');
  final TextEditingController tenMon = TextEditingController(text: 'Lập trình đa nền tảng');

  CoSo? coSo;
  DateTime? gioHoc;

  String? kiemTra() {
    if (maMon.text.trim().isEmpty) return 'Mã môn không được để trống';
    if (tenMon.text.trim().isEmpty) return 'Tên môn không được để trống';
    if (coSo == null) return 'Hãy chọn cơ sở';
    return null;
  }

  MonHoc taoMonHoc() => MonHoc(
        maMon: maMon.text.trim(),
        tenMon: tenMon.text.trim(),
        coSo: coSo!.ten,
        gioHoc: gioHoc?.toIso8601String(),
      );

  /// Lưu môn học vào SQL Server
  Future<void> luuMonHoc() async {
    final loi = kiemTra();
    if (loi != null) throw Exception(loi);
    await _api.luuMonHoc(taoMonHoc());
  }

  /// Hẹn thông báo đến giờ học
  Future<String> datNhacGioHoc() async {
    final gio = gioHoc;
    if (gio == null) return 'Hãy chọn giờ học';
    if (gio.isBefore(DateTime.now())) return 'Giờ học phải sau thời điểm hiện tại';

    await _thongBao.henGio(
      id: 1,
      thoiGian: gio,
      tieuDe: 'Đến giờ học: ${tenMon.text.trim()}',
      noiDung: 'Mã môn ${maMon.text.trim()} - Cơ sở ${coSo?.ten ?? "chưa chọn"}',
    );
    await _thongBao.hienNgay('Đã đặt lịch nhắc giờ học', 'Sẽ nhắc lúc ${dinhDangThoiGian(gio)}');
    return 'Đã hẹn thông báo lúc ${dinhDangThoiGian(gio)}';
  }

  /// Nhắc thử sau 1 phút (để demo nhanh)
  Future<String> nhacThuSau1Phut() async {
    final gio = DateTime.now().add(const Duration(minutes: 1));
    await _thongBao.henGio(
      id: 2,
      thoiGian: gio,
      tieuDe: 'Đến giờ học: ${tenMon.text.trim()}',
      noiDung: 'Cơ sở ${coSo?.ten ?? "chưa chọn"} - (nhắc thử sau 1 phút)',
    );
    return 'Sẽ có thông báo lúc ${dinhDangThoiGian(gio)}';
  }

  void dispose() {
    maMon.dispose();
    tenMon.dispose();
  }
}
