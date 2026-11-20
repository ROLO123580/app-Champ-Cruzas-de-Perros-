import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/servicios_paseos.dart';
import '../modelos/sesion.dart';
import 'servicios_paseos.dart';

class RepositorioServiciosPaseosFirestore
    implements RepositorioServiciosPaseos {
  RepositorioServiciosPaseosFirestore({
    required this.usuario,
    this._firestore,
  });
  final UsuarioChamp usuario;
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _perfiles =>
      _db.collection('paseadores_champ');
  CollectionReference<Map<String, dynamic>> get _reservas =>
      _db.collection('reservas_paseos');
  @override
  String get uid => usuario.uid;
  String get _nombre {
    final n = usuario.nombre?.trim() ?? '';
    return n.isEmpty
        ? 'Usuario de Champ'
        : n.substring(0, n.length.clamp(0, 120));
  }

  ReservaPaseo _leer(DocumentSnapshot<Map<String, dynamic>> d) =>
      ReservaPaseo.fromMap(
        d.id,
        d.data()!,
        pendiente: d.metadata.hasPendingWrites,
      );
  @override
  Stream<List<PerfilPaseador>> catalogo() =>
      _perfiles.where('activo', isEqualTo: true).limit(50).snapshots().map((s) {
        final lista =
            s.docs.map((d) => PerfilPaseador.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.nombre.compareTo(b.nombre));
        return lista;
      });
  @override
  Stream<PerfilPaseador?> miPerfil() => _perfiles
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? PerfilPaseador.fromMap(s.id, s.data()!) : null);
  @override
  Stream<ReservaPaseo?> observarReserva(String id) => _reservas
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((d) => d.exists ? _leer(d) : null);
  @override
  Stream<List<ReservaPaseo>> misReservas() {
    late StreamController<List<ReservaPaseo>> salida;
    final escuchas = <StreamSubscription<dynamic>>[];
    final partes = <int, List<ReservaPaseo>>{};
    var cerrado = false;
    void fallo(Object e) {
      if (cerrado) return;
      cerrado = true;
      salida.addError(e);
      unawaited(salida.close());
    }

    salida = StreamController<List<ReservaPaseo>>(
      onListen: () {
        for (final (index, campo) in ['clienteUid', 'paseadorUid'].indexed) {
          escuchas.add(
            _reservas
                .where(campo, isEqualTo: uid)
                .limit(100)
                .snapshots(includeMetadataChanges: true)
                .listen((s) {
                  if (cerrado) return;
                  partes[index] = s.docs.map(_leer).toList();
                  if (partes.length < 2) return;
                  final porId = {
                    for (final lista in partes.values)
                      for (final r in lista) r.id: r,
                  };
                  final lista = porId.values.toList()
                    ..sort((a, b) => a.inicio.compareTo(b.inicio));
                  salida.add(lista);
                }, onError: fallo),
          );
        }
      },
      onCancel: () async {
        cerrado = true;
        await Future.wait(escuchas.map((s) => s.cancel()));
      },
    );
    return salida.stream;
  }

  @override
  Future<void> guardarPerfil(PerfilPaseador perfil) async {
    perfil.validar();
    if (perfil.uid != uid) {
      throw StateError('Solo puedes editar tu perfil.');
    }
    final ref = _perfiles.doc(uid);
    await _db.runTransaction((tx) async {
      final anterior = await tx.get(ref);
      final actual = anterior.exists
          ? (anterior.data()!['revision'] as int)
          : 0;
      if (actual != perfil.revision) {
        throw StateError(
          'El perfil cambió desde otra sesión. Vuelve a cargarlo antes de editar.',
        );
      }
      final revision = actual + 1;
      tx.set(ref, {
        ...perfil.toMap(),
        'revision': revision,
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> solicitar(String id, SolicitudPaseo solicitud) async {
    solicitud.validar();
    if (solicitud.paseador.uid == uid) {
      throw StateError('Elige otro paseador para enviar una solicitud.');
    }
    final ref = _reservas.doc(id);
    await _db.runTransaction((tx) async {
      final previo = await tx.get(ref);
      if (previo.exists) {
        if (previo.data()!['clienteUid'] != uid) {
          throw StateError('Reserva no disponible.');
        }
        return;
      }
      final snapshot = await tx.get(_perfiles.doc(solicitud.paseador.uid));
      if (!snapshot.exists) {
        throw StateError('El perfil ya no está disponible.');
      }
      final actual = PerfilPaseador.fromMap(snapshot.id, snapshot.data()!);
      if (!actual.activo || actual.revision != solicitud.paseador.revision) {
        throw StateError(
          'Las condiciones cambiaron. Vuelve a abrir el perfil antes de solicitar.',
        );
      }
      tx.set(ref, {
        'clienteUid': uid,
        'clienteNombre': _nombre,
        'paseadorUid': actual.uid,
        'paseadorNombre': actual.nombre,
        'perro': solicitud.perro.trim(),
        'zona': solicitud.zona.trim(),
        'inicioMs': solicitud.inicio.millisecondsSinceEpoch,
        'bloqueInicial': solicitud.inicio.millisecondsSinceEpoch ~/ 1800000,
        'duracion': actual.duracion,
        'condiciones': actual.condiciones,
        'perfilRevision': actual.revision,
        'nota': solicitud.nota.trim(),
        'estado': 'solicitada',
        'creado': FieldValue.serverTimestamp(),
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> cambiarEstado(String id, EstadoReservaPaseo estado) async {
    final ref = _reservas.doc(id);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw StateError('Reserva no disponible.');
      }
      final reserva = _leer(snapshot);
      if (reserva.estado == estado) return;
      if (!reserva.acciones(uid).contains(estado)) {
        throw StateError(
          'Este cambio no está permitido para tu cuenta o para este horario.',
        );
      }
      final bloques = reserva.bloques
          .map(
            (n) => _db
                .collection('bloques_paseadores')
                .doc('${reserva.paseadorUid}_$n'),
          )
          .toList();
      if (estado == EstadoReservaPaseo.aceptada) {
        if (!reserva.inicio.isAfter(DateTime.now())) {
          throw StateError('La hora de esta solicitud ya pasó.');
        }
        for (final bloque in bloques) {
          final ocupado = await tx.get(bloque);
          if (ocupado.exists) {
            throw StateError('Ya tienes un paseo confirmado en ese horario.');
          }
        }
        for (final (i, bloque) in bloques.indexed) {
          tx.set(bloque, {
            'reservaId': id,
            'paseadorUid': uid,
            'bloque': reserva.bloques[i],
          });
        }
      } else if ((estado == EstadoReservaPaseo.cancelada ||
              estado == EstadoReservaPaseo.finalizada) &&
          reserva.estado != EstadoReservaPaseo.solicitada) {
        for (final bloque in bloques) {
          tx.delete(bloque);
        }
      }
      tx.update(ref, {
        'estado': estado.name,
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
  }
}
