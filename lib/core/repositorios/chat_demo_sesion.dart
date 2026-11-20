import '../modelos/chat.dart';
import 'contratos.dart';

/// Conversaciones de demostración aisladas de la instalación y de otras cuentas.
/// Los mensajes entre personas se guardan mediante CanalChatUsuarios.
class ChatDemoSesion implements AlmacenChat {
  List<Conversacion> _lista = [];
  @override
  Future<List<Conversacion>> cargar() async => List.of(_lista);
  @override
  Future<void> guardar(List<Conversacion> conversaciones) async {
    _lista = List.of(conversaciones);
  }
}
