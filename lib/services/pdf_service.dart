import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sinh_vien.dart';
import '../utils/dinh_dang.dart';

/// Xuất danh sách sinh viên ra file PDF
class PdfService {
  Future<File> xuatDanhSachSinhVien(List<SinhVien> ds, {String tieuDePhu = ''}) async {
    // Font Roboto để hiển thị tiếng Việt có dấu
    final fontThuong = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontDam = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: fontThuong, bold: fontDam));
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text('TRƯỜNG ĐẠI HỌC TÀI NGUYÊN VÀ MÔI TRƯỜNG TP.HCM',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          ),
          pw.Center(child: pw.Text('KHOA CÔNG NGHỆ THÔNG TIN')),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text('DANH SÁCH SINH VIÊN',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          ),
          if (tieuDePhu.isNotEmpty) pw.Center(child: pw.Text(tieuDePhu)),
          pw.Center(child: pw.Text('Ngày xuất: ${dinhDangThoiGian(now)}  -  Tổng số: ${ds.length} sinh viên')),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(36),
              1: pw.FixedColumnWidth(90),
              2: pw.FlexColumnWidth(),
              3: pw.FixedColumnWidth(60),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _o('STT', dam: true),
                  _o('MSSV', dam: true),
                  _o('Họ tên', dam: true),
                  _o('Ảnh', dam: true),
                ],
              ),
              for (var i = 0; i < ds.length; i++)
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    _o('${i + 1}'),
                    _o(ds[i].mssv),
                    _o(ds[i].hoTen),
                    _anh(ds[i].anhBase64),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();

    // Lưu file vào bộ nhớ của app (xem bằng Device Explorer: /sdcard/Android/data/<package>/files)
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/DanhSachSinhVien_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    // Mở màn hình xem trước / lưu PDF
    try {
      await Printing.layoutPdf(name: 'DanhSachSinhVien.pdf', onLayout: (_) async => bytes);
    } catch (_) {}

    return file;
  }

  pw.Widget _o(String text, {bool dam = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text, style: dam ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
      );

  pw.Widget _anh(String? base64Anh) {
    if (base64Anh == null || base64Anh.isEmpty) return _o('-');
    try {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Image(pw.MemoryImage(base64Decode(base64Anh)),
            width: 50, height: 50, fit: pw.BoxFit.cover),
      );
    } catch (_) {
      return _o('-');
    }
  }
}
