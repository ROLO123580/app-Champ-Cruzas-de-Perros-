import 'base_local.dart';
import 'http_local.dart';

/// Toda la aplicación accede a datos e imágenes mediante la misma API local.
/// Solo el servidor es propietario de SQLite y de la carpeta persistente.
ServicioBaseLocal crearServicioBase({String? url}) => HttpLocal(url: url);
