import 'core/repositorios/preferencias.dart';
import 'nanoapps/configuracion/configuracion_cuenta.dart';
import 'nanoapps/configuracion/nanofunciones/gestionar_preferencias/gestionar_preferencias.dart';
import 'core/repositorios/membership_piloto.dart';
import 'core/repositorios/cruces_privados_firestore.dart';
import 'core/repositorios/chat_demo_sesion.dart';

import 'dart:async';

import 'core/repositorios/servicios_paseos_firestore.dart';
import 'nanoapps/paseadores/nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';
import 'nanoapps/reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';

import 'core/repositorios/avisos_perros_firestore.dart';
import 'microapps/rescate_canino/app_rescate_canino.dart';
import 'nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/gestionar_avisos.dart';

import 'core/repositorios/comunidad_firestore.dart';
import 'microapps/comunidad_social/app_comunidad_social.dart';
import 'nanoapps/comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';

import 'package:flutter/material.dart';

import 'navegacion/catalogo_pantallas.dart';
import 'sidebar/app_sidebar.dart';
import 'core/servicios/servicios_champ.dart';
import 'core/repositorios/chat_firestore.dart';
import 'core/servicios/autenticacion_firebase.dart';
import 'microapps/acceso/app_acceso.dart';
import 'microapps/comercio/app_comercio.dart';
import 'microapps/comunidad_canina/app_comunidad_canina.dart';
import 'microapps/datos_locales/app_datos_locales.dart';
import 'nanoapps/chat/nanofunciones/gestionar_chat/gestionar_chat.dart';
import 'nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'nanoapps/membership/nanofunciones/gestionar_membership/gestionar_membership.dart';

class ChampApp extends StatefulWidget {
  const ChampApp({
    super.key,
    this.servicios,
    this.controladorSesion,
    this.preferencias,
  });
  final GestionarPreferencias? preferencias;
  final ServiciosChamp? servicios;
  final GestionarSesion? controladorSesion;

  @override
  State<ChampApp> createState() => _ChampAppState();
}

class _ChampAppState extends State<ChampApp> {
  final _navegador = GlobalKey<NavigatorState>();
  late final GestionarSesion sesion =
      widget.controladorSesion ??
      GestionarSesion(servicio: AutenticacionFirebase());
  late final preferencias =
      widget.preferencias ?? GestionarPreferencias(PreferenciasDispositivo());
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = sesion.usuario?.uid;
    sesion.addListener(_cambioSesion);
    unawaited(sesion.inicializar());
    if (!preferencias.cargado) unawaited(preferencias.cargar());
  }

  void _cambioSesion() {
    final uid = sesion.usuario?.uid;
    if (_uid == uid) return;
    _uid = uid;
    // La entrada cambia por estado; ninguna pantalla de Login se apila.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navegador.currentState?.popUntil((ruta) => ruta.isFirst);
    });
  }

  @override
  void dispose() {
    if (widget.preferencias == null) preferencias.dispose();
    sesion.removeListener(_cambioSesion);
    if (widget.controladorSesion == null) sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PreferenciasChamp(
    controlador: preferencias,
    child: ListenableBuilder(
      listenable: preferencias,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navegador,
        title: 'Champ',
        debugShowCheckedModeBanner: false,
        themeMode: preferencias.modo,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF25856A)),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25856A),
            brightness: Brightness.dark,
          ),
        ),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: preferencias.escala == 1
                  ? media.textScaler
                  : TextScaler.linear(
                      media.textScaler.scale(14) / 14 * preferencias.escala,
                    ),
            ),
            child: child!,
          );
        },
        home: ChampEntrada(servicios: widget.servicios, controlador: sesion),
      ),
    ),
  );
}

class ChampShell extends StatefulWidget {
  const ChampShell({
    super.key,
    this.controladorChat,
    this.controladorCruces,
    this.controladorMembership,
    this.controladorSesion,
    this.servicios,
    this.controladorComunidad,
    this.controladorAvisos,
    this.controladorPaseadores,
    this.controladorReservas,
  });
  final ServiciosChamp? servicios;
  final GestionarComunidad? controladorComunidad;
  final GestionarAvisos? controladorAvisos;
  final GestionarPaseadores? controladorPaseadores;
  final GestionarReservas? controladorReservas;
  final GestionarChat? controladorChat;
  final GestionarCruces? controladorCruces;
  final GestionarMembership? controladorMembership;
  final GestionarSesion? controladorSesion;

