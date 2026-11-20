import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/chat.dart';
import 'chat_usuarios.dart';

class RepositorioChatFirestore implements CanalChatUsuarios {
  RepositorioChatFirestore({required this.uid, this.firestore});
  @override
  final String uid;
  final FirebaseFirestore? firestore;
  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  void _validarSesion() {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Inicia sesión nuevamente para usar el chat.');
    }
  }

  static String identidad(String uno, String otro) {
    final participantes = [uno, otro]..sort();
    return 'usuarios_${sha256.convert(utf8.encode(jsonEncode(participantes)))}';
  }

  Conversacion _leer(String id, Map<String, dynamic> datos) {
    final participantes = List<String>.from(datos['participantes'] as List);
    return Conversacion(
      id: id,
      nombre: participantes.firstWhere((p) => p != uid),
      participantes: participantes,
      fecha: (datos['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimaActividad: (datos['actualizada'] as Timestamp?)?.toDate(),
      ultimoTexto: datos['ultimoTexto'] as String?,
    );
  }

  @override
  Stream<List<Conversacion>> conversaciones() {
    _validarSesion();
    return _chats
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => _leer(d.id, d.data())).toList());
  }

  @override
  Stream<List<Mensaje>> mensajes(String conversacionId) {
    _validarSesion();
    return _chats
        .doc(conversacionId)
        .collection('mensajes')
        .orderBy('fecha', descending: true)
        .limit(100)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
          return s.docs.reversed.map((d) {
            final datos = d.data();
            return Mensaje(
              id: d.id,
              fecha: (datos['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
              texto: datos['texto'] as String,
              remitenteId: datos['remitenteId'] as String,
              pendiente: d.metadata.hasPendingWrites,
            );
          }).toList();
        });
  }

  @override
  Future<Conversacion> abrir(String destinatarioUid) async {
    _validarSesion();
    final otro = destinatarioUid.trim();
    if (otro.isEmpty ||
        otro == uid ||
        otro.length > 128 ||
        otro.contains('/')) {
      throw StateError(
        'Escribe el ID de otra cuenta de Champ (hasta 128 caracteres).',
      );
    }
    final participantes = [uid, otro]..sort();
    final ref = _chats.doc(identidad(uid, otro));
    final datos = await _db.runTransaction<Map<String, dynamic>>((tx) async {
      final existente = await tx.get(ref);
      if (existente.exists) return existente.data()!;
      final nuevo = <String, dynamic>{
        'participantes': participantes,
        'fecha': FieldValue.serverTimestamp(),
        'actualizada': FieldValue.serverTimestamp(),
        'ultimoTexto': '',
      };
      tx.set(ref, nuevo);
      return {
        ...nuevo,
        'fecha': Timestamp.now(),
        'actualizada': Timestamp.now(),
      };
    });
    return _leer(ref.id, datos);
  }

  @override
  Future<void> enviar(String conversacionId, String texto) async {
    _validarSesion();
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.runes.length > 4000) {
      throw StateError('Escribe un mensaje de hasta 4000 caracteres.');
    }
    final ref = _chats.doc(conversacionId);
    final lote = _db.batch();
    lote.set(ref.collection('mensajes').doc(), {
      'remitenteId': uid,
      'texto': limpio,
      'fecha': FieldValue.serverTimestamp(),
    });
    lote.update(ref, {
      'actualizada': FieldValue.serverTimestamp(),
      'ultimoTexto': limpio,
    });
    await lote.commit();
  }
}
