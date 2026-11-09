/// MODEL: Sinh viên
class SinhVien {
  final String mssv;
  final String hoTen;

  /// Ảnh dạng chuỗi base64 (lưu trong SQL Server)
  final String? anhBase64;

  /// Mã môn học sinh viên đăng ký
  final String? maMon;

  const SinhVien({required this.mssv, required this.hoTen, this.anhBase64, this.maMon});

  factory SinhVien.fromJson(Map<String, dynamic> json) {
    return SinhVien(
      mssv: json['mssv'] as String? ?? '',
      hoTen: json['hoTen'] as String? ?? '',
      anhBase64: json['anh'] as String?,
      maMon: json['maMon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mssv': mssv,
        'hoTen': hoTen,
        'anh': anhBase64,
        'maMon': maMon,
      };
}
