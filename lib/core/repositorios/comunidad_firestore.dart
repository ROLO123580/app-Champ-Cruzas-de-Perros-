import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/comunidad.dart';
import '../modelos/sesion.dart';
import 'comunidad.dart';

class RepositorioComunidadFirestore implements RepositorioComunidad {
  RepositorioComunidadFirestore({required this.usuario, this._firestore});
  final UsuarioChamp usuario;
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;
  @override
  String get uid => usuario.uid;
  String get nombre => (usuario.nombre?.trim().isNotEmpty ?? false)
      ? usuario.nombre!.trim().substring(
          0,
          usuario.nombre!.trim().length.clamp(0, 120),
        )
      : 'Participante';
  CollectionReference<Map<String, dynamic>> get _eventos =>
      db.collection('eventos_champ');
  CollectionReference<Map<String, dynamic>> get _muro =>
      db.collection('muro_champ');

  EventoChamp _evento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EventoChamp(
      id: doc.id,
      autorUid: d['autorUid'] as String,
      autorNombre: d['autorNombre'] as String,
      datos: BorradorEvento(
        titulo: d['titulo'] as String,
        descripcion: d['descripcion'] as String,
        lugar: d['lugar'] as String,
        zona: d['zona'] as String,
        inicio: DateTime.fromMillisecondsSinceEpoch(d['inicioMs'] as int),
        cupos: d['cupos'] as int,
        duracionMinutos: d['duracion'] as int,
        esPaseo: d['tipo'] == 'paseo',
      ),
      participantes: Map<String, String>.from(d['participantes'] as Map),
      cancelado: d['cancelado'] == true,
      pendiente: doc.metadata.hasPendingWrites,
    );
  }

  @override
  Stream<List<EventoChamp>> eventos() => _eventos
      .orderBy('creado', descending: true)
      .limit(100)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(_evento).toList());
  @override
  Stream<EventoChamp?> evento(String id) => _eventos
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.exists ? _evento(s) : null);
  @override
  Stream<List<PublicacionChamp>> publicaciones() => _muro
      .orderBy('creado', descending: true)
      .limit(100)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => s.docs
            .map(
              (d) => PublicacionChamp(
                id: d.id,
                autorNombre: d.data()['autorNombre'] as String,
                texto: d.data()['texto'] as String,
                fecha:
                    (d.data()['creado'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                pendiente: d.metadata.hasPendingWrites,
              ),
            )
            .toList(),
      );

  @override
  Future<void> crearEvento(String id, BorradorEvento datos) async {
    datos.validar();
    final ref = _eventos.doc(id);
    await db.runTransaction((tx) async {
      final previo = await tx.get(ref);
      if (previo.exists) {
        if (previo.data()!['autorUid'] != uid) {
          throw StateError('Identidad de evento no disponible.');
        }
        return;
      }
      tx.set(ref, {
        'autorUid': uid,
        'autorNombre': nombre,
        'titulo': datos.titulo.trim(),
        'descripcion': datos.descripcion.trim(),
        'lugar': datos.lugar.trim(),
        'zona': datos.zona.trim(),
        'inicioMs': datos.inicio.millisecondsSinceEpoch,
        'duracion': datos.duracionMinutos,
        'cupos': datos.cupos,
        'tipo': datos.esPaseo ? 'paseo' : 'evento',
        'participantes': {uid: nombre},
        'cancelado': false,
        'creado': FieldValue.serverTimestamp(),
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> publicar(String id, String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.length > 2000) {
      throw StateError('Escribe entre 1 y 2000 caracteres.');
    }
    final ref = _muro.doc(id);
    await db.runTransaction((tx) async {
      final previo = await tx.get(ref);
      if (previo.exists) {
        if (previo.data()!['autorUid'] != uid) {
          throw StateError('Publicación no disponible.');
        }
        return;
      }
      tx.set(ref, {
        'autorUid': uid,
        'autorNombre': nombre,
        'texto': limpio,
        'creado': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> participar(String eventoId, bool inscribir) =>
      db.runTransaction((tx) async {
        final ref = _eventos.doc(eventoId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) throw StateError('Este evento ya no existe.');
        final actual = _evento(snapshot);
        if (actual.autorUid == uid) {
          throw StateError('Eres el organizador de este evento.');
        }
        final miembros = Map<String, String>.from(actual.participantes);
        if (inscribir) {
          if (!actual.inscripcionesAbiertas) {
            throw StateError('Las inscripciones están cerradas.');
          }
          if (miembros.containsKey(uid)) return;
          if (actual.disponibles <= 0) {
            throw StateError('Ya no quedan cupos disponibles.');
          }
          miembros[uid] = nombre;
        } else {
          if (!miembros.containsKey(uid)) return;
          miembros.remove(uid);
        }
        tx.update(ref, {
          'participantes': miembros,
          'actualizado': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> cancelar(String eventoId) => db.runTransaction((tx) async {
    final ref = _eventos.doc(eventoId);
    final actual = await tx.get(ref);
    if (!actual.exists || actual.data()!['autorUid'] != uid) {
      throw StateError('Solo el organizador puede cancelar.');
    }
    if (actual.data()!['cancelado'] == true) return;
    tx.update(ref, {
      'cancelado': true,
      'actualizado': FieldValue.serverTimestamp(),
    });
  });

  @override
  Stream<List<MensajeEvento>> mensajes(String eventoId) => _eventos
      .doc(eventoId)
      .collection('mensajes')
      .orderBy('fecha', descending: true)
      .limit(100)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => s.docs.reversed
            .map(
              (d) => MensajeEvento(
                id: d.id,
                uid: d.data()['uid'] as String,
                nombre: d.data()['nombre'] as String,
                texto: d.data()['texto'] as String,
                fecha:
                    (d.data()['fecha'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                pendiente: d.metadata.hasPendingWrites,
              ),
            )
            .toList(),
      );

  @override
  Future<void> enviar(String eventoId, String mensajeId, String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.length > 4000) {
      throw StateError('Escribe entre 1 y 4000 caracteres.');
    }
    final eventoRef = _eventos.doc(eventoId);
    final mensajeRef = eventoRef.collection('mensajes').doc(mensajeId);
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(eventoRef);
      if (!snapshot.exists) throw StateError('Evento no disponible.');
      final actual = _evento(snapshot);
      if (!actual.participantes.containsKey(uid)) {
        throw StateError('Inscríbete para participar en este chat.');
      }
      if (!actual.chatAbierto) {
        throw StateError('El chat está cerrado para nuevos mensajes.');
      }
      final previo = await tx.get(mensajeRef);
      if (previo.exists) return;
      tx.set(mensajeRef, {
        'uid': uid,
        'nombre': nombre,
        'texto': limpio,
        'fecha': FieldValue.serverTimestamp(),
      });
    });
  }
}
