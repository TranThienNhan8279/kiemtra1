import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'sinh_vien_view.dart';
import 'trang1_view.dart';
import 'trang2_view.dart';

/// VIEW chính: BottomNavigationBar chuyển giữa các trang (Bài 4)
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  static const List<String> _tieuDe = [
    'Trang 1 - Thông tin nhóm',
    'Trang 2 - Môn học',
    'Danh sách sinh viên',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.xinQuyen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tieuDe[_index]),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _index,
        children: const [Trang1View(), Trang2View(), SinhVienView()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.blue[900],
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Trang 1'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Trang 2'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sinh viên'),
        ],
      ),
    );
  }
}
