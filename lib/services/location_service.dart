import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Định vị bằng GPS (Bài 7)
class LocationService {
  Future<LatLng> layViTriHienTai() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Vui lòng bật dịch vụ vị trí (GPS)');
    }

    LocationPermission quyen = await Geolocator.checkPermission();
    if (quyen == LocationPermission.denied) {
      quyen = await Geolocator.requestPermission();
    }
    if (quyen == LocationPermission.denied || quyen == LocationPermission.deniedForever) {
      throw Exception('Chưa cấp quyền truy cập vị trí');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Máy ảo đôi khi chưa có tín hiệu -> lấy vị trí gần nhất
      final cu = await Geolocator.getLastKnownPosition();
      if (cu == null) rethrow;
      return LatLng(cu.latitude, cu.longitude);
    }
  }

  double khoangCachMet(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
}
