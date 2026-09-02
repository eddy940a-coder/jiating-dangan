import 'package:flutter/foundation.dart';

import '../services/settings_service.dart';

/// 解锁隐藏成员档案的临时授权：本次会话内可访问。
class HiddenMemberUnlockProvider extends ChangeNotifier {
  final SettingsService _svc = SettingsService.instance;
  final Set<String> _unlocked = <String>{};

  bool isUnlocked(String memberId) => _unlocked.contains(memberId);

  /// 验证密码并把对应成员加进解锁集合。
  Future<bool> unlock(String memberId, String pin) async {
    final ok = await _svc.verifyPassword(pin);
    if (ok) {
      _unlocked.add(memberId);
      notifyListeners();
    }
    return ok;
  }

  void clear() {
    _unlocked.clear();
    notifyListeners();
  }
}
