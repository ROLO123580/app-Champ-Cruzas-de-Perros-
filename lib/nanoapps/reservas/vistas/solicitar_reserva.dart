import 'package:flutter/material.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/servicios/identificadores.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import '../nanofunciones/gestionar_reservas/gestionar_reservas.dart';

class SolicitarReserva extends StatefulWidget {
  const SolicitarReserva({
    super.key,
    required this.controlador,
    required this.paseador,
  });
  final GestionarReservas controlador;
  final PerfilPaseador paseador;
  @override
  State<SolicitarReserva> createState() => _SolicitarReservaState();
}

class _SolicitarReservaState extends State<SolicitarReserva> {
  final _form = GlobalKey<FormState>();
  final _perro = TextEditingController(),
      _zona = TextEditingController(),
      _nota = TextEditingController();
  final _id = crearIdentificador();
  DateTime? _inicio;
  bool _leido = false;
  bool _tocado = false;
  bool _confirmandoSalida = false;
  String? _validacion;
  @override
  void dispose() {
    _perro.dispose();
    _zona.dispose();
    _nota.dispose();
    super.dispose();
  }

  Future<void> _fecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: ahora.add(const Duration(days: 1)),
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (hora == null || !mounted) return;
    if (hora.minute != 0 && hora.minute != 30) {
      setState(() {
        _inicio = null;
        _tocado = true;
        _validacion = 'Elige una hora terminada en :00 o :30.';
      });
      return;
    }
    final elegido = DateTime(
      dia.year,
      dia.month,
      dia.day,
      hora.hour,
      hora.minute,
    );
    if (!elegido.isAfter(DateTime.now())) {
      setState(() {
        _inicio = null;
        _tocado = true;
        _validacion = 'Elige una fecha y hora futuras.';
      });
      return;
    }
    setState(() {
      _tocado = true;
      _validacion = null;
    });
    setState(
      () => _inicio = DateTime(
        dia.year,
        dia.month,
        dia.day,
        hora.hour,
        hora.minute,
      ),
    );
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate() || _inicio == null || !_leido) {
      setState(
        () => _validacion =
            'Completa los datos, el horario y la revisión de las condiciones.',
      );
      return;
    }
    setState(() => _validacion = null);
    final ok = await widget.controlador.solicitar(
      _id,
      SolicitudPaseo(
        paseador: widget.paseador,
        perro: _perro.text,
        zona: _zona.text,
        inicio: _inicio!,
        nota: _nota.text,
      ),
    );
    if (ok && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context, _id);
    }
  }

  Future<void> _salir() async {
    if (_confirmandoSalida) return;
    _confirmandoSalida = true;
    final descartar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Descartar la solicitud?'),
        content: const Text(
          'Todavía no se ha enviado. Si sales, perderás lo que escribiste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    _confirmandoSalida = false;
    if (descartar == true && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final g = widget.controlador;
      final p = widget.paseador;
      return PopScope(
        canPop: !g.ocupado && !_tocado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !g.ocupado) _salir();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Solicitar paseo')),
          body: MarcoComunidad(
            children: [
              Text(
                'Paseo con ${p.nombre}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text('${p.duracion} minutos · ${p.zona}'),
              const SizedBox(height: 16),
              Form(
                key: _form,
                onChanged: () => setState(() => _tocado = true),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _perro,
                      readOnly: g.ocupado,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del perro',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indica el perro.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zona,
                      readOnly: g.ocupado,
                      maxLength: 160,
                      decoration: const InputDecoration(
                        labelText: 'Zona o referencia de encuentro',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indica la zona.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('fecha_reserva'),
                      onPressed: g.ocupado ? null : _fecha,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _inicio == null
                            ? 'Elegir fecha y hora'
                            : fechaComunidad(_inicio!),
                      ),
                    ),
                    const Text(
                      'Selecciona horarios en intervalos de 30 minutos. El paseador confirmará la solicitud.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nota,
                      readOnly: g.ocupado,
                      maxLength: 1000,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones del perro (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Condiciones que estás revisando',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(p.condiciones),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('He leído las condiciones del paseo'),
                value: _leido,
                onChanged: g.ocupado
                    ? null
                    : (v) => setState(() {
                        _leido = v ?? false;
                        _tocado = true;
                      }),
              ),
              const Text(
                'Enviar la solicitud no realiza ningún cargo. Las condiciones quedan guardadas para que ambos puedan consultarlas.',
              ),
              if (_validacion != null) AvisoComunidad(_validacion!),
              if (g.error != null) AvisoComunidad(g.error!),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('enviar_solicitud_paseo'),
                onPressed: g.ocupado ? null : _enviar,
                child: Text(g.ocupado ? 'Enviando…' : 'Enviar solicitud'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}
