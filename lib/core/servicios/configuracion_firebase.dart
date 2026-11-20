import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración exclusiva de Champ; no contiene valores de Fénix Fitness.
class ConfiguracionFirebaseChamp {
  const ConfiguracionFirebaseChamp({
    this.apiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
    this.appId = const String.fromEnvironment('FIREBASE_APP_ID'),
    this.messagingSenderId = const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    this.projectId = const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    this.authDomain = const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    this.storageBucket = const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    this.googleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String authDomain;
  final String storageBucket;
  final String googleServerClientId;

  bool get tieneOpciones => [
    apiKey,
    appId,
    messagingSenderId,
    projectId,
  ].every((v) => v.trim().isNotEmpty);

  FirebaseOptions? get opciones => tieneOpciones
      ? FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: authDomain.isEmpty ? null : authDomain,
          storageBucket: storageBucket.isEmpty ? null : storageBucket,
        )
      : null;

  String? pendiente({required bool web, required TargetPlatform plataforma}) {
    if (!web && plataforma != TargetPlatform.android) {
      return 'El acceso con Google está preparado para Chrome y Android. '
          'Esta plataforma necesita su propio registro y configuración.';
    }
    final variables = <String, String>{
      'FIREBASE_API_KEY': apiKey,
      'FIREBASE_APP_ID': appId,
      'FIREBASE_MESSAGING_SENDER_ID': messagingSenderId,
      'FIREBASE_PROJECT_ID': projectId,
      if (web) 'FIREBASE_AUTH_DOMAIN': authDomain,
    };
    // Android también puede obtener las opciones del google-services.json
    // procesado por Gradle. Nunca se utiliza un registro de otra aplicación.
    if (!web && variables.values.every((v) => v.isEmpty)) return null;
    final faltantes = variables.entries
        .where((v) => v.value.trim().isEmpty)
        .map((v) => v.key)
        .toList();
    if (faltantes.isEmpty) return null;
    return 'Falta configurar Firebase de Champ: ${faltantes.join(', ')}. '
        'Consulta docs/login.md y reinicia la app con esos valores.';
  }
}
