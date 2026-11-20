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

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _horasSugeridas = [
  TimeOfDay(hour: 9, minute: 0),
  TimeOfDay(hour: 11, minute: 0),
  TimeOfDay(hour: 16, minute: 0),
  TimeOfDay(hour: 18, minute: 0),
];
const _duraciones = [30, 60, 90, 120, 180];

String _dos(int n) => n.toString().padLeft(2, '0');
String _textoHora(TimeOfDay h) => '${_dos(h.hour)}:${_dos(h.minute)}';
String _textoDuracion(int minutos) {
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? '$horas h' : '$horas h $resto min';
}

class _FormularioEventoState extends State<FormularioEvento> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController(),
      _descripcion = TextEditingController();
  final _lugar = TextEditingController(), _zona = TextEditingController();
  final _id = crearIdentificador();
  DateTime? _dia;
  TimeOfDay? _hora;
  int _cupos = 10;
  int _duracion = 60;
  late bool _paseo = widget.esPaseo;
  String? _errorFecha;
  bool _tocado = false;

  DateTime? get _inicio => _dia == null || _hora == null
      ? null
      : DateTime(
          _dia!.year,
          _dia!.month,
          _dia!.day,
          _hora!.hour,
          _hora!.minute,
        );

  @override
  void dispose() {
    for (final c in [_titulo, _descripcion, _lugar, _zona]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cambiar(VoidCallback cambio) => setState(() {
    cambio();
    _tocado = true;
    _errorFecha = null;
  });

  /// Atajos de día: hoy, mañana y el próximo fin de semana.
  List<(String, DateTime)> _diasRapidos() {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final opciones = <(String, DateTime)>[
      ('Hoy', hoy),
      ('Mañana', hoy.add(const Duration(days: 1))),
    ];
    for (final (nombre, diaSemana) in [
      ('Sábado', DateTime.saturday),
      ('Domingo', DateTime.sunday),
    ]) {
      var d = hoy;
      while (d.weekday != diaSemana) {
        d = d.add(const Duration(days: 1));
      }
      if (!opciones.any((o) => o.$2 == d)) opciones.add((nombre, d));
    }
    opciones.sort((a, b) => a.$2.compareTo(b.$2));
    return opciones;
  }

  Future<void> _fecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: _dia ?? ahora.add(const Duration(days: 1)),
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: ahora.add(const Duration(days: 730)),
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (hora == null || !mounted) return;
    _cambiar(() {
      _dia = DateUtils.dateOnly(dia);
      _hora = hora;
    });
  }

  Future<void> _otraHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (hora != null && mounted) _cambiar(() => _hora = hora);
  }

  Future<void> _guardar() async {
    final valido = _form.currentState!.validate();
    final inicio = _inicio;
    if (inicio == null || !inicio.isAfter(DateTime.now())) {
      setState(
        () => _errorFecha = _dia == null || _hora == null
            ? 'Elige una fecha y hora futuras.'
            : 'Esa hora ya pasó. Elige una fecha y hora futuras.',
      );
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
        inicio: inicio,
        cupos: _cupos,
        duracionMinutos: _duracion,
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
    required String ejemplo,
    IconData? icono,
    int limite = 120,
    int lineas = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLength: limite,
      maxLines: lineas,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: ejemplo,
        counterText: '',
        alignLabelWithHint: lineas > 1,
        prefixIcon: icono == null ? null : Icon(icono),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Completa este campo.' : null,
    ),
  );

  Widget _seccion(IconData icono, String titulo, List<Widget> contenido) =>
      Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      icono,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...contenido,
            ],
          ),
        ),
      );

  Widget _tipo() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (paseo, icono, titulo, detalle) in [
          (true, Icons.pets, 'Paseo compartido', 'Caminamos juntos'),
          (
            false,
            Icons.park_outlined,
            'Encuentro en un parque',
            'Juego y convivencia',
          ),
        ])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: paseo ? 6 : 0,
                left: paseo ? 0 : 6,
              ),
              child: _opcionTipo(paseo, icono, titulo, detalle),
            ),
          ),
      ],
    ),
  );

  Widget _opcionTipo(
    bool paseo,
    IconData icono,
    String titulo,
    String detalle,
  ) {
    final esquema = Theme.of(context).colorScheme;
    final elegido = _paseo == paseo;
    return Material(
      color: elegido ? esquema.primaryContainer : esquema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: elegido ? esquema.primary : esquema.outlineVariant,
          width: elegido ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _cambiar(() => _paseo = paseo),
        child: Semantics(
          selected: elegido,
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icono, size: 30, color: esquema.primary),
                const SizedBox(height: 6),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  detalle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuando() {
    final rapidos = _diasRapidos();
    final enRapidos = rapidos.any((r) => r.$2 == _dia);
    final horaSugerida = _horasSugeridas.contains(_hora);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Día', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (nombre, dia) in rapidos)
              ChoiceChip(
                label: Text(
                  nombre == 'Hoy' || nombre == 'Mañana'
                      ? nombre
                      : '$nombre ${dia.day}',
                ),
                selected: _dia == dia,
                onSelected: (_) => _cambiar(() => _dia = dia),
              ),
            ActionChip(
              key: const Key('elegir_fecha_evento'),
              avatar: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(
                _dia != null && !enRapidos
                    ? '${_dias[_dia!.weekday - 1]} ${_dia!.day}/${_dia!.month}'
                    : 'Otra fecha',
              ),
              onPressed: _fecha,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Hora', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hora in _horasSugeridas)
              ChoiceChip(
                label: Text(_textoHora(hora)),
                selected: _hora == hora,
                onSelected: (_) => _cambiar(() => _hora = hora),
              ),
            ActionChip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text(
                _hora != null && !horaSugerida
                    ? _textoHora(_hora!)
                    : 'Otra hora',
              ),
              onPressed: _otraHora,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _inicio == null
              ? 'Elige un día y una hora. Cada participante lo verá en su propia zona horaria.'
              : 'Comienza el ${fechaComunidad(_inicio!)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_errorFecha != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _errorFecha!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _cuantos() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cupos', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  'Incluyéndote a ti (2 a 100)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Menos cupos',
            onPressed: _cupos > 2 ? () => _cambiar(() => _cupos--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$_cupos',
              key: const Key('cupos_evento'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Más cupos',
            onPressed: _cupos < 100 ? () => _cambiar(() => _cupos++) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text('Duración', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final minutos in _duraciones)
            ChoiceChip(
              label: Text(_textoDuracion(minutos)),
              selected: _duracion == minutos,
              onSelected: (_) => _cambiar(() => _duracion = minutos),
            ),
        ],
      ),
    ],
  );

  Widget _barraPublicar(bool ocupado) {
    final inicio = _inicio;
    final resumen = [
      _paseo ? 'Paseo' : 'Encuentro',
      if (inicio != null) fechaComunidad(inicio),
      '$_cupos cupos',
      _textoDuracion(_duracion),
    ].join(' · ');
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    resumen,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('publicar_evento'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: ocupado ? null : _guardar,
                    icon: ocupado
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_outlined),
                    label: Text(
                      ocupado ? 'Confirmando publicación…' : 'Publicar evento',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
          bottomNavigationBar: _barraPublicar(ocupado),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Un buen plan empieza aquí',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Invita a la comunidad a pasear o jugar con sus perros.',
                    ),
                    const SizedBox(height: 16),
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
                            _seccion(
                              Icons.celebration_outlined,
                              '¿Qué harán?',
                              [
                                _tipo(),
                                const SizedBox(height: 14),
                                _campo(
                                  _titulo,
                                  'Nombre del encuentro',
                                  ejemplo:
                                      'Ej: Paseo de domingo por el Forestal',
                                ),
                              ],
                            ),
                            _seccion(Icons.place_outlined, '¿Dónde?', [
                              _campo(
                                _lugar,
                                'Parque o punto de encuentro',
                                ejemplo: 'Ej: Entrada del Parque Forestal',
                                icono: Icons.park_outlined,
                              ),
                              _campo(
                                _zona,
                                'Ciudad o comuna',
                                ejemplo: 'Ej: Santiago Centro',
                                icono: Icons.location_city_outlined,
                              ),
                            ]),
                            _seccion(Icons.event_outlined, '¿Cuándo?', [
                              _cuando(),
                            ]),
                            _seccion(
                              Icons.groups_outlined,
                              '¿Cuántos y cuánto rato?',
                              [_cuantos()],
                            ),
                            _seccion(Icons.notes_outlined, 'Detalles', [
                              _campo(
                                _descripcion,
                                'Cuéntanos el plan y cómo encontrarse',
                                ejemplo: 'Ej: Nos juntamos en la pileta. Trae agua y bolsitas. Perros con correa.',
                                limite: 2000,
                                lineas: 4,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
