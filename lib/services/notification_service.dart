import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thông báo cục bộ (Bài 8)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  /// Xin quyền thông báo (Android 13+)
  Future<void> xinQuyen() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  NotificationDetails _chiTiet() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'gio_hoc_channel',
          'Nhắc giờ học',
          channelDescription: 'Thông báo khi đến giờ học',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      );

  /// Hiện thông báo ngay
  Future<void> hienNgay(String tieuDe, String noiDung) {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return _plugin.show(id, tieuDe, noiDung, _chiTiet());
  }

  /// Hẹn giờ hiện thông báo
  Future<void> henGio({
    required int id,
    required DateTime thoiGian,
    required String tieuDe,
    required String noiDung,
  }) async {
    final lich = tz.TZDateTime.from(thoiGian, tz.local);
    try {
      await _plugin.zonedSchedule(id, tieuDe, noiDung, lich, _chiTiet(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Android 14 có thể chưa cho phép báo thức chính xác -> dùng chế độ không chính xác
      await _plugin.zonedSchedule(id, tieuDe, noiDung, lich, _chiTiet(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}