  @override
  State<ChampShell> createState() => _ChampShellState();
}

class _ChampShellState extends State<ChampShell> {
  late final servicios = widget.servicios ?? ServiciosChamp.predeterminados;
  int seleccion = titulos.indexOf('Inicio');
  String? conversacionInicial;
  GestionarChat? _chat;
  GestionarCruces? _cruces;
  GestionarMembership? _membership;
  GestionarComunidad? _comunidad;
  GestionarAvisos? _avisos;
  GestionarPaseadores? _paseadores;
  GestionarReservas? _reservas;
  GestionarPaseadores? get paseadores {
    if (widget.controladorPaseadores != null) {
      return widget.controladorPaseadores;
    }
    final usuario = widget.controladorSesion?.usuario;
    if (usuario == null) return null;
    return _paseadores ??= GestionarPaseadores(
      RepositorioServiciosPaseosFirestore(usuario: usuario),
    );
  }

  GestionarReservas? get reservas {
    if (widget.controladorReservas != null) return widget.controladorReservas;
    final usuario = widget.controladorSesion?.usuario;
    if (usuario == null) return null;
    return _reservas ??= GestionarReservas(
      RepositorioServiciosPaseosFirestore(usuario: usuario),
    );
  }

  GestionarAvisos? get avisos {
    if (widget.controladorAvisos != null) return widget.controladorAvisos;
    final usuario = widget.controladorSesion?.usuario;
    if (usuario == null) return null;
    return _avisos ??= GestionarAvisos(
      RepositorioAvisosPerrosFirestore(usuario: usuario),
    );
  }

  Future<bool> _abrirChatUsuario(String uid) async {
    if (chat.uid == null) return false;
    chat.conectar();
    final id = await chat.crear(uid);
    if (id == null || !mounted) return false;
    setState(() {
      conversacionInicial = id;
      seleccion = titulos.indexOf('Chat');
    });
    return true;
  }

  GestionarComunidad? get comunidad {
    if (widget.controladorComunidad != null) return widget.controladorComunidad;
    final usuario = widget.controladorSesion?.usuario;
    if (usuario == null) return null;
    return _comunidad ??= GestionarComunidad(
      RepositorioComunidadFirestore(usuario: usuario),
    );
  }

  GestionarChat get chat => _chat ??=
      widget.controladorChat ??
      GestionarChat(
        almacen: widget.controladorSesion?.usuario == null
            ? servicios.chat
            : ChatDemoSesion(),
        canal: widget.controladorSesion?.usuario == null
            ? null
            : RepositorioChatFirestore(
                uid: widget.controladorSesion!.usuario!.uid,
              ),
      );
  GestionarCruces get cruces => _cruces ??=
      widget.controladorCruces ??
      GestionarCruces(
        almacen: widget.controladorSesion?.usuario == null
            ? servicios.cruces
            : RepositorioCrucesPrivadosFirestore(
                uid: widget.controladorSesion!.usuario!.uid,
              ),
      );
  GestionarMembership get membership => _membership ??=
      widget.controladorMembership ??
      GestionarMembership(
        repositorio: widget.controladorSesion?.usuario == null
            ? servicios.membership
            : RepositorioMembershipPiloto(),
      );

  void _seleccionar(String modulo) =>
      setState(() => seleccion = titulos.indexOf(modulo));

