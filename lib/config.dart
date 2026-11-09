import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/co_so.dart';
import 'models/sinh_vien.dart';

/// Cấu hình chung của ứng dụng
class AppConfig {
  /// Máy ảo Android gọi về máy tính qua 10.0.2.2.
  /// Nếu chạy máy thật: đổi thành IP LAN của máy tính, ví dụ http://192.168.1.10:5000/api
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

  /// Server tìm đường OSRM (miễn phí, không cần API key)
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  /// Thông tin nhóm (Trang 1)
  static const List<SinhVien> nhom = [
    SinhVien(mssv: '1250080123', hoTen: 'Trần Thiện Nhân'),
    SinhVien(mssv: '1250080159', hoTen: 'Mai Phước Sang'),
  ];

  /// Các cơ sở của trường (Trang 2)
  static const List<CoSo> dsCoSo = [
    CoSo(
      ten: 'Nhà Bè',
      diaChi: 'Xã Hiệp Phước (Nhà Bè cũ), TP.HCM',
      viTri: LatLng(10.6643, 106.7155),
    ),
    CoSo(
      ten: 'Lê Văn Sỹ',
      diaChi: '236B Lê Văn Sỹ, P. Tân Sơn Hòa, TP.HCM',
      viTri: LatLng(10.7977, 106.6658),
    ),
  ];

  /// Điểm mặc định (TP.HCM) khi không lấy được vị trí thật
  static const LatLng viTriMacDinh = LatLng(10.7769, 106.7009);
}
