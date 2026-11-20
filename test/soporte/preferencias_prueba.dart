import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasPrueba implements SharedPreferencesAsync {
  final datos = <String, String>{};
  final _fallar = [false];
  bool get fallar => _fallar.single;
  set fallar(bool valor) => _fallar[0] = valor;
  @override
  Future<String?> getString(String key) async => datos[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fallar) throw StateError('Sin espacio');
    datos[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
