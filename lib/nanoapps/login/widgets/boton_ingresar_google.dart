import 'package:flutter/material.dart';

/// Presentación del acceso a Google. La NanoFunción decide qué acción ejecutar.
class BotonIngresarGoogle extends StatelessWidget {
  const BotonIngresarGoogle({
    super.key,
    required this.onPressed,
    this.cargando = false,
    this.texto = 'Ingresar con Google',
  });

  final VoidCallback? onPressed;
  final bool cargando;
  final String texto;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SizedBox(
      width: double.infinity,
      child: Semantics(
        liveRegion: cargando,
        child: OutlinedButton(
          key: const Key('boton_ingresar_google'),
          onPressed: cargando ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            visualDensity: VisualDensity.standard,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F1F1F),
            disabledForegroundColor: const Color(0xFF747775),
            side: const BorderSide(color: Color(0xFF747775)),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/login/google_g.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cargando ? 'Conectando con Google…' : texto,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                dimension: 20,
                child: cargando
                    ? const ExcludeSemantics(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF747775),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
