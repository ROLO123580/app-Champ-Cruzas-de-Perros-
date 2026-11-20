# NanoApps, NanoFunciones y NanoActividades

La presentacion, la coordinacion de acciones y el acceso al repositorio quedan
separados. Se conservan los datos, las reglas de Firestore y los modulos anteriores.

```text
App Champ
└── MicroApp AppComunidadSocial
    ├── NanoApp AppComunidad
    │   └── NanoFuncion GestionarComunidad
    │       ├── NanoActividad ConsultarComunidad
    │       └── NanoActividad PublicarMuro
    ├── NanoApp AppEventos + vista FormularioEvento
    │   └── NanoFuncion GestionarEventos
    │       ├── NanoActividad ConsultarEvento
    │       ├── NanoActividad CrearEvento
    │       ├── NanoActividad InscribirEvento
    │       └── NanoActividad CancelarEvento
    └── NanoApp AppChatEventos
        └── NanoFuncion GestionarChatEventos
            ├── NanoActividad ConsultarMensajes
            ├── NanoActividad EnviarMensajeEvento
            └── Reutiliza ConsultarEvento
```

Las NanoActividades delegan la persistencia en `RepositorioComunidad`; su
implementacion Firestore es la que usa el servicio remoto. Las NanoFunciones
mantienen estados independientes de carga/error/operacion. `OperacionComunidad`
comparte solo el comportamiento de esas operaciones, sin mezclar su estado.
La consulta del evento se reutiliza para comprobar el acceso al grupo.

`GestionarComunidad` conserva los controladores durante la sesion y los destruye
al salir. Las NanoApps no poseen ni destruyen controladores inyectados. Paseos
reutiliza el catalogo de eventos con tipo paseo, sin duplicar reservas o inscripciones.

Rutas:

- `lib/microapps/comunidad_social/app_comunidad_social.dart`.
- `lib/nanoapps/comunidad/app_comunidad.dart`.
- `lib/nanoapps/eventos/app_eventos.dart`.
- `lib/nanoapps/eventos/vistas/formulario_evento.dart`.
- `lib/nanoapps/chat_eventos/app_chat_eventos.dart`.
- Cada modulo contiene `nanofunciones/<funcion>/nanoactividades/<actividad>/`.
- Componentes visuales compartidos: `lib/ui/componentes_comunidad.dart`.

Se retiran los archivos de las antiguas vistas de Comunidad y la actividad
generica PersistirComunidad; no se dejan copias funcionales en las rutas anteriores.

Validar todo:

```bash
bash tool/validar_champ.sh
```

En PowerShell:

```powershell
.\tool\validar_champ.ps1
```

Los scripts ejecutan dependencias, analisis, pruebas y compilacion web. No publican
en Firebase. La activacion remota se explica en `comunidad_eventos.md`.
