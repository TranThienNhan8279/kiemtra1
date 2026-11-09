import 'package:flutter/material.dart';

import '../controllers/trang1_controller.dart';
import '../models/sinh_vien.dart';
import '../utils/dinh_dang.dart';

/// VIEW Trang 1: ĐH TN&MT TP.HCM - Khoa CNTT - KT-GK - Flutter - MSSV - Họ tên - Ảnh chụp từ camera
class Trang1View extends StatefulWidget {
  const Trang1View({super.key});

  @override
  State<Trang1View> createState() => _Trang1ViewState();
}

class _Trang1ViewState extends State<Trang1View> {
  final Trang1Controller _controller = Trang1Controller();
  bool _dangLuu = false;

  @override
  void initState() {
    super.initState();
    _controller.taiAnhDaLuu().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _thongBao(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _chupAnh() async {
    final loi = await _controller.chupAnh();
    if (!mounted) return;
    setState(() {});
    _thongBao(loi ?? 'Đã lưu ảnh cục bộ: ${_controller.anh!.path}');
  }

  Future<void> _luuNhom() async {
    setState(() => _dangLuu = true);
    try {
      await _controller.luuNhomVaoCsdl();
      _thongBao('Đã lưu ${_controller.nhom.length} sinh viên (kèm ảnh) vào SQL Server');
    } catch (e) {
      _thongBao('Lỗi: ${thongDiepLoi(e)}');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade900, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'TRƯỜNG ĐH TÀI NGUYÊN VÀ MÔI TRƯỜNG TP.HCM',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 6),
            const Text('Khoa Công nghệ Thông tin', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('KT-GK', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red)),
            const Text('Flutter',
                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.blue)),
            const Divider(height: 28, thickness: 1),
            _bangThongTin(_controller.nhom),
            const SizedBox(height: 16),
            _khungAnh(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _chupAnh,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _dangLuu ? null : _luuNhom,
                    icon: _dangLuu
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Lưu vào CSDL'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bangThongTin(List<SinhVien> ds) {
    const dam = TextStyle(fontWeight: FontWeight.bold);
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(8), child: Text('MSSV', style: dam)),
            Padding(padding: EdgeInsets.all(8), child: Text('Họ tên', style: dam)),
          ],
        ),
        for (final sv in ds)
          TableRow(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(sv.mssv)),
            Padding(padding: const EdgeInsets.all(8), child: Text(sv.hoTen)),
          ]),
      ],
    );
  }

  Widget _khungAnh() {
    final anh = _controller.anh;
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: anh == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text('Ảnh chụp từ Camera', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(anh, key: ValueKey(anh.path), fit: BoxFit.cover),
            ),
    );
  }
}
