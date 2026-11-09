import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../controllers/sinh_vien_controller.dart';
import '../models/sinh_vien.dart';
import '../utils/dinh_dang.dart';

/// VIEW: chọn môn học, nhập sinh viên (tay / Excel) -> SQL Server, xuất PDF
/// Tự đồng bộ với SQL Server mỗi 3 giây (thêm/xóa trong SSMS sẽ hiện lên app)
class SinhVienView extends StatefulWidget {
  const SinhVienView({super.key});

  @override
  State<SinhVienView> createState() => _SinhVienViewState();
}

class _SinhVienViewState extends State<SinhVienView> {
  final SinhVienController _controller = SinhVienController();
  final Map<String, Uint8List> _boNhoAnh = {};
  Timer? _dongBo;
  bool _dangTai = false;
  bool _loiKetNoi = false;

  @override
  void initState() {
    super.initState();
    _taiLai(hienLoi: true);
    _dongBo = Timer.periodic(const Duration(seconds: 3), (_) => _taiLai());
  }

  @override
  void dispose() {
    _dongBo?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _thongBao(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _taiLai({bool hienLoi = false}) async {
    if (_dangTai) return;
    _dangTai = true;
    try {
      await _controller.taiDanhSach();
      _loiKetNoi = false;
    } catch (e) {
      if (hienLoi || !_loiKetNoi) _thongBao('Không kết nối được API: ${thongDiepLoi(e)}');
      _loiKetNoi = true;
    } finally {
      _dangTai = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _chupAnh() async {
    final loi = await _controller.chupAnh();
    if (!mounted) return;
    setState(() {});
    if (loi != null) _thongBao(loi);
  }

  Future<void> _them() async {
    try {
      await _controller.themSinhVien();
      _boNhoAnh.clear();
      _thongBao('Đã lưu sinh viên vào SQL Server');
    } catch (e) {
      _thongBao('Lỗi: ${thongDiepLoi(e)}');
    }
    if (mounted) setState(() {});
  }

  Future<void> _nhapExcel() async {
    try {
      final soLuong = await _controller.nhapTuExcel();
      if (soLuong == null) return;
      _thongBao('Đã nhập $soLuong sinh viên từ Excel vào SQL Server');
    } catch (e) {
      _thongBao('Lỗi nhập Excel: ${thongDiepLoi(e)}');
    }
    if (mounted) setState(() {});
  }

  Future<void> _xoa(SinhVien sv) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Xóa sinh viên ${sv.hoTen} (${sv.mssv})?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa')),
        ],
      ),
    );
    if (dongY != true) return;
    try {
      await _controller.xoaSinhVien(sv.mssv);
      _boNhoAnh.remove(sv.mssv);
      if (mounted) setState(() {});
      _thongBao('Đã xóa ${sv.mssv}');
    } catch (e) {
      _thongBao('Lỗi: ${thongDiepLoi(e)}');
    }
  }

  Future<void> _xuatPdf() async {
    try {
      final file = await _controller.xuatPdf();
      if (mounted) setState(() {});
      _thongBao('Đã xuất PDF: ${file.path}');
    } catch (e) {
      _thongBao('Lỗi xuất PDF: ${thongDiepLoi(e)}');
    }
  }

  ImageProvider? _anhCua(SinhVien sv) {
    final b64 = sv.anhBase64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return MemoryImage(_boNhoAnh.putIfAbsent(sv.mssv, () => base64Decode(b64)));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = _controller.danhSach;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- CHỌN MÔN HỌC ----------
          Row(
            children: [
              const Text('Môn học: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _controller.maMonDangChon,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('-- Tất cả môn --')),
                    for (final m in _controller.dsMonHoc)
                      DropdownMenuItem<String?>(value: m.maMon, child: Text('${m.maMon} - ${m.tenMon}')),
                  ],
                  onChanged: (v) {
                    setState(() => _controller.maMonDangChon = v);
                    _taiLai(hienLoi: true);
                  },
                ),
              ),
            ],
          ),
          // ---------- FORM NHẬP ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _chupAnh,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: _controller.anhMoi != null ? FileImage(_controller.anhMoi!) : null,
                      child: _controller.anhMoi == null ? const Icon(Icons.camera_alt, size: 26) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller.mssv,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'MSSV', isDense: true),
                        ),
                        TextField(
                          controller: _controller.hoTen,
                          decoration: const InputDecoration(labelText: 'Họ tên', isDense: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                  onPressed: _them, icon: const Icon(Icons.person_add), label: const Text('Lưu vào CSDL')),
              ElevatedButton.icon(
                  onPressed: _nhapExcel, icon: const Icon(Icons.upload_file), label: const Text('Nhập Excel')),
              ElevatedButton.icon(
                  onPressed: _xuatPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('Xuất PDF')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Danh sách hiện tại (${ds.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Icon(_loiKetNoi ? Icons.cloud_off : Icons.sync,
                  size: 18, color: _loiKetNoi ? Colors.red : Colors.green),
              Text(_loiKetNoi ? ' Mất kết nối' : ' Đồng bộ 3s',
                  style: TextStyle(fontSize: 12, color: _loiKetNoi ? Colors.red : Colors.green)),
            ],
          ),
          const Divider(),
          // ---------- DANH SÁCH ----------
          Expanded(
            child: ds.isEmpty
                ? const Center(child: Text('Chưa có sinh viên nào'))
                : ListView.builder(
                    itemCount: ds.length,
                    itemBuilder: (context, index) {
                      final sv = ds[index];
                      final anh = _anhCua(sv);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: anh,
                            child: anh == null ? Text('${index + 1}') : null,
                          ),
                          title: Text(sv.hoTen, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('MSSV: ${sv.mssv}\nMôn: ${_controller.tenMon(sv.maMon)}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _xoa(sv),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
