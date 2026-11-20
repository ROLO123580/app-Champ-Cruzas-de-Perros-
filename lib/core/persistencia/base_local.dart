import 'dart:convert';
import 'dart:typed_data';

/// Contrato del cliente API y del motor de almacenamiento que utiliza el servidor.
abstract class ServicioBaseLocal {
  Future<Map<String, dynamic>> ejecutar(
    String operacion,
    Map<String, dynamic> argumentos,
  );
  Future<void> cerrar();
}

class BaseLocal {
  BaseLocal(this.servicio);
  final ServicioBaseLocal servicio;
  Future<Map<String, dynamic>> operar(
    String op, [
    Map<String, dynamic> args = const {},
  ]) => servicio.ejecutar(op, args);
  Future<Map<String, dynamic>?> obtener(String coleccion, String id) async =>
      (await operar('obtener', {'coleccion': coleccion, 'id': id}))['registro']
          as Map<String, dynamic>?;
  Future<List<Map<String, dynamic>>> listar(String coleccion) async =>
      ((await operar('listar', {'coleccion': coleccion}))['registros'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
  Future<void> guardar(
    String coleccion,
    String id,
    Map<String, dynamic> datos,
  ) => aplicar([
    {'tipo': 'guardar', 'coleccion': coleccion, 'id': id, 'datos': datos},
  ]);
  Future<void> eliminar(String coleccion, String id) => aplicar([
    {'tipo': 'eliminar', 'coleccion': coleccion, 'id': id},
  ]);
  Future<void> aplicar(List<Map<String, dynamic>> cambios) async {
    await operar('aplicar', {'cambios': cambios});
  }

  Future<String> guardarImagen(Uint8List bytes) async =>
      (await operar('guardar_imagen', {
            'bytes': base64Encode(bytes),
          }))['referencia']
          as String;
  Future<Uint8List> leerImagen(String referencia) async => base64Decode(
    (await operar('leer_imagen', {'referencia': referencia}))['bytes']
        as String,
  );
  Future<void> registrarLike(String origen, String destino, String decision) =>
      aplicar([
        {
          'tipo': 'like',
          'origen': origen,
          'destino': destino,
          'decision': decision,
        },
      ]);
  Future<List<Map<String, dynamic>>> likes(String origen) async =>
      ((await operar('likes', {'origen': origen}))['likes'] as List)
          .cast<Map<String, dynamic>>();
  Future<List<Map<String, dynamic>>> matches(String origen) async =>
      ((await operar('matches', {'origen': origen}))['matches'] as List)
          .cast<Map<String, dynamic>>();
  Future<Map<String, dynamic>> estado() => operar('estado');
  Future<String> respaldar() async =>
      (await operar('respaldar'))['ruta'] as String;
  Future<void> cerrar() => servicio.cerrar();
}
