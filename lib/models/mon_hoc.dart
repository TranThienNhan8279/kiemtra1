/// MODEL: Môn học
class MonHoc {
  final String maMon;
  final String tenMon;
  final String coSo;

  /// Giờ học dạng ISO-8601 (có thể null)
  final String? gioHoc;

  const MonHoc({
    required this.maMon,
    required this.tenMon,
    required this.coSo,
    this.gioHoc,
  });

  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      maMon: json['maMon'] as String? ?? '',
      tenMon: json['tenMon'] as String? ?? '',
      coSo: json['coSo'] as String? ?? '',
      gioHoc: json['gioHoc'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'maMon': maMon,
        'tenMon': tenMon,
        'coSo': coSo,
        'gioHoc': gioHoc,
      };
}
