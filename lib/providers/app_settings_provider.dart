import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme/app_text.dart';

class AppSettingsProvider extends ChangeNotifier {
  final SettingsService _svc = SettingsService.instance;

  bool _loaded = false;
  FontScaleLevel _fontLevel = FontScaleLevel.normal;
  bool _lockEnabled = true;
  bool _biometricEnabled = false;
  bool _hasPassword = false;

  bool get loaded => _loaded;
  FontScaleLevel get fontLevel => _fontLevel;
  bool get lockEnabled => _lockEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasPassword => _hasPassword;

  AppText get textStyle => AppText(scale: _fontLevel.factor);

  Future<void> load() async {
    _fontLevel = await _svc.getFontLevel();
    _lockEnabled = await _svc.isLockEnabled();
    _biometricEnabled = await _svc.isBiometricEnabled();
    _hasPassword = await _svc.hasPassword();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setFontLevel(FontScaleLevel level) async {
    _fontLevel = level;
    notifyListeners();
    await _svc.setFontLevel(level);
  }

  Future<void> setLockEnabled(bool enabled) async {
    _lockEnabled = enabled;
    notifyListeners();
    await _svc.setLockEnabled(enabled);
    if (enabled) {
      _biometricEnabled = false;
      await _svc.setBiometricEnabled(false);
      notifyListeners();
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && !_lockEnabled) return;
    _biometricEnabled = enabled;
    notifyListeners();
    await _svc.setBiometricEnabled(enabled);
  }

  Future<void> setPassword(String pin) async {
    await _svc.setPassword(pin);
    _hasPassword = true;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPin, String newPin) async {
    final ok = await _svc.changePassword(oldPin, newPin);
    if (ok) notifyListeners();
    return ok;
  }

  Future<bool> verifyPassword(String pin) => _svc.verifyPassword(pin);
}
