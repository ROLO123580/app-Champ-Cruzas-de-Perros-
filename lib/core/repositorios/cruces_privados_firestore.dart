import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/cruces.dart';
import 'contratos.dart';

/// Ficha e historial privados de la cuenta. No importa datos locales.
/// El catálogo de Cruces conserva explícitamente sus perfiles de demostración.
class RepositorioCrucesPrivadosFirestore extends AlmacenCruces {
  RepositorioCrucesPrivadosFirestore({required this.uid, this._firestore});
  final String uid;
  @override
  bool get enCuenta => true;
  final FirebaseFirestore? _firestore;
  int? _revision;
  DocumentReference<Map<String, dynamic>> get _ref =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('fichas_privadas_champ')
          .doc(uid);
  @override
  Future<EstadoCruces> cargar() async {
    final doc = await _ref.get(const GetOptions(source: Source.server));
    _revision = doc.exists ? doc.data()!['revision'] as int : 0;
    return doc.exists
        ? EstadoCruces.fromJson(
            jsonDecode(doc.data()!['contenido'] as String)
                as Map<String, dynamic>,
          )
        : EstadoCruces();
  }

  @override
  Future<void> guardar(EstadoCruces estado) async {
    if (_revision == null) throw StateError('Carga tu ficha antes de guardar.');
    final contenido = jsonEncode(estado.toJson());
    if (utf8.encode(contenido).length > 350000) {
      throw StateError('Reduce el tamaño de la foto antes de guardar.');
    }
    final revision = _revision!;
    await (_firestore ?? FirebaseFirestore.instance).runTransaction((tx) async {
      final actual = await tx.get(_ref);
      final version = actual.exists ? actual.data()!['revision'] as int : 0;
      if (version != revision) {
        throw StateError(
          'Tu ficha cambió en otro dispositivo. Vuelve a abrir la aplicación antes de guardar.',
        );
      }
      tx.set(_ref, {
        'contenido': contenido,
        'revision': revision + 1,
        'actualizado': FieldValue.serverTimestamp(),
      });
    });
    _revision = revision + 1;
  }
}
