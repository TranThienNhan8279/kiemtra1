import 'package:google_maps_flutter/google_maps_flutter.dart';

/// MODEL: Cơ sở của trường
class CoSo {
  final String ten;
  final String diaChi;
  final LatLng viTri;

  const CoSo({required this.ten, required this.diaChi, required this.viTri});
}
