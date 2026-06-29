import 'package:shared_preferences/shared_preferences.dart';

const _hostKey = 'rtk_mac_host';
const _portKey = 'rtk_mac_port';

class HostPrefs {
  HostPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<HostPrefs> load() async {
    return HostPrefs(await SharedPreferences.getInstance());
  }

  String? get host => _prefs.getString(_hostKey);

  String get port => _prefs.getString(_portKey) ?? '8765';

  Future<void> save({required String host, required String port}) async {
    await _prefs.setString(_hostKey, host.trim());
    await _prefs.setString(_portKey, port.trim().isEmpty ? '8765' : port.trim());
  }

  Future<void> clear() async {
    await _prefs.remove(_hostKey);
    await _prefs.remove(_portKey);
  }
}
