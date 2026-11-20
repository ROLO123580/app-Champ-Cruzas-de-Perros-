// Inspección local: no inicializa Firebase, no abre SQLite y no llama a la red.
import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  var platform = 'all';
  String? definesPath;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--help') {
      stdout.writeln(
        'dart run tool/verificar_firebase.dart '
        '[--platform web|android|all] [--defines archivo.json]',
      );
      return;
    }
    if ((argument == '--platform' || argument == '--defines') &&
        index + 1 < arguments.length) {
      final value = arguments[++index];
      if (argument == '--platform') {
        platform = value;
      } else {
        definesPath = value;
      }
    } else {
      stderr.writeln('Argumento desconocido o sin valor: $argument');
      exitCode = 64;
      return;
    }
  }
  if (!{'web', 'android', 'all'}.contains(platform)) {
    stderr.writeln('--platform debe ser web, android o all.');
    exitCode = 64;
    return;
  }
  final checker = _Checker();
  final defines = definesPath == null
      ? <String, dynamic>{}
      : checker.readJson(definesPath);
  final gradle = File('android/app/build.gradle.kts');
  if (!gradle.existsSync()) {
    checker.missing('Ejecuta desde la raíz del proyecto Champ.');
    exitCode = 1;
    return;
  }
  final package = RegExp(r'applicationId\s*=\s*"([^"]+)"')
      .firstMatch(gradle.readAsStringSync())
      ?.group(1);
  if (package == null) {
    checker.missing('No se pudo leer applicationId de Android.');
  } else {
    stdout.writeln('Android applicationId: $package');
  }
  if (platform != 'android') checker.checkWeb(defines);
  if (platform != 'web') checker.checkAndroid(defines, package);
  stdout.writeln(
    '\nPendiente de comprobación externa: proveedor Google habilitado, '
    'dominios autorizados, registro OAuth/SHA, ingreso y restauración reales.',
  );
  stdout.writeln(
    'Este comando comprueba archivos; no acredita conexión ni login real.',
  );
  exitCode = checker.failures == 0 ? 0 : 1;
}

class _Checker {
  int failures = 0;
  static const _required = [
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
  ];

  void missing(String message) {
    failures++;
    stdout.writeln('FALTA: $message');
  }

  Map<String, dynamic> readJson(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      missing('Archivo JSON no encontrado: $path');
      return {};
    }
    try {
      final value = jsonDecode(file.readAsStringSync());
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      missing('JSON inválido: $path');
      return {};
    } on FileSystemException {
      missing('No se pudo leer: $path');
      return {};
    }
    missing('Se esperaba un objeto JSON en: $path');
    return {};
  }

  String value(Map<String, dynamic> map, String key) =>
      map[key] is String ? (map[key] as String).trim() : '';

  void checkWeb(Map<String, dynamic> defines) {
    stdout.writeln('\nChrome:');
    for (final key in [..._required, 'FIREBASE_AUTH_DOMAIN']) {
      if (value(defines, key).isEmpty) missing('Define $key para Chrome.');
    }
    final appId = value(defines, 'FIREBASE_APP_ID');
    if (appId.isNotEmpty && !appId.contains(':web:')) {
      missing('FIREBASE_APP_ID debe corresponder al registro web de Champ.');
    }
    final authDomain = value(defines, 'FIREBASE_AUTH_DOMAIN');
    if (authDomain.isNotEmpty &&
        (authDomain.contains('://') || authDomain.contains('/'))) {
      missing('FIREBASE_AUTH_DOMAIN requiere hostname sin esquema ni ruta.');
    }
  }

  void checkAndroid(Map<String, dynamic> defines, String? package) {
    stdout.writeln('\nAndroid:');
    final path = 'android/app/google-services.json';
    final config = readJson(path);
    final project = _object(config['project_info']);
    if (value(project, 'project_id').isEmpty) {
      missing('project_info.project_id en google-services.json.');
    }
    final provided = _required
        .where((key) => value(defines, key).isNotEmpty)
        .length;
    if (provided > 0 && provided < _required.length) {
      missing('Definiciones Firebase Android incompletas.');
    }
    final expectedProject = value(defines, 'FIREBASE_PROJECT_ID');
    if (expectedProject.isNotEmpty &&
        expectedProject != value(project, 'project_id')) {
      missing('El proyecto de defines y google-services.json no coincide.');
    }
    final clients = _objects(config['client']);
    final matching = clients.where((client) {
      final info = _object(client['client_info']);
      final android = _object(info['android_client_info']);
      return package != null && value(android, 'package_name') == package;
    }).toList();
    if (matching.isEmpty) {
      missing('Cliente Android para el applicationId de Champ en $path.');
      return;
    }
    final client = matching.first;
    final appId = value(_object(client['client_info']), 'mobilesdk_app_id');
    if (!appId.contains(':android:')) {
      missing('mobilesdk_app_id no corresponde a Android.');
    }
    final expectedId = value(defines, 'FIREBASE_APP_ID');
    if (expectedId.isNotEmpty && appId != expectedId) {
      missing('FIREBASE_APP_ID no coincide con el cliente Android del JSON.');
    }
    final expectedSender = value(defines, 'FIREBASE_MESSAGING_SENDER_ID');
    if (expectedSender.isNotEmpty &&
        expectedSender != project['project_number']?.toString()) {
      missing('FIREBASE_MESSAGING_SENDER_ID no coincide con project_number.');
    }
    if (!_objects(client['api_key'])
        .any((entry) => value(entry, 'current_key').isNotEmpty)) {
      missing('api_key.current_key en el cliente Android.');
    }
    final oauth = _objects(client['oauth_client']);
    final webClients = oauth.where((entry) => entry['client_type'] == 3);
    final serverId = value(defines, 'GOOGLE_SERVER_CLIENT_ID');
    if (!webClients.any((entry) => value(entry, 'client_id').isNotEmpty) &&
        serverId.isEmpty) {
      missing(
        'Cliente OAuth web (client_type 3) o GOOGLE_SERVER_CLIENT_ID '
        'para Google Sign-In Android.',
      );
    }
    if (serverId.isNotEmpty &&
        !serverId.endsWith('.apps.googleusercontent.com')) {
      missing('GOOGLE_SERVER_CLIENT_ID no tiene formato de cliente OAuth.');
    }
    final androidClients = oauth.where((entry) => entry['client_type'] == 1);
    if (!androidClients.any((entry) {
      final info = _object(entry['android_info']);
      return value(info, 'package_name') == package &&
          value(info, 'certificate_hash').isNotEmpty;
    })) {
      missing('Registro OAuth Android con paquete y huella SHA en el JSON.');
    }
    stdout.writeln(
      'La coincidencia local no verifica la huella de la firma usada al instalar.',
    );
  }

  Map<String, dynamic> _object(dynamic object) =>
      object is Map<String, dynamic> ? object : {};

  List<Map<String, dynamic>> _objects(dynamic objects) =>
      objects is List ? objects.whereType<Map<String, dynamic>>().toList() : [];
}
