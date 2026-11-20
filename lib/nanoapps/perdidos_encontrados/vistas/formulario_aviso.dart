import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/core/servicios/identificadores.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import '../nanofunciones/gestionar_avisos/gestionar_avisos.dart';

class FormularioAviso extends StatefulWidget {
  const FormularioAviso({super.key, required this.controlador, this.aviso});
  final GestionarAvisos controlador;
  final AvisoPerro? aviso;
  @override
  State<FormularioAviso> createState() => _FormularioAvisoState();
}

class _FormularioAvisoState extends State<FormularioAviso> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(
    text: widget.aviso?.datos.nombre ?? '',
  );
  late final _raza = TextEditingController(
    text: widget.aviso?.datos.raza ?? '',
  );
  late final _zona = TextEditingController(
    text: widget.aviso?.datos.zona ?? '',
  );
  late final _lugar = TextEditingController(
    text: widget.aviso?.datos.lugar ?? '',
  );
  late final _descripcion = TextEditingController(
    text: widget.aviso?.datos.descripcion ?? '',
  );
  late final _chipUltimos = TextEditingController(
    text: widget.aviso?.datos.chipUltimos ?? '',
  );
  late final _id = widget.aviso?.id ?? crearIdentificador();
  late TipoAvisoPerro _tipo =
      widget.aviso?.datos.tipo ?? TipoAvisoPerro.perdido;
  late String _chip = widget.aviso?.datos.chip ?? 'desconocido',
      _foto = widget.aviso?.datos.fotoBase64 ?? '';
  late DateTime _fecha = widget.aviso?.datos.fechaVista ?? DateTime.now();
  bool _tocado = false;
  String? _validacion;
  @override
  void dispose() {
    for (final c in [
      _nombre,
      _raza,
      _zona,
      _lugar,
      _descripcion,
      _chipUltimos,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: ahora,
    );
    if (dia == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _fecha = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
      _tocado = true;
    });
  }

  Future<void> _seleccionarFoto() async {
    final foto = await widget.controlador.seleccionarFoto();
    if (foto != null && mounted) {
      setState(() {
        _foto = base64Encode(foto);
        _tocado = true;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) {
      setState(
        () => _validacion = 'Revisa los campos indicados antes de publicar.',
      );
      return;
    }
    setState(() => _validacion = null);
    final ok = await widget.controlador.guardar(
      _id,
      DatosAvisoPerro(
        tipo: _tipo,
        nombre: _nombre.text,
        raza: _raza.text,
        zona: _zona.text,
        lugar: _lugar.text,
        descripcion: _descripcion.text,
        fechaVista: _fecha,
        chip: _chip,
        chipUltimos: _chipUltimos.text.trim(),
        fotoBase64: _foto,
      ),
    );
    if (ok && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context, _id);
    }
  }

  Future<void> _salir() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Se descartará lo escrito en este formulario.'),
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
    if (salir == true && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context);
    }
  }

  Widget _campo(
    TextEditingController c,
    String titulo, {
    int limite = 120,
    int lineas = 1,
    bool obligatorio = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      readOnly: widget.controlador.ocupado,
      maxLength: limite,
      maxLines: lineas,
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => obligatorio && (v == null || v.trim().isEmpty)
          ? 'Completa este campo.'
          : null,
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final g = widget.controlador;
      final ocupado = g.ocupado;
      return PopScope(
        canPop: !ocupado && !_tocado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !ocupado) _salir();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.aviso == null ? 'Publicar aviso' : 'Editar aviso',
            ),
          ),
          body: MarcoComunidad(
            children: [
              Text(
                'Cada dato puede ayudar',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe al perro y la última zona donde fue visto. Puedes dejar el nombre vacío si no lo conoces.',
              ),
              const SizedBox(height: 20),
              if (ocupado) const LinearProgressIndicator(),
              Form(
                key: _form,
                onChanged: () {
                  if (!_tocado) setState(() => _tocado = true);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<TipoAvisoPerro>(
                      key: const Key('tipo_aviso'),
                      isExpanded: true,
                      initialValue: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de aviso',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TipoAvisoPerro.perdido,
                          child: Text('Perdí a mi perro'),
                        ),
                        DropdownMenuItem(
                          value: TipoAvisoPerro.encontrado,
                          child: Text('Encontré un perro'),
                        ),
                      ],
                      onChanged: ocupado
                          ? null
                          : (v) => setState(() {
                              _tipo = v!;
                              _tocado = true;
                            }),
                    ),
                    const SizedBox(height: 20),
                    _campo(
                      _nombre,
                      'Nombre del perro (si lo conoces)',
                      limite: 80,
                    ),
                    _campo(_raza, 'Raza o mezcla (opcional)', limite: 80),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('foto_aviso'),
                          onPressed: ocupado ? null : _seleccionarFoto,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _foto.isEmpty ? 'Añadir foto' : 'Cambiar foto',
                          ),
                        ),
                        if (_foto.isNotEmpty)
                          TextButton(
                            onPressed: ocupado
                                ? null
                                : () => setState(() {
                                    _foto = '';
                                    _tocado = true;
                                  }),
                            child: const Text('Quitar foto'),
                          ),
                      ],
                    ),
                    if (_foto.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Image.memory(
                          base64Decode(_foto),
                          height: 180,
                          cacheWidth: 480,
                          cacheHeight: 360,
                          fit: BoxFit.contain,
                        ),
                      ),
                    const Text(
                      'Foto opcional de hasta 1 MB. Champ prepara una copia reducida para compartir el aviso.',
                    ),
                    const SizedBox(height: 20),
                    _campo(_zona, 'Ciudad o comuna', obligatorio: true),
                    _campo(
                      _lugar,
                      'Último lugar o referencia',
                      limite: 160,
                      obligatorio: true,
                    ),
                    OutlinedButton.icon(
                      onPressed: ocupado ? null : _elegirFecha,
                      icon: const Icon(Icons.schedule),
                      label: Text('Visto: ${fechaComunidad(_fecha)}'),
                    ),
                    const Text('Fecha y hora local del último avistamiento.'),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      key: const Key('chip_aviso'),
                      isExpanded: true,
                      initialValue: _chip,
                      decoration: const InputDecoration(
                        labelText: '¿Tiene microchip?',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'desconocido',
                          child: Text('No lo sé'),
                        ),
                        DropdownMenuItem(value: 'si', child: Text('Sí')),
                        DropdownMenuItem(value: 'no', child: Text('No')),
                      ],
                      onChanged: ocupado
                          ? null
                          : (v) => setState(() {
                              _chip = v!;
                              if (_chip != 'si') _chipUltimos.clear();
                              _tocado = true;
                            }),
                    ),
                    if (_chip == 'si')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          key: const Key('chip_ultimos_aviso'),
                          controller: _chipUltimos,
                          readOnly: ocupado,
                          maxLength: 4,
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Últimos 4 dígitos del chip (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v != null &&
                                  v.isNotEmpty &&
                                  !RegExp(r'^[0-9]{4}$').hasMatch(v)
                              ? 'Escribe solo los últimos 4 dígitos.'
                              : null,
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'El chip se lee con un escáner cercano; no transmite ubicación GPS. Los últimos dígitos ayudan a cotejar, pero no identifican por sí solos al perro.',
                    ),
                    const SizedBox(height: 20),
                    _campo(
                      _descripcion,
                      'Señas y detalles para reconocerlo',
                      limite: 2000,
                      lineas: 4,
                      obligatorio: true,
                    ),
                  ],
                ),
              ),
              if (_validacion != null) AvisoComunidad(_validacion!),
              if (g.error != null) AvisoComunidad(g.error!),
              FilledButton.icon(
                key: const Key('guardar_aviso'),
                onPressed: ocupado ? null : _guardar,
                icon: const Icon(Icons.check),
                label: Text(
                  ocupado
                      ? 'Confirmando…'
                      : widget.aviso == null
                      ? 'Publicar aviso'
                      : 'Guardar cambios',
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