  Future<void> _abrirChat(String id, String nombre) async {
    final conversacion = await chat.abrirMatch(id, nombre);
    if (!mounted) return;
    if (conversacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chat.error ?? 'No se pudo abrir el chat. Intenta nuevamente.',
          ),
        ),
      );
      return;
    }
    setState(() {
      conversacionInicial = conversacion;
      seleccion = titulos.indexOf('Chat');
    });
  }

  Widget get pantallaActual {
    final modulo = titulos[seleccion];
    if (modulo == 'Perdidos y encontrados') {
      return AppRescateCanino(
        controlador: avisos,
        onContactar: _abrirChatUsuario,
      );
    }
    if (modulo == 'Comunidad' || modulo == 'Paseos') {
      return AppComunidadSocial(
        controlador: comunidad,
        soloPaseos: modulo == 'Paseos',
        paseadores: modulo == 'Paseos' ? paseadores : null,
        reservas: modulo == 'Paseos' ? reservas : null,
        onContactar: _abrirChatUsuario,
      );
    }
    if (modulo == 'Chat') {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Privados'),
                Tab(text: 'Eventos y paseos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AppComunidadCanina(
                    modulo: 'Chat',
                    chat: chat,
                    conversacionInicial: conversacionInicial,
                    onAbrirChat: _abrirChat,
                  ),
                  AppComunidadSocial(controlador: comunidad, misEventos: true),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (['Inicio', 'Mis perros', 'Cruces', 'Chat'].contains(modulo)) {
      return AppComunidadCanina(
        modulo: modulo,
        chat: modulo == 'Chat' ? chat : null,
        cruces: modulo == 'Chat' ? null : cruces,
        usuario: widget.controladorSesion?.usuario,
        onSeleccion: _seleccionar,
        conversacionInicial: conversacionInicial,
        onAbrirChat: _abrirChat,
      );
    }
    if (modulo == 'Membership' || modulo == 'Carro') {
      return AppComercio(
        modulo: modulo,
        controlador: membership,
        onIrCarro: () => _seleccionar('Carro'),
        onIrMembership: () => _seleccionar('Membership'),
      );
    }
    if (modulo == 'Configuración' &&
        widget.controladorSesion?.usuario != null) {
      return ConfiguracionCuenta(
        usuario: widget.controladorSesion!.usuario!,
        sesion: widget.controladorSesion!,
      );
    }
    if (modulo == 'Configuración') {
      return AppDatosLocales(base: servicios.base);
    }
    return pantallasProvisionales[modulo] ??
        const Center(child: Text('Módulo no disponible.'));
  }

  @override
  void dispose() {
    if (widget.controladorChat == null) _chat?.dispose();
    if (widget.controladorCruces == null) _cruces?.dispose();
    if (widget.controladorMembership == null) _membership?.dispose();
    if (widget.controladorComunidad == null) _comunidad?.dispose();
    if (widget.controladorAvisos == null) _avisos?.dispose();
    if (widget.controladorPaseadores == null) _paseadores?.dispose();
    if (widget.controladorReservas == null) _reservas?.dispose();
    super.dispose();
  }

  Widget _sidebar({BuildContext? drawerContext}) => AppSidebar(
    seleccion: seleccion,
    usuario: widget.controladorSesion?.usuario,
    ocupado: widget.controladorSesion?.ocupado ?? false,
    errorSesion: widget.controladorSesion?.error,
    onCerrarSesion: widget.controladorSesion == null
        ? null
        : () {
            if (drawerContext != null) Navigator.of(drawerContext).pop();
            unawaited(widget.controladorSesion!.cerrarSesion());
          },
    onSeleccion: (index) {
      setState(() => seleccion = index);
      if (drawerContext != null) Navigator.of(drawerContext).pop();
    },
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final escritorio = constraints.maxWidth >= 900;

      return Scaffold(
        appBar: AppBar(title: Text('Champ · ${titulos[seleccion]}')),
        drawer: escritorio
            ? null
            : Drawer(
                child: Builder(
                  builder: (drawerContext) =>
                      _sidebar(drawerContext: drawerContext),
                ),
              ),
        body: Row(
          children: [
            if (escritorio) ...[
              SizedBox(width: 300, child: _sidebar()),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: pantallaActual),
          ],
        ),
      );
    },
  );
}

class ChampEntrada extends StatelessWidget {
  const ChampEntrada({super.key, this.servicios, required this.controlador});
  final ServiciosChamp? servicios;
  final GestionarSesion controlador;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder: (context, _) {
      final usuario = controlador.usuario;
      if (!controlador.listo || usuario == null) {
        return AppAcceso(controlador: controlador);
      }
      return ChampShell(
        key: ValueKey(usuario.uid),
        servicios: servicios,
        controladorSesion: controlador,
      );
    },
  );
}
