import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config.dart';
import '../models/co_so.dart';
import '../models/ket_qua_duong_di.dart';
import '../services/location_service.dart';
import '../services/osrm_service.dart';
import '../utils/dinh_dang.dart';

/// CONTROLLER bản đồ: định vị + vẽ polyline đường đi (OSRM)
class BanDoController {
  final LocationService _location = LocationService();
  final OsrmService _osrm = OsrmService();

  LatLng viTriBatDau = AppConfig.viTriMacDinh;
  bool laViTriThat = false;

  /// true khi người dùng tự chọn điểm xuất phát trên bản đồ
  bool laDiemTuChon = false;

  /// View gán hàm này để xử lý khi kéo marker điểm xuất phát
  void Function(LatLng)? onKeoDiemBatDau;
  KetQuaDuongDi? ketQua;

  // Luôn tạo Set mới để GoogleMap nhận ra thay đổi
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  /// Lấy vị trí hiện tại. Trả về cảnh báo (null nếu ổn)
  Future<String?> capNhatViTriHienTai() async {
    String? canhBao;
    try {
      final vt = await _location.layViTriHienTai();
      final kc = _location.khoangCachMet(vt, AppConfig.viTriMacDinh);
      if (kc > 100000) {
        // Máy ảo mặc định ở Mỹ -> OSRM không tìm được đường về TP.HCM
        viTriBatDau = AppConfig.viTriMacDinh;
        laViTriThat = false;
        canhBao = 'Vị trí máy ảo cách TP.HCM ${(kc / 1000).toStringAsFixed(0)} km. '
            'Đang dùng điểm mặc định TP.HCM (đặt lại Location của emulator).';
      } else {
        viTriBatDau = vt;
        laViTriThat = true;
      }
      laDiemTuChon = false;
    } catch (e) {
      viTriBatDau = AppConfig.viTriMacDinh;
      laViTriThat = false;
      canhBao = '${thongDiepLoi(e)}. Đang dùng điểm mặc định TP.HCM.';
    }
    _capNhatMarkerBatDau();
    return canhBao;
  }

  /// Chọn một vị trí khác trên bản đồ làm điểm xuất phát
  void chonDiemBatDau(LatLng p) {
    viTriBatDau = p;
    laViTriThat = false;
    laDiemTuChon = true;
    _capNhatMarkerBatDau();
  }

  String get moTaDiemBatDau {
    final p = '${viTriBatDau.latitude.toStringAsFixed(5)}, ${viTriBatDau.longitude.toStringAsFixed(5)}';
    if (laDiemTuChon) return 'Xuất phát: điểm đã chọn ($p)';
    if (laViTriThat) return 'Xuất phát: vị trí hiện tại ($p)';
    return 'Xuất phát: mặc định TP.HCM ($p)';
  }

  void _capNhatMarkerBatDau() {
    final batDau = Marker(
      markerId: const MarkerId('batdau'),
      position: viTriBatDau,
      draggable: true,
      onDragEnd: (p) => onKeoDiemBatDau?.call(p),
      infoWindow: InfoWindow(
          title: laDiemTuChon
              ? 'Điểm xuất phát đã chọn'
              : (laViTriThat ? 'Vị trí của bạn' : 'Điểm xuất phát (mặc định)')),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
    markers = {
      ...markers.where((m) => m.markerId.value != 'batdau'),
      batDau,
    };
  }

  /// Tìm đường từ vị trí hiện tại đến cơ sở đã chọn và vẽ polyline
  Future<void> timDuongDen(CoSo coSo) async {
    final kq = await _osrm.timDuong(viTriBatDau, coSo.viTri);
    ketQua = kq;

    final dich = Marker(
      markerId: const MarkerId('dich'),
      position: coSo.viTri,
      infoWindow: InfoWindow(title: 'Cơ sở ${coSo.ten}', snippet: coSo.diaChi),
    );
    markers = {
      ...markers.where((m) => m.markerId.value != 'dich'),
      dich,
    };
    polylines = {
      Polyline(
        polylineId: const PolylineId('duongdi'),
        points: kq.diem,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  String get moTaKetQua {
    final kq = ketQua;
    if (kq == null) return 'Chọn cơ sở để tìm đường đi';
    return 'Khoảng cách: ${kq.khoangCachKm.toStringAsFixed(1)} km  -  '
        'Thời gian: ${kq.thoiGianPhut.toStringAsFixed(0)} phút (OSRM)';
  }
}
