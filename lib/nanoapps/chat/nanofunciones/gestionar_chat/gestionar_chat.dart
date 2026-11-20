import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/repositorios/chat_usuarios.dart';
import 'nanoactividades/persistir_chat/chat_usuarios.dart';

import '../../../../core/modelos/chat.dart';
import '../../../../core/repositorios/contratos.dart';
import '../../../../core/servicios/servicios_champ.dart';
import '../../../../core/servicios/seleccionar_foto.dart';
import '../../../../core/servicios/identificadores.dart';
import 'nanoactividades/persistir_chat/persistir_chat.dart';
import 'nanoactividades/seleccionar_foto/seleccionar_foto.dart';

class GestionarChat extends ChangeNotifier {
  GestionarChat({
    AlmacenChat? almacen,
    SeleccionarFoto? selector,
    CanalChatUsuarios? canal,
  }) : _usuarios = canal == null ? null : ChatUsuariosActividad(canal),
       _almacen = PersistirChatActividad(
         almacen ?? ServiciosChamp.predeterminados.chat,
       ),
       _selector = SeleccionarFotoActividad(selector ?? SeleccionarFoto());
  final PersistirChatActividad _almacen;
  final SeleccionarFotoActividad _selector;
  final ChatUsuariosActividad? _usuarios;
  String? get uid => _usuarios?.uid;
  String? errorUsuarios;
  bool cargandoMensajes = false;
  bool conectando = false;
  StreamSubscription<List<Conversacion>>? _suscripcion;
  StreamSubscription<List<Mensaje>>? _suscripcionMensajes;
  StreamSubscription<Map<String, String>>? _suscripcionContactos;

  /// Directorio de cuentas (UID → nombre visible), sin la cuenta propia.
  Map<String, String> contactos = const {};
  List<Conversacion> _remotas = [];
  List<Mensaje> _mensajes = [];
  String? _seleccionada;
  String? _escuchandoId;
  int _versionMensajes = 0;
  int _versionConversaciones = 0;
  List<Conversacion> _conversaciones = [];
  bool ocupado = false;
  bool cargado = false;
  String? error;
  bool _cerrado = false;
  String _id() => crearIdentificador();
  List<Conversacion> get conversaciones {
    final remotas = _remotas.map(
      (c) => Conversacion(
        id: c.id,
        nombre: _nombreDe(c),
        fecha: c.fecha,
        participantes: c.participantes,
        ultimaActividad: c.ultimaActividad,
        ultimoTexto: c.ultimoTexto,
        mensajes: c.id == _seleccionada ? _mensajes : const [],
      ),
    );
    final lista = [..._conversaciones, ...remotas]
      ..sort((a, b) => b.actualizada.compareTo(a.actualizada));
    return List.unmodifiable(lista);
  }

  /// Nombre visible de otra cuenta; nunca muestra el UID técnico.
  String nombreContacto(String otroUid) =>
      contactos[otroUid] ?? 'Usuario de Champ';

  String _nombreDe(Conversacion c) {
    final otro = c.participantes.where((p) => p != uid).firstOrNull;
    if (otro == null) return c.nombre;
    final conocido = contactos[otro];
    if (conocido != null) return conocido;
    return c.nombre == otro ? 'Usuario de Champ' : c.nombre;
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (ocupado || _cerrado) return false;
    ocupado = true;
    error = null;
    _avisar();
    try {
      await accion();
      return true;
    } catch (e) {
      error = e is StateError
          ? e.message.toString()
          : 'No se pudo completar la operación. Intenta nuevamente.';
      return false;
    } finally {
      ocupado = false;
      _avisar();
    }
  }

  Future<void> cargar() async {
    conectar();
    await _ejecutar(() async {
      _conversaciones = await _almacen.cargar();
      cargado = true;
    });
  }

  String _falloUsuarios(Object e) => e is StateError
      ? e.message.toString()
      : 'No se pudo conectar con el chat. Revisa tu conexión y la configuración de Firestore.';

