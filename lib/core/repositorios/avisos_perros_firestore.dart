import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/aviso_perro.dart';
import '../modelos/sesion.dart';
import 'avisos_perros.dart';

class RepositorioAvisosPerrosFirestore implements RepositorioAvisosPerros {
  RepositorioAvisosPerrosFirestore({
    required this.usuario,
    this._firestore,
  });
  final UsuarioChamp usuario;
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _avisos =>
      _db.collection('avisos_perros');
  @override
  String get uid => usuario.uid;
  String get _nombre {
    final nombre = usuario.nombre?.trim() ?? '';
    return nombre.isEmpty
        ? 'Usuario de Champ'
        : nombre.substring(0, nombre.length.clamp(0, 120));
  }

  AvisoPerro _leer(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AvisoPerro(
      id: doc.id,
      autorUid: d['autorUid'] as String,
      autorNombre: d['autorNombre'] as String,
      datos: DatosAvisoPerro.fromMap(d),
      resuelto: d['resuelto'] as bool,
      notaCierre: d['notaCierre'] as String,
      pendiente: doc.metadata.hasPendingWrites,
    );
  }

  @override
  Stream<List<AvisoPerro>> listar() => _avisos
      .orderBy('creado', descending: true)
      .limit(50)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(_leer).toList());
  @override
  Stream<AvisoPerro?> observar(String id) => _avisos
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((d) => d.exists ? _leer(d) : null);
  @override
  Future<void> guardar(String id, DatosAvisoPerro datos) async {
    datos.validar();
    final ref = _avisos.doc(id);
    await _db.runTransaction((tx) async {
      final previo = await tx.get(ref);
      if (previo.exists) {
        if (previo.data()!['autorUid'] != uid) {
          throw StateError('Solo puedes editar tus propios avisos.');
        }
        if (previo.data()!['resuelto'] == true) {
          throw StateError('Este aviso ya está resuelto.');
        }
        tx.update(ref, {
          ...datos.toMap(),
          'actualizado': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          ...datos.toMap(),
          'autorUid': uid,
          'autorNombre': _nombre,
          'resuelto': false,
          'notaCierre': '',
          'creado': FieldValue.serverTimestamp(),
          'actualizado': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> resolver(String id, String nota) async {
    final limpio = nota.trim();
    if (limpio.isEmpty || limpio.length > 500) {
      throw StateError('Escribe una nota de cierre de hasta 500 caracteres.');
    }
    final ref = _avisos.doc(id);
    await _db.runTransaction((tx) async {
      final previo = await tx.get(ref);
      if (!previo.exists || previo.data()!['autorUid'] != uid) {
        throw StateError('Solo quien publicó puede cerrar el aviso.');
      }
      if (previo.data()!['resuelto'] == true) return;
      tx.update(ref, {
        'resuelto': true,
        'notaCierre': limpio,
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
  }
}
