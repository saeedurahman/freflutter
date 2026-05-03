import 'package:get_storage/get_storage.dart';

class StorageService {
  StorageService([GetStorage? storage]) : _box = storage ?? GetStorage();

  final GetStorage _box;

  static const String _tokenKey = 'auth_token';
  static const String _clientCodeKey = 'client_code';
  static const String _roleKey = 'user_role';

  Future<void> saveToken(String token) => _box.write(_tokenKey, token);

  String? getToken() {
    final value = _box.read<String?>(_tokenKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> saveClientCode(String code) =>
      _box.write(_clientCodeKey, code);

  String? getClientCode() {
    final value = _box.read<String?>(_clientCodeKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> saveRole(String role) => _box.write(_roleKey, role);

  String? getRole() {
    final value = _box.read<String?>(_roleKey);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> clearAll() async {
    await _box.erase();
  }

  bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
