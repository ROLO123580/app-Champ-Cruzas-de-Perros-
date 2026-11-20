import 'package:flutter/material.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/ui/componentes_comunidad.dart';
import 'package:champ/nanoapps/reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';
import 'package:champ/nanoapps/reservas/vistas/solicitar_reserva.dart';
import 'package:champ/nanoapps/reservas/vistas/detalle_reserva.dart';

import 'nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';
import 'vistas/editar_paseador.dart';

class AppPaseadores extends StatefulWidget {
  const AppPaseadores({
    super.key,
    required this.controlador,
    required this.reservas,
    required this.onContactar,
  });
  final GestionarPaseadores controlador;
  final GestionarReservas reservas;
  final Future<bool> Function(String uid) onContactar;
  @override
  State<AppPaseadores> createState() => _AppPaseadoresState();
}

class _AppPaseadoresState extends State<AppPaseadores> {
  String _zona = '';
  @override
  void initState() {
    super.initState();
    widget.controlador.iniciar();
    widget.reservas.iniciar();
  }

  Future<void> _editar() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => EditarPaseador(controlador: widget.controlador),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final g = widget.controlador;
      final lista = g.catalogo
          .where((p) => '${p.zona} ${p.nombre}'.toLowerCase().contains(_zona))
          .toList();
      return MarcoComunidad(
        children: [
          Text(
            'Encuentra compañía para su paseo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Conoce al paseador, revisa sus condiciones y envía una solicitud. Champ no realiza cargos en esta etapa.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('mi_perfil_paseador'),
              onPressed: g.ocupado ? null : _editar,
              icon: const Icon(Icons.person_outline),
              label: Text(
                g.perfil == null
                    ? 'Crear mi perfil de paseador'
                    : 'Editar mi perfil de paseador',
              ),
            ),
          ),
          if (g.perfil != null)
            Text(
              g.perfil!.activo
                  ? 'Tu perfil está publicado.'
                  : 'Tu perfil está pausado y no recibe solicitudes.',
            ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre o zona',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _zona = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          if (g.cargando) const LinearProgressIndicator(),
          if (g.error != null)
            AvisoComunidad(
              g.error!,
              onReintentar: () => g.iniciar(reintentar: true),
            ),
          if (!g.cargando && g.error == null && lista.isEmpty)
            const VacioComunidad(
              titulo: 'Todavía no hay paseadores para esta zona',
              texto: 'Prueba otra zona o publica tu perfil si quieres ofrecer paseos.',
              icono: Icons.directions_walk,
            ),
          for (final p in lista)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(child: Icon(Icons.directions_walk)),
                title: Text(p.nombre),
                subtitle: Text(
                  '${p.zona} · Paseos de ${p.duracion} minutos\n${p.disponibilidad}',
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DetallePaseador(
                      perfil: p,
                      controlador: g,
                      reservas: widget.reservas,
                      onContactar: widget.onContactar,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Hasta 50 perfiles activos. Las condiciones y la disponibilidad son informadas por cada paseador.',
          ),
        ],
      );
    },
  );
}

class DetallePaseador extends StatefulWidget {
  const DetallePaseador({
    super.key,
    required this.perfil,
    required this.controlador,
    required this.reservas,
    required this.onContactar,
  });
  final PerfilPaseador perfil;
  final GestionarPaseadores controlador;
  final GestionarReservas reservas;
  final Future<bool> Function(String) onContactar;
  @override
  State<DetallePaseador> createState() => _DetallePaseadorState();
}

class _DetallePaseadorState extends State<DetallePaseador> {
  bool _contactando = false;
  String? _error;
  Future<void> _chat(String uid) async {
    setState(() {
      _contactando = true;
      _error = null;
    });
    var ok = false;
    try {
      ok = await widget.onContactar(uid);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _contactando = false;
        _error = 'No pudimos abrir el chat. Intenta nuevamente.';
      });
    }
  }

  Future<void> _solicitar(PerfilPaseador perfil) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            SolicitarReserva(controlador: widget.reservas, paseador: perfil),
      ),
    );
    if (id != null && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DetalleReserva(
            controlador: widget.reservas,
            reservaId: id,
            onContactar: widget.onContactar,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil del paseador')),
    body: ListenableBuilder(
      listenable: widget.controlador,
      builder: (context, _) {
        final candidatos = widget.controlador.catalogo
            .where((p) => p.uid == widget.perfil.uid)
            .toList();
        if (candidatos.isEmpty) {
          return const VacioComunidad(
            titulo: 'Perfil fuera del catálogo actual',
            texto:
                'Vuelve al directorio para consultar los perfiles disponibles.',
          );
        }
        final p = candidatos.first;
        final propio = p.uid == widget.controlador.uid;
        return MarcoComunidad(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 36,
                child: Icon(Icons.directions_walk, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(p.nombre, style: Theme.of(context).textTheme.headlineMedium),
            Text(p.zona),
            const SizedBox(height: 20),
            Text(p.descripcion),
            const SizedBox(height: 20),
            Text(
              'Disponibilidad',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(p.disponibilidad),
            const SizedBox(height: 20),
            Text(
              'Condiciones del servicio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(p.condiciones),
            Text('Duración: ${p.duracion} minutos'),
            const SizedBox(height: 20),
            if (_error != null) AvisoComunidad(_error!),
            if (propio)
              const Text(
                'Este es tu perfil. Puedes editarlo desde el directorio.',
              ),
            if (!propio)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('solicitar_paseador'),
                    onPressed: _contactando ? null : () => _solicitar(p),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Solicitar un paseo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _contactando ? null : () => _chat(p.uid),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      _contactando ? 'Abriendo chat…' : 'Consultar por chat',
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              'La solicitud necesita confirmación del paseador. No se realiza ningún cobro desde esta pantalla.',
            ),
          ],
        );
      },
    ),
  );
}
