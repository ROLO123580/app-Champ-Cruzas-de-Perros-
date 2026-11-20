import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../modelos/sesion.dart';
import 'autenticacion.dart';
import 'configuracion_firebase.dart';

/// Adapta los flujos de `lib/login/auth_service.dart` del Fénix funcional
/// ubicado en `/home/rolo/flutter_projects/fenix_fitness` (solo lectura):
/// correo/contraseña, alta, popup web y credencial Google nativa. Champ añade
/// configuración propia, inicialización compartida y errores en español.
class AutenticacionFirebase implements ServicioAutenticacion {
  AutenticacionFirebase({
    this.configuracion = const ConfiguracionFirebaseChamp(),
  });

  final ConfiguracionFirebaseChamp configuracion;
  FirebaseAuth? _auth;
  Future<void>? _inicializacion;
  String? _pendiente;
  static Future<FirebaseApp>? _inicioFirebase;
  static Future<void>? _inicioGoogle;

  @override
  String? get configuracionPendiente =>
      _pendiente ??
      configuracion.pendiente(web: kIsWeb, plataforma: defaultTargetPlatform);

  @override
  bool get disponible => _auth != null && configuracionPendiente == null;

  @override
  UsuarioChamp? get usuarioActual => _publico(_auth?.currentUser);

  @override
  Stream<UsuarioChamp?> get cambios =>
      _auth?.authStateChanges().map(_publico) ?? Stream.value(null);

  static UsuarioChamp? _publico(User? usuario) => usuario == null
      ? null
      : UsuarioChamp(
          uid: usuario.uid,
          nombre: usuario.displayName,
          correo: usuario.email,
          fotoUrl: usuario.photoURL,
        );

  @override
  Future<void> inicializar() {
    final vigente = _inicializacion;
    if (vigente != null) return vigente;
    late final Future<void> nueva;
    nueva = _preparar().catchError((Object error, StackTrace traza) {
      // Una inicialización fallida puede reintentarse; una exitosa se reutiliza.
      if (identical(_inicializacion, nueva)) _inicializacion = null;
      Error.throwWithStackTrace(error, traza);
    });
    return _inicializacion = nueva;
  }

  Future<void> _preparar() async {
    _pendiente = configuracion.pendiente(
      web: kIsWeb,
      plataforma: defaultTargetPlatform,
    );
    if (_pendiente != null) return;
    try {
      final app = await _obtenerFirebase();
      _validarAplicacion(app);
      _auth = FirebaseAuth.instanceFor(app: app);
      // El primer evento llega una vez restauradas las credenciales del SDK.
      await _auth!.authStateChanges().first;
    } on FirebaseException catch (e) {
      if (e.code == 'network-request-failed' || e.code == 'too-many-requests') {
        _auth = null;
        throw FalloAutenticacion(_mensajeFirebase(e.code));
      }
      _pendiente = !kIsWeb && configuracion.opciones == null
          ? 'Falta el registro Firebase Android de Champ: instala '
                'android/app/google-services.json para com.example.champ y '
                'vuelve a compilar. Consulta docs/login.md.'
          : _mensajeFirebase(e.code);
      _auth = null;
    } on FalloAutenticacion catch (e) {
      _pendiente = e.mensaje;
      _auth = null;
    } catch (_) {
      _pendiente =
          'No se pudo inicializar Firebase de Champ. Revisa su '
          'registro y configuración de esta plataforma en docs/login.md.';
      _auth = null;
    }
  }

  Future<FirebaseApp> _obtenerFirebase() async {
    final inicializacion = _inicioFirebase ??= _crearFirebase();
    try {
      return await inicializacion;
    } catch (_) {
      if (identical(_inicioFirebase, inicializacion)) _inicioFirebase = null;
      rethrow;
    }
  }

  void _validarAplicacion(FirebaseApp app) {
    final opciones = configuracion.opciones;
    if (opciones != null &&
        (app.options.projectId != opciones.projectId ||
            app.options.appId != opciones.appId)) {
      throw const FalloAutenticacion(
        'Firebase ya está inicializado con un registro diferente de Champ.',
      );
    }
  }

  Future<FirebaseApp> _crearFirebase() async {
    final opciones = configuracion.opciones;
    if (Firebase.apps.isNotEmpty) {
      final existente = Firebase.app();
      _validarAplicacion(existente);
      return existente;
    }
    return Firebase.initializeApp(options: opciones);
  }

