import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/mon_hoc.dart';
import '../models/sinh_vien.dart';

/// Gọi Web API (ASP.NET Core) -> SQL Server
class ApiService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {'Content-Type': 'application/json; charset=utf-8'};

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  dynamic _xuLy(http.Response r) {
    final body = utf8.decode(r.bodyBytes);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API lỗi ${r.statusCode}: $body');
    }
    return body.isEmpty ? null : jsonDecode(body);
  }

  // ---------------- SINH VIÊN ----------------
  Future<List<SinhVien>> layDanhSachSinhVien({String? maMon}) async {
    final path = (maMon == null || maMon.isEmpty)
        ? '/sinhvien'
        : '/sinhvien?maMon=${Uri.encodeQueryComponent(maMon)}';
    final r = await http.get(_uri(path)).timeout(_timeout);
    final List data = _xuLy(r) as List;
    return data.map((e) => SinhVien.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> luuSinhVien(SinhVien sv) async {
    final r = await http
        .post(_uri('/sinhvien'), headers: _headers, body: jsonEncode(sv.toJson()))
        .timeout(_timeout);
    _xuLy(r);
  }

  /// Gửi file Excel lên API để nhập danh sách sinh viên vào SQL Server. Trả về số SV đã nhập
  Future<int> nhapExcel(List<int> bytes, String? maMon) async {
    final r = await http
        .post(_uri('/sinhvien/import'),
            headers: _headers,
            body: jsonEncode({'fileBase64': base64Encode(bytes), 'maMon': maMon}))
        .timeout(const Duration(seconds: 60));
    final data = _xuLy(r) as Map<String, dynamic>;
    return (data['soLuong'] as num).toInt();
  }

  Future<void> xoaSinhVien(String mssv) async {
    final r = await http.delete(_uri('/sinhvien/$mssv')).timeout(_timeout);
    _xuLy(r);
  }

  // ---------------- MÔN HỌC ----------------
  Future<List<MonHoc>> layDanhSachMonHoc() async {
    final r = await http.get(_uri('/monhoc')).timeout(_timeout);
    final List data = _xuLy(r) as List;
    return data.map((e) => MonHoc.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> luuMonHoc(MonHoc mh) async {
    final r = await http
        .post(_uri('/monhoc'), headers: _headers, body: jsonEncode(mh.toJson()))
        .timeout(_timeout);
    _xuLy(r);
  }
}