  void conectar() {
    if (_usuarios == null || _cerrado) return;
    final version = ++_versionConversaciones;
    unawaited(_suscripcion?.cancel());
    unawaited(_suscripcionContactos?.cancel());
    try {
      _suscripcionContactos = _usuarios.contactos().listen(
        (mapa) {
          if (_cerrado || version != _versionConversaciones) return;
          contactos = Map.unmodifiable(mapa);
          _avisar();
        },
        // Sin directorio el chat sigue operativo con nombres genéricos.
        onError: (Object _) {},
      );
    } catch (_) {}
    conectando = true;
    errorUsuarios = null;
    try {
      _suscripcion = _usuarios.observar().listen(
        (lista) {
          if (_cerrado || version != _versionConversaciones) return;
          _remotas = lista;
          conectando = false;
          errorUsuarios = null;
          if (_seleccionada != null &&
              _escuchandoId != _seleccionada &&
              lista.any((c) => c.id == _seleccionada)) {
            seleccionar(_seleccionada);
          }
          _avisar();
        },
        onError: (Object e) {
          if (_cerrado || version != _versionConversaciones) return;
          conectando = false;
          errorUsuarios = _falloUsuarios(e);
          _avisar();
        },
      );
    } catch (e) {
      conectando = false;
      errorUsuarios = _falloUsuarios(e);
    }
    _avisar();
  }

  void seleccionar(String? id) {
    _seleccionada = id;
    final version = ++_versionMensajes;
    unawaited(_suscripcionMensajes?.cancel());
    _escuchandoId = null;
    _mensajes = [];
    cargandoMensajes = false;
    if (_usuarios != null && _remotas.any((c) => c.id == id)) {
      _escuchandoId = id;
      cargandoMensajes = true;
      errorUsuarios = null;
      try {
        _suscripcionMensajes = _usuarios
            .mensajes(id!)
            .listen(
              (lista) {
                if (_cerrado || version != _versionMensajes) return;
                _mensajes = lista;
                cargandoMensajes = false;
                errorUsuarios = null;
                _avisar();
              },
              onError: (Object e) {
                if (_cerrado || version != _versionMensajes) return;
                cargandoMensajes = false;
                errorUsuarios = _falloUsuarios(e);
                _avisar();
              },
            );
      } catch (e) {
        cargandoMensajes = false;
        errorUsuarios = _falloUsuarios(e);
      }
    }
    _avisar();
  }

  Future<void> _guardar(List<Conversacion> nuevas) async {
    await _almacen.guardar(nuevas);
    _conversaciones = nuevas;
  }

  Future<String?> crear(String nombre) async {
    if (_usuarios != null) {
      String? id;
      final ok = await _ejecutar(() async {
        final c = await _usuarios.abrir(nombre);
        if (_cerrado) return;
        _remotas = [..._remotas.where((r) => r.id != c.id), c];
        id = c.id;
      });
      return ok ? id : null;
    }
    if (!cargado || nombre.trim().isEmpty) return null;
    final id = _id();
    final ok = await _ejecutar(
      () => _guardar([
        ..._conversaciones,
        Conversacion(id: id, nombre: nombre.trim(), fecha: DateTime.now()),
      ]),
    );
    return ok ? id : null;
  }

  /// La identidad estable del match evita duplicar conversaciones al reabrirlo.
  Future<String?> abrirMatch(String id, String nombre) async {
    if (!cargado) await cargar();
    if (!cargado ||
        ocupado ||
        _cerrado ||
        id.isEmpty ||
        nombre.trim().isEmpty) {
      return null;
    }
    if (_conversaciones.any((c) => c.id == id)) return id;
    final ok = await _ejecutar(
      () => _guardar([
        ..._conversaciones,
        Conversacion(id: id, nombre: nombre.trim(), fecha: DateTime.now()),
      ]),
    );
    return ok ? id : null;
  }

  Future<void> _agregar(String id, {String? texto, Uint8List? foto}) async {
    final indice = _conversaciones.indexWhere((c) => c.id == id);
    if (indice < 0) throw StateError('La conversación ya no existe.');
    final nuevas = [..._conversaciones];
    nuevas[indice] = nuevas[indice].agregar(
      Mensaje(id: _id(), fecha: DateTime.now(), texto: texto, foto: foto),
    );
    await _guardar(nuevas);
  }

  Future<bool> enviarTexto(String id, String texto) async {
    if (texto.trim().isEmpty) return false;
    if (_usuarios != null && _remotas.any((c) => c.id == id)) {
      return _ejecutar(() => _usuarios.enviar(id, texto));
    }
    if (!cargado) return false;
    return _ejecutar(() async {
      if (texto.trim().length > 4000) {
        throw StateError('Máximo 4000 caracteres.');
      }
      await _agregar(id, texto: texto.trim());
    });
  }

  Future<bool> enviarFoto(String id) => _ejecutar(() async {
    if (!cargado) throw StateError('Espera a que se cargue el chat.');
    final foto = await _selector.ejecutar();
    if (foto != null) await _agregar(id, foto: foto);
  });
  @override
  void dispose() {
    _cerrado = true;
    unawaited(_suscripcion?.cancel());
    unawaited(_suscripcionMensajes?.cancel());
    unawaited(_suscripcionContactos?.cancel());
    super.dispose();
  }
}
