import 'dart:math';

/// Identidad independiente del reloj y de los contadores de cada ventana.
String crearIdentificador() {
  final azar = Random.secure();
  return List.generate(
    16,
    (_) => azar.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
