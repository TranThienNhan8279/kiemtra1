import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config.dart';
import '../controllers/ban_do_controller.dart';
import '../controllers/mon_hoc_controller.dart';
import '../models/co_so.dart';
import '../utils/dinh_dang.dart';

/// VIEW Trang 2: Môn học - Mã môn - Tên môn - Cơ sở (Nhà Bè / Lê Văn Sỹ) - Map
class Trang2View extends StatefulWidget {
  const Trang2View({super.key});

  @override
  State<Trang2View> createState() => _Trang2ViewState();
}

class _Trang2ViewState extends State<Trang2View> {
  final MonHocController _monHoc = MonHocController();
  final BanDoController _banDo = BanDoController();
  final Completer<GoogleMapController> _mapController = Completer();
  bool _dangTim = false;

  @override
  void initState() {
    super.initState();
    _banDo.onKeoDiemBatDau = _chonDiemBatDau;
    WidgetsBinding.instance.addPostFrameCallback((_) => _layViTri());
  }

  /// Chạm / kéo trên bản đồ để chọn điểm xuất phát khác, rồi chỉ đường về cơ sở
  Future<void> _chonDiemBatDau(LatLng p) async {
    setState(() => _banDo.chonDiemBatDau(p));
    if (_monHoc.coSo != null) {
      await _timDuong();
    } else {
      _thongBao('Đã chọn điểm xuất phát. Hãy chọn cơ sở để chỉ đường.');
    }
  }

  @override
  void dispose() {
    _monHoc.dispose();
    super.dispose();
  }

  void _thongBao(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- ĐỊNH VỊ + TÌM ĐƯỜNG ----------------
  Future<void> _layViTri() async {
    final canhBao = await _banDo.capNhatViTriHienTai();
    if (!mounted) return;
    setState(() {});
    if (canhBao != null) _thongBao(canhBao);
    if (_monHoc.coSo != null) {
      await _timDuong();
    } else {
      await _diChuyenCamera([_banDo.viTriBatDau]);
    }
  }

  Future<void> _chonCoSo() async {
    final coSo = await showDialog<CoSo>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn cơ sở'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cs in AppConfig.dsCoSo)
              ListTile(
                leading: Icon(
                  cs.ten == _monHoc.coSo?.ten ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.blue,
                ),
                title: Text(cs.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cs.diaChi),
                onTap: () => Navigator.of(ctx).pop(cs),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
        ],
      ),
    );
    if (coSo == null) return;
    setState(() => _monHoc.coSo = coSo);
    await _timDuong();
  }

  Future<void> _timDuong() async {
    final coSo = _monHoc.coSo;
    if (coSo == null) {
      _thongBao('Hãy chọn cơ sở');
      return;
    }
    setState(() => _dangTim = true);
    try {
      await _banDo.timDuongDen(coSo);
      if (!mounted) return;
      setState(() {});
      await _diChuyenCamera(_banDo.ketQua!.diem);
    } catch (e) {
      _thongBao('Lỗi tìm đường: ${thongDiepLoi(e)}');
    } finally {
      if (mounted) setState(() => _dangTim = false);
    }
  }

  Future<void> _diChuyenCamera(List<LatLng> diem) async {
    if (diem.isEmpty) return;
    final c = await _mapController.future;
    if (diem.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(diem.first, 14));
      return;
    }
    double minLat = diem.first.latitude, maxLat = diem.first.latitude;
    double minLng = diem.first.longitude, maxLng = diem.first.longitude;
    for (final p in diem) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    await c.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      50,
    ));
  }

  // ---------------- GIỜ HỌC + THÔNG BÁO ----------------
  Future<void> _chonGioHoc() async {
    final now = DateTime.now();
    final ngay = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (ngay == null || !mounted) return;
    final gio = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 2))),
    );
    if (gio == null) return;
    setState(() => _monHoc.gioHoc = DateTime(ngay.year, ngay.month, ngay.day, gio.hour, gio.minute));
  }

  Future<void> _datNhac() async {
    try {
      _thongBao(await _monHoc.datNhacGioHoc());
    } catch (e) {
      _thongBao('Lỗi đặt thông báo: ${thongDiepLoi(e)}');
    }
  }

  Future<void> _nhacThu() async {
    try {
      _thongBao(await _monHoc.nhacThuSau1Phut());
    } catch (e) {
      _thongBao('Lỗi đặt thông báo: ${thongDiepLoi(e)}');
    }
  }

  Future<void> _luuMonHoc() async {
    try {
      await _monHoc.luuMonHoc();
      _thongBao('Đã lưu môn học vào SQL Server');
    } catch (e) {
      _thongBao('Lỗi: ${thongDiepLoi(e)}');
    }
  }

  // ---------------- GIAO DIỆN ----------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade900, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('Môn học',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            ),
            const SizedBox(height: 12),
            _dongNhap('Mã môn:', _monHoc.maMon),
            const SizedBox(height: 10),
            _dongNhap('Tên môn:', _monHoc.tenMon),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Cơ sở:', style: TextStyle(fontSize: 16))),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chonCoSo,
                    icon: const Icon(Icons.location_city),
                    label: Text(_monHoc.coSo?.ten ?? 'Chọn cơ sở (Nhà Bè / Lê Văn Sỹ)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Giờ học:', style: TextStyle(fontSize: 16))),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chonGioHoc,
                    icon: const Icon(Icons.access_time),
                    label: Text(_monHoc.gioHoc == null ? 'Chọn ngày giờ học' : dinhDangThoiGian(_monHoc.gioHoc!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                    onPressed: _luuMonHoc, icon: const Icon(Icons.save), label: const Text('Lưu môn học')),
                ElevatedButton.icon(
                    onPressed: _datNhac,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Nhắc giờ học')),
                TextButton.icon(
                    onPressed: _nhacThu, icon: const Icon(Icons.timer), label: const Text('Nhắc thử sau 1 phút')),
              ],
            ),
            const Divider(height: 24),
            Text(_banDo.moTaDiemBatDau, style: const TextStyle(color: Colors.indigo)),
            Text(_dangTim ? 'Đang tìm đường...' : _banDo.moTaKetQua,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Text('Chạm vào bản đồ (hoặc kéo marker xanh) để chọn điểm xuất phát khác',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _layViTri,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Vị trí hiện tại'),
                ),
                ElevatedButton.icon(
                  onPressed: _dangTim ? null : _timDuong,
                  icon: const Icon(Icons.directions),
                  label: Text('Chỉ đường đến ${_monHoc.coSo?.ten ?? "cơ sở"}'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 340,
              decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: AppConfig.viTriMacDinh, zoom: 12),
                markers: _banDo.markers,
                polylines: _banDo.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                onTap: _chonDiemBatDau,
                onMapCreated: (c) {
                  if (!_mapController.isCompleted) _mapController.complete(c);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dongNhap(String nhan, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(nhan, style: const TextStyle(fontSize: 16))),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
      ],
    );
  }
}
