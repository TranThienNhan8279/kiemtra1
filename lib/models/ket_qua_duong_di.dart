import 'package:google_maps_flutter/google_maps_flutter.dart';

/// MODEL: Kết quả tìm đường từ OSRM
class KetQuaDuongDi {
  final List<LatLng> diem; // các điểm để vẽ polyline
  final double khoangCachKm;
  final double thoiGianPhut;

  const KetQuaDuongDi({
    required this.diem,
    required this.khoangCachKm,
    required this.thoiGianPhut,
  });
}
