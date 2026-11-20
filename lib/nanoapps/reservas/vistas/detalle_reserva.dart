import 'dart:async';

import 'package:flutter/material.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import '../nanofunciones/gestionar_reservas/gestionar_reservas.dart';

class DetalleReserva extends StatefulWidget {
  const DetalleReserva({
    super.key,
    required this.controlador,
    required this.reservaId,
    required this.onContactar,
  });
  final GestionarReservas controlador;
  final String reservaId;
  final Future<bool> Function(String) onContactar;
  @override
  State<DetalleReserva> createState() => _DetalleReservaState();
}

class _DetalleReservaState extends State<DetalleReserva> {
  late Stream<ReservaPaseo?> _stream = widget.controlador.observar(
    widget.reservaId,
  );
  Timer? _reloj;
  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

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
        _error = 'No pudimos abrir el chat. Vuelve a intentar.';
      });
    }
  }

  Future<void> _cambiar(ReservaPaseo r, EstadoReservaPaseo estado) async {
    if (estado == EstadoReservaPaseo.cancelada) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Cancelar esta reserva?'),
          content: const Text(
            'La otra persona verá la cancelación y el horario quedará libre.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Conservar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Cancelar reserva'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }
    await widget.controlador.cambiar(r.id, estado);
  }

  String _accion(EstadoReservaPaseo estado) => switch (estado) {
    EstadoReservaPaseo.aceptada => 'Aceptar solicitud',
    EstadoReservaPaseo.rechazada => 'Rechazar',
    EstadoReservaPaseo.cancelada => 'Cancelar reserva',
    EstadoReservaPaseo.enCurso => 'Iniciar paseo',
    EstadoReservaPaseo.finalizada => 'Finalizar paseo',
    _ => 'Enviar',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de reserva')),
    body: StreamBuilder<ReservaPaseo?>(
      stream: _stream,
      builder: (context, s) {
        if (s.hasError) {
          return MarcoComunidad(
            children: [
              AvisoComunidad(
                'No pudimos cargar la reserva.',
                onReintentar: () => setState(
                  () => _stream = widget.controlador.observar(widget.reservaId),
                ),
              ),
            ],
          );
        }
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = s.data;
        if (r == null) {
          return const VacioComunidad(
            titulo: 'Reserva no disponible',
            texto: 'Vuelve a tu agenda para revisar tus solicitudes.',
          );
        }
        return ListenableBuilder(
          listenable: widget.controlador,
          builder: (context, _) {
            final g = widget.controlador;
            final otro = g.uid == r.clienteUid ? r.paseadorUid : r.clienteUid;
            return MarcoComunidad(
              children: [
                Chip(label: Text(r.etiqueta)),
                Text(
                  'Paseo de ${r.perro}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(fechaComunidad(r.inicio)),
                  subtitle: Text(
                    '${r.duracion} minutos · hora local de este equipo',
                  ),
                ),
                Text('Paseador: ${r.paseadorNombre}'),
                Text('Responsable: ${r.clienteNombre}'),
                Text('Encuentro: ${r.zona}'),
                const SizedBox(height: 20),
                Text(
                  'Condiciones de la solicitud',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(r.condiciones),
                if (r.nota.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(r.nota),
                ],
                const SizedBox(height: 20),
                if (g.error != null) AvisoComunidad(g.error!),
                if (_error != null) AvisoComunidad(_error!),
                if (g.ocupado) const LinearProgressIndicator(),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final estado in r.acciones(g.uid))
                      FilledButton(
                        onPressed: g.ocupado || r.pendiente
                            ? null
                            : () => _cambiar(r, estado),
                        child: Text(_accion(estado)),
                      ),
                    OutlinedButton.icon(
                      onPressed: _contactando ? null : () => _chat(otro),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        _contactando ? 'Abriendo chat…' : 'Coordinar por chat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Champ conserva la solicitud y sus cambios de estado. En esta etapa no procesa cobros.',
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
