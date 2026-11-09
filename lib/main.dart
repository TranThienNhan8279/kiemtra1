import 'package:flutter/material.dart';

import 'services/notification_service.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Khởi tạo thông báo lỗi: $e');
  }
  runApp(const KiemTraApp());
}

class KiemTraApp extends StatelessWidget {
  const KiemTraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KT-GK Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomeView(),
    );
  }
}
