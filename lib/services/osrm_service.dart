import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/ket_qua_duong_di.dart';

/// Tìm đường đi bằng OSRM (thay cho Google Directions API)
class OsrmService {
  Future<KetQuaDuongDi> timDuong(LatLng batDau, LatLng ketThuc) async {
    // OSRM nhận tọa độ theo thứ tự: kinh độ,vĩ độ
    final url = '${AppConfig.osrmBaseUrl}/route/v1/driving/'
        '${batDau.longitude},${batDau.latitude};${ketThuc.longitude},${ketThuc.latitude}'
        '?overview=full&geometries=geojson';

    final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception('OSRM lỗi ${r.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(utf8.decode(r.bodyBytes));
    final List routes = (data['routes'] as List?) ?? [];
    if (data['code'] != 'Ok' || routes.isEmpty) {
      throw Exception('Không tìm thấy đường đi (${data['code']})');
    }

    final route = routes.first as Map<String, dynamic>;
    final List toaDo = route['geometry']['coordinates'] as List;
    final diem = toaDo
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return KetQuaDuongDi(
      diem: diem,
      khoangCachKm: (route['distance'] as num).toDouble() / 1000,
      thoiGianPhut: (route['duration'] as num).toDouble() / 60,
    );
  }
}
