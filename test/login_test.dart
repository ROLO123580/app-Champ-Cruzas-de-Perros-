import 'dart:async';

import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/core/servicios/configuracion_firebase.dart';
import 'package:champ/microapps/acceso/app_acceso.dart';
import 'package:champ/nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'package:champ/nanoapps/login/widgets/boton_ingresar_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/autenticacion_falsa.dart';

void main() {
  test('restaura una sesión y suscribe una única vez', () async {
    const usuario = UsuarioChamp(uid: 'restaurado', nombre: 'Ana');
    final servicio = AutenticacionFalsa(usuarioActual: usuario);
    final controlador = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(controlador.dispose);
    await Future.wait([controlador.inicializar(), controlador.inicializar()]);
    expect(servicio.inicializaciones, 1);
    expect(servicio.eventos.hasListener, isTrue);
    expect(controlador.listo, isTrue);
    expect(controlador.ocupado, isFalse);
    expect(controlador.usuario, same(usuario));
    servicio.eventos.add(null);
    expect(controlador.usuario, isNull);
  });

  test(
    'evita accesos y cierres duplicados mientras están pendientes',
    () async {
      final servicio = AutenticacionFalsa()
        ..esperaAcceso = Completer<UsuarioChamp?>()
        ..esperaSalida = Completer<void>();
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      final acceso = controlador.entrarGoogle();
      await controlador.entrarGoogle();
      await controlador.cerrarSesion();
      expect(servicio.accesos, 1);
      expect(servicio.salidas, 0);
      expect(controlador.ocupado, isTrue);
      servicio.esperaAcceso!.complete(const UsuarioChamp(uid: 'uno'));
      await acceso;
      expect(controlador.usuario?.uid, 'uno');
      final salida = controlador.cerrarSesion();
      await controlador.cerrarSesion();
      await controlador.entrarGoogle();
      expect(servicio.salidas, 1);
      expect(servicio.accesos, 1);
      servicio.esperaSalida!.complete();
      await salida;
      expect(controlador.usuario, isNull);
      expect(controlador.ocupado, isFalse);
    },
  );

  test(
    'cancelación y error conservan estado y permiten un nuevo acceso',
    () async {
      final servicio = AutenticacionFalsa()
        ..falloAcceso = const AccesoCancelado();
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      await controlador.entrarGoogle();
      expect(controlador.cancelado, isTrue);
      expect(controlador.error, isNull);
      expect(controlador.usuario, isNull);
      servicio.falloAcceso = const FalloAutenticacion('Sin conexión.');
      await controlador.entrarGoogle();
      expect(controlador.cancelado, isFalse);
      expect(controlador.error, 'Sin conexión.');
      servicio.falloAcceso = null;
      await controlador.entrarGoogle();
      expect(controlador.error, isNull);
      expect(controlador.usuario?.nombre, 'Ana');
      servicio.falloSalida = const FalloAutenticacion('Error al cerrar.');
      await controlador.cerrarSesion();
      expect(controlador.usuario, isNotNull);
      expect(controlador.error, 'Error al cerrar.');
      servicio.falloSalida = null;
      await controlador.cerrarSesion();
      expect(controlador.usuario, isNull);
    },
  );

  test(
    'libera la suscripción y suprime operaciones tardías tras dispose',
    () async {
      final servicio = AutenticacionFalsa()
        ..esperaAcceso = Completer<UsuarioChamp?>();
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      await controlador.inicializar();
      var notificaciones = 0;
      controlador.addListener(() => notificaciones++);
      final acceso = controlador.entrarGoogle();
      final antes = notificaciones;
      controlador.dispose();
      expect(servicio.eventos.hasListener, isFalse);
      servicio.esperaAcceso!.complete(const UsuarioChamp(uid: 'tardio'));
      await acceso;
      servicio.eventos.add(null);
      expect(notificaciones, antes);
      expect(controlador.usuario, isNull);
    },
  );

  test('dispose durante restauración nunca crea una suscripción', () async {
    final servicio = AutenticacionFalsa()
      ..esperaInicializacion = Completer<void>();
    final controlador = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    final inicio = controlador.inicializar();
    controlador.dispose();
    servicio.esperaInicializacion!.complete();
    await inicio;
    expect(servicio.eventos.hasListener, isFalse);
  });

  test(
    'configuración incompleta bloquea el acceso sin inventar una sesión',
    () async {
      final servicio = AutenticacionFalsa(
        configuracionPendiente: 'Falta registrar Firebase de Champ.',
      );
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      await controlador.entrarGoogle();
      await controlador.entrarCorreo(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      await controlador.crearCuenta(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      expect(servicio.accesos, 0);
      expect(servicio.accesosCorreo, 0);
      expect(servicio.creacionesCuenta, 0);
      expect(controlador.disponible, isFalse);
      expect(controlador.usuario, isNull);
    },
  );

  test(
    'fallo de restauración se comunica sin suscripciones abiertas',
    () async {
      final servicio = AutenticacionFalsa()
        ..falloInicializacion = const FalloAutenticacion('Error al restaurar.');
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      expect(controlador.listo, isTrue);
      expect(controlador.ocupado, isFalse);
      expect(controlador.error, 'Error al restaurar.');
      expect(servicio.eventos.hasListener, isFalse);
      servicio.falloInicializacion = null;
      await controlador.reintentarInicializacion();
      expect(servicio.inicializaciones, 2);
      expect(servicio.eventos.hasListener, isTrue);
      expect(controlador.error, isNull);
    },
  );

  test('Google web exige opciones propias y dominio de autenticación', () {
    const vacia = ConfiguracionFirebaseChamp();
    expect(
      vacia.pendiente(web: true, plataforma: TargetPlatform.android),
      contains('FIREBASE_APP_ID'),
    );
    const completa = ConfiguracionFirebaseChamp(
      apiKey: 'prueba-no-real',
      appId: '1:123:web:prueba',
      messagingSenderId: '123',
      projectId: 'prueba',
      authDomain: 'prueba.firebaseapp.com',
    );
    expect(
      completa.pendiente(web: true, plataforma: TargetPlatform.android),
      isNull,
    );
    expect(completa.opciones?.projectId, 'prueba');
    expect(
      vacia.pendiente(web: false, plataforma: TargetPlatform.android),
      isNull,
    );
    expect(
      vacia.pendiente(web: false, plataforma: TargetPlatform.linux),
      contains('Chrome y Android'),
    );
  });

  test('correo valida antes del SDK y conserva la contraseña exacta', () async {
    final servicio = AutenticacionFalsa();
    final controlador = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(controlador.dispose);
    await controlador.inicializar();
    await controlador.entrarCorreo(correo: 'sin-correo', clave: 'privada');
    expect(controlador.error, 'Escribe un correo electrónico válido.');
    controlador.limpiarAvisos();
    expect(controlador.error, isNull);
    expect(controlador.cancelado, isFalse);
    await controlador.entrarCorreo(correo: 'ana@example.test', clave: '');
    expect(controlador.error, 'Escribe tu contraseña.');
    await controlador.crearCuenta(correo: 'ana@example.test', clave: '12345');
    expect(controlador.error, 'Usa una contraseña de al menos 6 caracteres.');
    expect(servicio.accesosCorreo, 0);
    expect(servicio.creacionesCuenta, 0);
    // Iniciar sesión permite la contraseña de una cuenta existente sin imponer
    // las condiciones de alta. Los espacios pueden ser parte de su clave.
    await controlador.entrarCorreo(
      correo: '  ana@example.test  ',
      clave: ' a ',
    );
    expect(servicio.correoRecibido, 'ana@example.test');
    expect(servicio.claveRecibida, ' a ');
    expect(controlador.usuario?.correo, 'ana@example.test');
    expect(controlador.error, isNull);
  });

  test(
    'crear cuenta establece sesión, se restaura y permite cerrarla',
    () async {
      final servicio = AutenticacionFalsa();
      var controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      await controlador.inicializar();
      await controlador.crearCuenta(
        correo: '  nueva@example.test ',
        clave: 'nueva clave',
      );
      expect(servicio.creacionesCuenta, 1);
      expect(servicio.correoRecibido, 'nueva@example.test');
      expect(controlador.usuario?.uid, 'cuenta-nueva-prueba');
      controlador.dispose();
      expect(servicio.eventos.hasListener, isFalse);
      controlador = GestionarSesion(servicio: servicio);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      expect(controlador.usuario?.correo, 'nueva@example.test');
      await controlador.cerrarSesion();
      expect(controlador.usuario, isNull);
      expect(servicio.salidas, 1);
    },
  );

  test(
    'correo y alta comparten el bloqueo con Google y cerrar sesión',
    () async {
      final servicio = AutenticacionFalsa()
        ..esperaCorreo = Completer<UsuarioChamp?>()
        ..esperaCreacion = Completer<UsuarioChamp?>();
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      final acceso = controlador.entrarCorreo(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      await controlador.entrarCorreo(
        correo: 'otra@example.test',
        clave: 'privada',
      );
      await controlador.crearCuenta(
        correo: 'otra@example.test',
        clave: 'privada',
      );
      await controlador.entrarGoogle();
      await controlador.cerrarSesion();
      expect(servicio.accesosCorreo, 1);
      expect(servicio.creacionesCuenta, 0);
      expect(servicio.accesos, 0);
      expect(servicio.salidas, 0);
      servicio.esperaCorreo!.complete(const UsuarioChamp(uid: 'correo'));
      await acceso;
      await controlador.cerrarSesion();
      final alta = controlador.crearCuenta(
        correo: 'nueva@example.test',
        clave: 'privada',
      );
      await controlador.crearCuenta(
        correo: 'otra@example.test',
        clave: 'privada',
      );
      await controlador.entrarCorreo(
        correo: 'otra@example.test',
        clave: 'privada',
      );
      await controlador.entrarGoogle();
      expect(servicio.creacionesCuenta, 1);
      expect(servicio.accesosCorreo, 1);
      expect(servicio.accesos, 0);
      servicio.esperaCreacion!.complete(const UsuarioChamp(uid: 'alta'));
      await alta;
      expect(controlador.usuario?.uid, 'alta');
      expect(controlador.ocupado, isFalse);
    },
  );

  test(
    'errores de correo y alta permiten reintentar sin acreditar sesión',
    () async {
      final servicio = AutenticacionFalsa()
        ..falloCorreo = const FalloAutenticacion('Credenciales no válidas.')
        ..falloCreacion = const FalloAutenticacion('Correo ya registrado.');
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      await controlador.entrarCorreo(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      expect(controlador.error, 'Credenciales no válidas.');
      expect(controlador.usuario, isNull);
      expect(controlador.ocupado, isFalse);
      await controlador.crearCuenta(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      expect(controlador.error, 'Correo ya registrado.');
      expect(controlador.usuario, isNull);
      servicio.falloCreacion = null;
      servicio.esperaCreacion = Completer<UsuarioChamp?>()..complete(null);
      await controlador.crearCuenta(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      expect(controlador.error, contains('no devolvió una sesión válida'));
      expect(controlador.cancelado, isFalse);
      servicio.esperaCreacion = null;
      await controlador.crearCuenta(
        correo: 'ana@example.test',
        clave: 'privada',
      );
      expect(controlador.error, isNull);
      expect(controlador.usuario, isNotNull);
    },
  );

  test('correo y alta ignoran resultados tardíos después de dispose', () async {
    for (final crear in [false, true]) {
      final pendiente = Completer<UsuarioChamp?>();
      final servicio = AutenticacionFalsa()
        ..esperaCorreo = pendiente
        ..esperaCreacion = pendiente;
      final controlador = GestionarSesion(servicio: servicio);
      await controlador.inicializar();
      var avisos = 0;
      controlador.addListener(() => avisos++);
      final tarea = crear
          ? controlador.crearCuenta(
              correo: 'ana@example.test',
              clave: 'privada',
            )
          : controlador.entrarCorreo(
              correo: 'ana@example.test',
              clave: 'privada',
            );
      final antes = avisos;
      controlador.dispose();
      pendiente.complete(const UsuarioChamp(uid: 'tardio'));
      await tarea;
      expect(avisos, antes);
      expect(controlador.usuario, isNull);
      expect(servicio.eventos.hasListener, isFalse);
      await servicio.dispose();
    }
  });

  testWidgets('Login muestra cancelación y permite reintentar', (tester) async {
    final servicio = AutenticacionFalsa()
      ..falloAcceso = const AccesoCancelado();
    final controlador = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(controlador.dispose);
    await controlador.inicializar();
    await tester.pumpWidget(
      MaterialApp(home: AppAcceso(controlador: controlador)),
    );
    await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
    await tester.tap(find.text('CONTINUAR CON GOOGLE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acceso cancelado.'), findsOneWidget);
    servicio.falloAcceso = const FalloAutenticacion('Proveedor no habilitado.');
    await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
    await tester.tap(find.text('CONTINUAR CON GOOGLE'));
    await tester.pumpAndSettle();
    expect(find.text('Proveedor no habilitado.'), findsOneWidget);
    expect(find.textContaining('Acceso cancelado.'), findsNothing);
  });

  testWidgets('el botón Google muestra carga y evita pulsaciones repetidas', (
    tester,
  ) async {
    final servicio = AutenticacionFalsa()
      ..esperaAcceso = Completer<UsuarioChamp?>();
    final controlador = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(controlador.dispose);
    await controlador.inicializar();
    await tester.pumpWidget(
      MaterialApp(home: AppAcceso(controlador: controlador)),
    );
    await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
    await tester.tap(find.text('CONTINUAR CON GOOGLE'));
    await tester.pump();
    expect(find.text('Conectando con Google…'), findsOneWidget);
    expect(
      tester
          .widget<BotonIngresarGoogle>(find.byType(BotonIngresarGoogle))
          .onPressed,
      isNull,
    );
    expect(servicio.accesos, 1);
    servicio.esperaAcceso!.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('CONTINUAR CON GOOGLE'), findsOneWidget);
    expect(find.textContaining('Acceso cancelado.'), findsOneWidget);
  });

  testWidgets(
    'sin Firebase el botón informa el ajuste sin simular un ingreso',
    (tester) async {
      final servicio = AutenticacionFalsa(
        configuracionPendiente: 'Configuración de prueba pendiente.',
      );
      final controlador = GestionarSesion(servicio: servicio);
      addTearDown(servicio.dispose);
      addTearDown(controlador.dispose);
      await controlador.inicializar();
      await tester.pumpWidget(
        MaterialApp(home: AppAcceso(controlador: controlador)),
      );
      expect(find.byType(BotonIngresarGoogle), findsOneWidget);
      await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
      await tester.tap(find.text('CONTINUAR CON GOOGLE'));
      await tester.pumpAndSettle();
      expect(find.text('Configurar acceso con Google'), findsOneWidget);
      expect(find.text('Configuración de prueba pendiente.'), findsOneWidget);
      expect(servicio.accesos, 0);
      expect(controlador.usuario, isNull);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('CONTINUAR CON GOOGLE'), findsOneWidget);
    },
  );
}
