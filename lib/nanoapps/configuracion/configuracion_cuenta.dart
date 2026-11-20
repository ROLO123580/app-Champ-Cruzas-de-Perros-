import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/modelos/sesion.dart';
import '../login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'nanofunciones/gestionar_preferencias/gestionar_preferencias.dart';

class ConfiguracionCuenta extends StatefulWidget {
  const ConfiguracionCuenta({
    super.key,
    required this.usuario,
    required this.sesion,
  });
  final UsuarioChamp usuario;
  final GestionarSesion sesion;
  @override
  State<ConfiguracionCuenta> createState() => _ConfiguracionCuentaState();
}

class _ConfiguracionCuentaState extends State<ConfiguracionCuenta> {
  Future<void> _copiar() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.usuario.uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Identificador copiado. Compártelo con quien quieras conversar.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo copiar. Puedes seleccionar el identificador manualmente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _salir() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tus datos guardados se conservan. Para volver a verlos, entra con esta misma cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) await widget.sesion.cerrarSesion();
  }

  Widget _titulo(String texto, IconData icono) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Icon(icono),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final p = PreferenciasChamp.de(context);
    final u = widget.usuario;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListenableBuilder(
          listenable: widget.sesion,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Configuración',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu cuenta, la apariencia de Champ y el cuidado de tus datos.',
              ),
              _titulo('Mi cuenta', Icons.account_circle_outlined),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nombre?.trim().isNotEmpty == true
                            ? u.nombre!
                            : 'Usuario de Champ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (u.correo != null) SelectableText(u.correo!),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Mi identificador para chat'),
                        subtitle: const Text(
                          'Permite que otra persona inicie una conversación contigo.',
                        ),
                        children: [
                          SelectableText(u.uid),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copiar,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar identificador'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.sesion.error != null)
                        Text(
                          widget.sesion.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: widget.sesion.ocupado ? null : _salir,
                        icon: const Icon(Icons.logout),
                        label: Text(
                          widget.sesion.ocupado
                              ? 'Cerrando sesión…'
                              : 'Cerrar sesión',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (p != null) ...[
                _titulo('Apariencia', Icons.palette_outlined),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estas preferencias se guardan en este navegador o equipo y se aplican a todas sus sesiones.',
                        ),
                        const SizedBox(height: 16),
                        if (p.ocupado) const LinearProgressIndicator(),
                        DropdownButtonFormField<ThemeMode>(
                          key: ValueKey('tema-${p.modo.name}'),
                          initialValue: p.modo,
                          decoration: const InputDecoration(
                            labelText: 'Tema',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Según el sistema'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Claro'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Oscuro'),
                            ),
                          ],
                          onChanged: p.ocupado || !p.cargado
                              ? null
                              : (v) {
                                  if (v != null) p.cambiar(tema: v);
                                },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<double>(
                          key: ValueKey('texto-${p.escala}'),
                          initialValue: p.escala,
                          decoration: const InputDecoration(
                            labelText: 'Tamaño del texto',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Normal')),
                            DropdownMenuItem(
                              value: 1.15,
                              child: Text('Grande'),
                            ),
                            DropdownMenuItem(
                              value: 1.3,
                              child: Text('Más grande'),
                            ),
                          ],
                          onChanged: p.ocupado || !p.cargado
                              ? null
                              : (v) {
                                  if (v != null) p.cambiar(texto: v);
                                },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Vista previa: un paseo, nuevas amistades y tiempo juntos.',
                        ),
                        if (p.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              p.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (!p.cargado && !p.ocupado)
                          TextButton(
                            onPressed: p.cargar,
                            child: const Text('Reintentar preferencias'),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: p.ocupado ? null : p.restablecer,
                          child: const Text('Restablecer apariencia'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              _titulo('Privacidad y datos', Icons.privacy_tip_outlined),
              const Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('Tu información privada'),
                      subtitle: Text(
                        'La ficha activa de tu perro pertenece a tu cuenta. Las reservas son privadas para cliente y paseador; los chats, para sus participantes.',
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.people_outline),
                      title: Text('Lo que compartes'),
                      subtitle: Text(
                        'El muro, los eventos, los avisos y los perfiles activos de paseadores son visibles para otros usuarios autenticados de Champ. Revisa los datos antes de publicarlos.',
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.storage_outlined),
                      title: Text('Datos anteriores de este equipo'),
                      subtitle: Text(
                        'Los archivos SQLite anteriores se conservan. No se importan automáticamente a tu cuenta ni se ofrecen sus respaldos a otras cuentas.',
                      ),
                    ),
                  ],
                ),
              ),
              _titulo('Ayuda', Icons.help_outline),
              const Card(
                child: Column(
                  children: [
                    ExpansionTile(
                      title: Text('¿Cómo funciona una reserva?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Revisa las condiciones del paseador y solicita una fecha futura, a las :00 o :30. El paseo queda confirmado cuando el paseador acepta. Puedes seguir el estado desde Paseos → Mi agenda.',
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: Text('¿Qué es de demostración?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Cruces incluye perros e intereses de ejemplo. Sus matches no provienen de personas reales. El chat de esos ejemplos en una cuenta autenticada dura esta sesión y no envía mensajes a nadie.',
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: Text('¿El microchip muestra la ubicación?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'El microchip permite identificar al perro con un lector físico; no ofrece rastreo GPS. En los avisos solo se muestran, si los informas, los últimos cuatro dígitos.',
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: Text('¿Champ realiza cobros?'),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'En esta etapa no se procesan pagos ni se contratan membresías. Solicitar un paseo no genera un cargo en Champ.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Champ · versión 1.0.0 (1)'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