  @override
  Future<UsuarioChamp?> entrarGoogle() async {
    if (!disponible) {
      throw FalloAutenticacion(
        configuracionPendiente ?? 'Firebase de Champ aún no está disponible.',
      );
    }
    try {
      final UserCredential resultado;
      if (kIsWeb) {
        // Se llama desde el botón; no hay awaits previos que bloqueen el popup.
        resultado = await _auth!.signInWithPopup(GoogleAuthProvider());
      } else {
        await (_inicioGoogle ??= GoogleSignIn.instance.initialize(
          serverClientId: configuracion.googleServerClientId.isEmpty
              ? null
              : configuracion.googleServerClientId,
        ));
        final cuenta = await GoogleSignIn.instance.authenticate();
        final token = cuenta.authentication.idToken;
        if (token == null) {
          throw const FalloAutenticacion(
            'Google no devolvió una credencial válida. Revisa el cliente OAuth '
            'web de Champ y las huellas de firma de Android.',
          );
        }
        resultado = await _auth!.signInWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        );
      }
      return _publico(resultado.user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AccesoCancelado();
      }
      throw FalloAutenticacion(
        e.code == GoogleSignInExceptionCode.clientConfigurationError ||
                e.code == GoogleSignInExceptionCode.providerConfigurationError
            ? 'Revisa el cliente OAuth de Champ, google-services.json y las '
                  'huellas SHA de la firma de Android.'
            : 'Google no pudo completar el acceso. Intenta nuevamente.',
      );
    } on FirebaseAuthException catch (e) {
      if ({
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-canceled',
      }.contains(e.code)) {
        throw const AccesoCancelado();
      }
      throw FalloAutenticacion(_mensajeFirebase(e.code));
    }
  }

  @override
  Future<UsuarioChamp?> entrarCorreo({
    required String correo,
    required String clave,
  }) => _autenticarCorreo(correo: correo, clave: clave, crear: false);

  @override
  Future<UsuarioChamp?> crearCuenta({
    required String correo,
    required String clave,
  }) => _autenticarCorreo(correo: correo, clave: clave, crear: true);

  Future<UsuarioChamp?> _autenticarCorreo({
    required String correo,
    required String clave,
    required bool crear,
  }) async {
    if (!disponible) {
      throw FalloAutenticacion(
        configuracionPendiente ?? 'Firebase de Champ aún no está disponible.',
      );
    }
    try {
      // Contraseñas y credenciales se entregan directamente al SDK. No se
      // almacenan en los repositorios de contenido, preferencias ni registros.
      final resultado = crear
          ? await _auth!.createUserWithEmailAndPassword(
              email: correo.trim(),
              password: clave,
            )
          : await _auth!.signInWithEmailAndPassword(
              email: correo.trim(),
              password: clave,
            );
      return _publico(resultado.user);
    } on FirebaseAuthException catch (e) {
      throw FalloAutenticacion(_mensajeCorreo(e.code));
    }
  }

  static String _mensajeCorreo(String codigo) => switch (codigo) {
    'invalid-email' => 'Escribe un correo electrónico válido.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'La contraseña no cumple los requisitos de seguridad de Champ. '
          'Usa al menos 6 caracteres y revisa la política de contraseñas '
          'configurada en Firebase.',
    'email-already-in-use' =>
      'Este correo ya tiene una cuenta. Inicia sesión '
          'con su método de acceso habitual.',
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'wrong-password' ||
    'user-not-found' =>
      'No se pudo iniciar sesión con ese correo y contraseña.',
    'user-disabled' =>
      'Esta cuenta está deshabilitada. Consulta con quien '
          'administra las cuentas de Champ.',
    'operation-not-allowed' =>
      'Habilita el proveedor Correo electrónico y '
          'contraseña en Firebase Authentication de Champ.',
    'too-many-requests' =>
      'Se hicieron demasiados intentos de acceso. '
          'Espera un momento antes de volver a intentarlo.',
    'network-request-failed' =>
      'No se pudo conectar con el servicio de acceso. '
          'Revisa tu conexión y vuelve a intentarlo.',
    _ => _mensajeFirebase(codigo),
  };

  @override
  Future<void> cerrarSesion() async {
    if (_auth == null) return;
    try {
      await _auth!.signOut();
      if (!kIsWeb && _inicioGoogle != null) {
        await GoogleSignIn.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw FalloAutenticacion(_mensajeFirebase(e.code));
    } on GoogleSignInException {
      // Firebase ya cerró su sesión; no se conserva una sesión autenticada.
    }
  }

  static String _mensajeFirebase(String codigo) => switch (codigo) {
    'unauthorized-domain' =>
      'Este dominio no está autorizado en Firebase de '
          'Champ. Agrega localhost o el dominio real en Authentication → Settings '
          '→ Authorized domains.',
    'operation-not-allowed' =>
      'Habilita el proveedor Google en Firebase '
          'Authentication de Champ.',
    'popup-blocked' =>
      'Chrome bloqueó la ventana de Google. Permite ventanas '
          'emergentes para esta aplicación y vuelve a intentarlo.',
    'network-request-failed' =>
      'No se pudo conectar con Google. Revisa la '
          'conexión y vuelve a intentarlo.',
    'account-exists-with-different-credential' =>
      'Esta cuenta ya utiliza otro '
          'método de acceso. Revisa sus proveedores en Firebase de Champ.',
    'invalid-api-key' || 'app-not-authorized' || 'invalid-credential' =>
      'La configuración de Firebase o de Google no corresponde a Champ. '
          'Revisa docs/login.md.',
    _ => 'No se pudo completar la autenticación ($codigo). Intenta nuevamente.',
  };
}
