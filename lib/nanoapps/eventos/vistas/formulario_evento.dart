import 'package:flutter/material.dart';

import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/servicios/identificadores.dart';

import '../nanofunciones/gestionar_eventos/gestionar_eventos.dart';

import 'package:champ/ui/componentes_comunidad.dart';

class FormularioEvento extends StatefulWidget {
  const FormularioEvento({
    super.key,
    required this.controlador,
    this.esPaseo = false,
  });
  final GestionarEventos controlador;
  final bool esPaseo;
  @override
  State<FormularioEvento> createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<FormularioEvento> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController(),
      _descripcion = TextEditingController();
  final _lugar = TextEditingController(), _zona = TextEditingController();
  final _cupos = TextEditingController(text: '10'),
      _duracion = TextEditingController(text: '60');
  final _id = crearIdentificador();
  DateTime? _inicio;
  late bool _paseo = widget.esPaseo;
  String? _errorFecha;
  bool _tocado = false;
  @override
  void dispose() {
    for (final c in [_titulo, _descripcion, _lugar, _zona, _cupos, _duracion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: _inicio ?? ahora.add(const Duration(days: 1)),
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 730)),
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _inicio = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
      _errorFecha = null;
      _tocado = true;
    });
  }

  Future<void> _guardar() async {
    final valido = _form.currentState!.validate();
    if (_inicio == null || !_inicio!.isAfter(DateTime.now())) {
      setState(() => _errorFecha = 'Elige una fecha y hora futuras.');
      return;
    }
    if (!valido) return;
    final ok = await widget.controlador.crear(
      _id,
      BorradorEvento(
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        lugar: _lugar.text,
        zona: _zona.text,
        inicio: _inicio!,
        cupos: int.parse(_cupos.text),
        duracionMinutos: int.parse(_duracion.text),
        esPaseo: _paseo,
      ),
    );
    if (ok && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context, _id);
    }
  }

  Future<void> _salir() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin publicar?'),
        content: const Text('Lo escrito en este formulario se descartará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context);
    }
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    int limite = 120,
    int lineas = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      maxLength: limite,
      maxLines: lineas,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Completa este campo.' : null,
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final ocupado = widget.controlador.ocupado;
      return PopScope(
        canPop: !ocupado && !_tocado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !ocupado) _salir();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Crear evento')),
          body: MarcoComunidad(
            children: [
              Text(
                'Un buen plan empieza aquí',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige un parque o punto de encuentro y abre la invitación a la comunidad.',
              ),
              const SizedBox(height: 24),
              if (widget.controlador.error != null)
                AvisoComunidad(widget.controlador.error!),
              AbsorbPointer(
                absorbing: ocupado,
                child: Form(
                  key: _form,
                  onChanged: () {
                    if (!_tocado) setState(() => _tocado = true);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _campo(_titulo, 'Nombre del encuentro'),
                      DropdownButtonFormField<bool>(
                        isExpanded: true,
                        initialValue: _paseo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de actividad',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Encuentro en un parque'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Paseo compartido'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _paseo = v ?? false;
                          _tocado = true;
                        }),
                      ),
                      const SizedBox(height: 20),
                      _campo(_lugar, 'Parque o punto de encuentro'),
                      _campo(_zona, 'Ciudad o comuna'),
                      OutlinedButton.icon(
                        key: const Key('elegir_fecha_evento'),
                        onPressed: _fecha,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _inicio == null
                              ? 'Elegir fecha y hora'
                              : fechaComunidad(_inicio!),
                        ),
                      ),
                      const Text(
                        'Hora local de este equipo. Cada participante verá el horario en su propia zona horaria.',
                      ),
                      if (_errorFecha != null)
                        Text(
                          _errorFecha!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _cupos,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cupos totales',
                          helperText: 'Entre 2 y 100 personas, incluyéndote.',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 2 || n > 100
                              ? 'Ingresa entre 2 y 100 cupos.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _duracion,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duración en minutos',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 15 || n > 720
                              ? 'Ingresa entre 15 y 720 minutos.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _campo(
                        _descripcion,
                        'Cuéntanos el plan y cómo encontrarse',
                        limite: 2000,
                        lineas: 4,
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('publicar_evento'),
                onPressed: ocupado ? null : _guardar,
                icon: ocupado
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  ocupado ? 'Confirmando publicación…' : 'Publicar evento',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}
