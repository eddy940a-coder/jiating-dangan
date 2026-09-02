import 'package:flutter/foundation.dart';

/// 控制底部 Tab 切换的全局索引（仅在已解锁后使用）。
class TabIndexProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  void set(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}
