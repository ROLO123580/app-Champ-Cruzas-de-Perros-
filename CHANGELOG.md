# Historial de Champ

## 2026-10-31 · Perdidos y encontrados

- Listado con filtros y busqueda, alta/edicion, foto compartida, ficha, contacto
  mediante chat privado y cierre del caso por el autor con nota.
- AppRescateCanino compone la NanoApp, GestionarAvisos y cuatro NanoActividades.
  Repositorio Firestore con transacciones; sin migracion ni cambios en SQLite.
- Chip informado y terminacion opcional de cuatro digitos, sin publicar el numero
  completo ni simular rastreo GPS. Validacion cliente y reglas de servidor.
- 96 pruebas Flutter aprobadas, ocho nuevas, analisis sin incidencias, compilacion
  web correcta y capturas. Emulador: 21 rechazos de permisos; regresion de eventos
  y chats privados conservada. No se despliega en Firebase real automaticamente.

## 2026-10-31 · Separacion de NanoApps y scripts de entrega

- Se separan AppComunidad, AppEventos y AppChatEventos, sus tres NanoFunciones
  y ocho NanoActividades. Las pantallas dejan de acceder al repositorio directamente.
- Se comparte solo el comportamiento de operaciones; el estado y los errores de
  muro, eventos y chat quedan en sus respectivos controladores.
- Se trasladan formulario, detalle, chat y componentes a sus rutas definitivas y
  se retira PersistirComunidad. Se actualizan navegacion y pruebas existentes.
- Se entregan scripts de validacion para PowerShell y Bash y actualizador con
  comprobacion de hashes, deteccion de conflictos y respaldo previo del codigo.
- Analisis sin incidencias y 88 pruebas Flutter aprobadas tras reorganizar.
  No cambia el esquema ni las reglas de Firebase; no se modifica la base personal.

## 2026-10-31 · Muro, eventos en parques y chat de participantes

- Comunidad reemplaza el titulo provisional por muro de texto, tarjetas de
  encuentros, filtros por actividad/zona y seleccion Mis eventos.
- Se agregan formulario de evento, detalle, inscripcion/cancelacion por cupos y
  chat grupal de participantes. Paseos reutiliza eventos de tipo paseo; Chat
  conserva los privados y agrega la pestana Eventos y paseos.
- Las NanoApps delegan en GestionarComunidad, PersistirComunidad y un contrato
  de repositorio. Firestore permite compartir contenido entre equipos sin tocar
  SQLite ni datos locales. Nuevas reglas limitan los cambios de membresia al
  propio usuario y revocan acceso al chat al salir del evento.
- Transacciones evitan sobrecupos. Los formularios conservan texto al fallar y
  solo anuncian exito despues de confirmacion. Los grupos finalizados o cancelados
  quedan disponibles para lectura a sus miembros.
- Validacion: analisis sin incidencias, 88 pruebas Flutter aprobadas (6 nuevas),
  capturas de las cuatro pantallas y prueba a 320 px con texto ampliado. Compilacion
  web correcta. Emulador real de Firestore: carrera por el ultimo cupo, intercambio
  y revocacion, 17 rechazos de permisos; chat privado anterior conserva sus 10
  rechazos de seguridad e intercambio entre dos cuentas simuladas.
- No se desplegaron reglas ni se crearon datos de produccion. Se requiere activar
  las reglas actualizadas en el Firebase propio y verificar dos cuentas reales.
  Fotos remotas, comentarios, moderacion, edicion de eventos, paseadores de pago
  y avisos de perros perdidos quedan fuera de este bloque.
- Activacion, rutas, pruebas y limites: [docs/comunidad_eventos.md](docs/comunidad_eventos.md).

## 2026-10-29 · Inicio y Mis perros funcionales

- Inicio reemplaza el título provisional por un resumen del perfil y actividad
  local, con accesos a Mis perros, Cruces, Chat y Configuración. Es la pantalla
  inicial después del acceso; los datos del catálogo demo se identifican.
- Mis perros permite crear y editar la ficha y foto existentes con las mismas
  validaciones y persistencia de Cruces. Se conserva la identidad del perfil,
  sus decisiones y matches. Se mantiene un perfil propio por instalación.
- El shell comparte GestionarCruces mediante AppComunidadCanina; las NanoApps
  no crean otro almacenamiento ni destruyen el controlador inyectado. La barra
  superior indica el módulo actual y el menú usa iconos por sección.
- Se actualizan README y arquitectura, incluido el inicio web con el archivo
  Firebase externo mediante tool/iniciar_champ_web.sh.
- Validación en Ubuntu/WSL, con datos aislados: flutter analyze sin incidencias,
  82 pruebas Flutter aprobadas y flutter build web correcto. Siete pruebas
  nuevas cubren creación/edición/restauración, historial compartido, navegación,
  carga/error/reintento y presentación a 320 px con texto ampliado.
- Esta entrega no desarrolla Paseos, Perdidos y encontrados ni Comunidad.
  No incluye prueba de ingreso real, chat entre cuentas reales ni Android.

## 2026-10-21 · Chat entre cuentas sobre Firebase

- Revisión previa de instrucciones y documentación del repositorio, acceso y
  persistencia. No hay AGENTS.md en el proyecto/padres ni metadatos Git utilizables.
- Se integra Cloud Firestore 7.0.0 con la identidad del login existente. Se
  conserva NanoApp → NanoFunción → NanoActividad → contrato/repositorio.
- Chat combina historial local rotulado con conversaciones privadas entre dos
  UIDs, ID estable por par, lista y mensajes en tiempo real, vista previa,
  burbujas por remitente, envío atómico, estados pendientes y reintento.
  Dispose cancela escuchas; los eventos de suscripciones anteriores se ignoran.
- Se conserva SQLite, importación, fotos locales y el recorrido match → chat.
  El historial anterior no se sube ni se asigna automáticamente a una cuenta.
- Se añaden reglas por participante y un script de integración con Emulator
  Suite. No se crean registros ni se despliega en Firebase real.
- Validación: 75 pruebas Flutter aprobadas, análisis de `lib test tool` sin
  incidencias y compilación web correcta. Emulador Firestore: dos cuentas,
  recepción en tiempo real, creación concurrente/reapertura y diez rechazos de
  seguridad comprobados. Las pruebas Flutter del canal remoto usan dobles;
  el script JS usa las reglas reales en el emulador.
- Se actualizan dos pruebas existentes de Membership/Carro: esperan a que
  termine el desplazamiento, buscan elementos de listas perezosas mediante
  scroll y verifican el título actual «Membresía …». No cambia ese módulo.
- Activación y límites: [docs/chat.md](docs/chat.md). Faltan configuración real,
  base Firestore, despliegue de reglas y prueba con dos cuentas reales.
  Texto remoto y últimos 100 mensajes; fotos remotas y paginación pendientes.

## 2026-10-20 · Widget Ingresar con Google

- Se extrae `lib/nanoapps/login/widgets/boton_ingresar_google.dart`: botón
  reutilizable blanco con borde, logotipo oficial local, altura mínima de 48,
  ancho adaptable, indicador de carga y semántica accesible. El asset original
  está en `assets/login/google_g.png`, con procedencia en `FUENTES.md`.
- Login mantiene visible el botón al restaurar la sesión. Durante una operación
  deshabilita nuevas pulsaciones; con Firebase disponible llama a la NanoFunción
  de sesión existente. Sin configuración, permite consultar el ajuste en un
  diálogo sin llamar al proveedor ni crear una sesión. El detalle técnico deja
  de ocupar la tarjeta principal.
- Se conserva la jerarquía RH+IA, los servicios de autenticación, la API y
  SQLite. No se añade una dependencia de widgets ni se modifica Fénix.
- Validación: `flutter analyze --no-pub` sin incidencias y
  `flutter test --no-pub` con **60 pruebas aprobadas**. Dos regresiones nuevas
  comprueban carga/bloqueo de pulsaciones y apertura/cierre del diálogo sin
  solicitudes de autenticación al faltar configuración.
- Chrome debug de escritorio real: logotipo y botón visibles, pulsación abre el detalle
  pendiente y Entendido lo cierra. Sin excepciones JS ni solicitudes fallidas
  observadas. El script inicial de Google Sign-In se carga por el plugin; el
  clic no inicia OAuth sin configuración. Evidencia `build/boton_google_chrome*`.
  La emulación móvil mostró el widget sin desbordamientos, pero produjo una
  aserción debug de insets en el motor Flutter; no se presenta como Android
  validado. Chrome quedó abierto en escritorio con el diálogo cerrado.

## 2026-10-20 · Login Google, Membership y Carro

- Se inspeccionó Fénix Fitness en `C:/flutter_projects/fenix_fitness`, incluida
  la ruta `lib` indicada, dependencias y ocho DOCX (cuatro originales y copias).
  Se reutilizaron las rutas y estructura visual de `nanoapps/login/app_login.dart`,
  `nanoapps/membership/app_membership.dart` y la navegación. Esa copia no contiene
  autenticación funcional, Carro ni planes/precios/beneficios. Se conservó intacta:
  17 SHA-256 verificados en `docs/reutilizacion_fenix.md`.
- Nuevas MicroApps Acceso y Comercio; NanoFunciones/NanoActividades de Login,
  Membership y Carro según RH+IA. `main.dart` sigue iniciando la app y
  `app_champ.dart` conecta servicios y módulos existentes. El gate de sesión
  reemplaza el callback simulado, evita apilar Login/shell y limpia rutas
  secundarias cuando cambia la identidad. El menú muestra cuenta, Membership,
  Carro y Cerrar sesión, conservando los índices anteriores.
- Servicio real Firebase: `firebase_core 5.0.0`, `firebase_auth 7.0.0`,
  `google_sign_in 7.2.0`. Chrome usa popup Firebase; Android usa singleton
  `initialize/authenticate` e ID token. Restauración inicial, inicialización
  compartida, nombre/foto disponibles, cierre, cancelación/error/reintento,
  bloqueo de solicitudes repetidas y cancelación de suscripción al destruir.
  No se almacenan credenciales en `champ.db`.
- Configuración exclusiva de Champ mediante defines y recursos Android.
  Google Services 4.5.0 se aplica condicionalmente al JSON real, validando
  `com.example.champ`, proyecto y appId. INTERNET y HTTP local delimitado para
  la API. `tool/verificar_firebase.dart` y `docs/firebase_configuracion.md`
  especifican archivos, dominios, OAuth y huellas debug observadas. No hay
  proyecto/registro Firebase de Champ verificable; Login informa esa ausencia.
- Membership consulta catálogo por la API y conserva condiciones explícitas sin
  inventar valores. Selección y Carro comparten `membership/estado`; estados
  seleccionado y pendiente separados, sin activar membresías ni simular pagos.
  Reentrar recarga el catálogo; pasar a pendiente comprueba disponibilidad y
  condiciones de la vista, selección persistida y catálogo. Se rechazan cambios
  hechos en otra ventana. Falta el catálogo comercial real y la autoridad de pagos.
- Se conserva la API como único acceso productivo al contenido, la misma base
  por aplicación y esquema 3. Se reutiliza la tabla documental, sin migraciones
  ni borrado al cerrar sesión. Descubrimiento, fotos, likes, matches y Chat siguen
  intactos; Google no traslada esos datos a la nube.
- Validación final Ubuntu/WSL: `flutter analyze --no-pub` sin incidencias,
  `flutter test --no-pub` con **58 pruebas aprobadas** y
  `flutter build web --no-pub` correcto. Incluye nueve pruebas Login con doble,
  once Membership/Carro (HTTP real/reinicio incluido), tres de integración del
  gate/navegación/SQLite y las 35 pruebas previas, incluido match → chat.
- `flutter build apk --debug --no-pub` generó
  `build/app/outputs/flutter-apk/app-debug.apk`. La ausencia del JSON mantiene
  Login pendiente; compilar no verifica Google. Avisos no bloqueantes del entorno
  sobre KGP en plugins Firebase y formatos XML SDK quedan documentados.
- Chrome real mostró Login de la nueva compilación a 1280 × 900 y 390 × 844,
  sin desbordamientos, con botón
  Google deshabilitado y configuración faltante identificada. Sin excepciones JS
  ni solicitudes fallidas durante la observación CDP. Captura e informe locales
  en `build/validacion_chrome.png`, `build/validacion_chrome_movil.png` y sus `.json`.
  El tamaño móvil no equivale a Android nativo. Consulta de consola por API confirmó
  la misma base persistente de WSL y esquema 3.
- No se probó un ingreso real de Google, sus credenciales restauradas ni un
  cierre contra el proveedor: faltan configuración y acceso a consola. No hay
  Android conectado/emulador para prueba visual. Los resultados con dobles no
  se presentan como autenticación real. Rutas y límites en `docs/login.md`,
  `docs/membership.md` y `ARQUITECTURA.md`.

## 2026-10-20 · Todo acceso mediante API local

- `crearServicioBase()` utiliza `HttpLocal` en Chrome y en escritorio. La API
  concentra CRUD, imágenes, likes, matches, Chat y respaldos sobre los mismos
  archivos persistentes. Se conservan la jerarquía RH+IA y el esquema SQLite 3.
- `tool/champ_db.dart` pasa a ser cliente de la API y acepta `CHAMP_API_URL` del
  entorno. `CHAMP_DATA_DIR` pertenece al servidor y no abre otra base desde la
  consola. `tool/champ_api.dart` sigue siendo el proceso que accede a SQLite.
- Se habilita `com.apple.security.network.client` en los entitlements macOS de
  Debug y Release. Se actualizan las instrucciones de inicio: la API debe estar
  disponible para todos los clientes, incluidos los destinos de escritorio.
- Se añade `test/acceso_api_test.dart` con dos casos de integración HTTP real:
  datos/fotos/likes/matches/Chat/respaldos y recuperación al reiniciar, más consola
  en procesos separados consultando la misma base sin crear otra carpeta.
- Validación en Ubuntu/WSL: `flutter analyze --no-pub` sin incidencias,
  `flutter test --no-pub` con **35 pruebas aprobadas** y
  `flutter build web --no-pub` correcto. La consola consultó mediante API la base
  persistente `/home/rolo/.local/share/RHIA/Champ/champ.db` con esquema 3.
- La lectura de preferencias antiguas se conserva solo para importarlas; los
  archivos seleccionados y las fotos de semilla se envían al servidor. La
  comprobación visual y los empaquetados de escritorio siguen pendientes.

## 2026-10-20 · Revisión de conservación y reinicio entre procesos

- Se conserva la base SQLite y la jerarquía RH+IA existente. El catálogo de
  navegación pasa de `lib/core/catalogo_pantallas.dart` a
  `lib/navegacion/catalogo_pantallas.dart`; se eliminan las instancias alternativas
  de Cruces, Chat y Configuración fuera de sus MicroApps.
- Editar una ficha ya no reescribe decisiones desde un estado anterior. Revisar
  descartados actúa sobre las filas actuales de SQLite y vuelve a cargar el estado.
  Los intereses demo no sustituyen decisiones entrantes ya registradas.
- Chat guarda solo identidades pendientes y divide historiales grandes en lotes
  de hasta 100 registros con objetivo de 512 KiB. Conserva los lotes confirmados
  y permite reintentar fallos o confirmaciones perdidas sin duplicar mensajes.
- Los nuevos identificadores usan 128 bits aleatorios; la NanoFunción asigna
  identidades de perfiles y la pantalla deja de generarlas con el reloj.
- Se añaden `test/reinicio_proceso_test.dart`, `test/soporte/proceso_datos.dart`,
  `test/cruces_concurrencia_test.dart` y `test/chat_incremental_test.dart`.
- Resultado en Ubuntu/WSL: `flutter analyze --no-pub` sin incidencias,
  `flutter test --no-pub` con **33 pruebas aprobadas** y
  `flutter build web --no-pub` correcto. Dos procesos Dart independientes
  recuperaron ficha, foto PNG y likes, conservando un único match tras reintentar.
  También se comprobaron decisiones entre conexiones e importación de más de
  16 MiB sin reenviar el historial completo.
- Pendiente manual: recorrido visual en Chrome con la API y validación de los
  empaquetados de escritorio. Las pruebas de interfaz con adaptadores de prueba
  se distinguen de las pruebas SQLite/HTTP reales en `ARQUITECTURA.md`.

## 2026-10-20 · SQLite local y arquitectura RH+IA

- Se conserva `main.dart` como inicio y `app_champ.dart` como orquestador de
  navegación y dependencias. Se incorporan las MicroApps Comunidad Canina y Datos
  Locales, conservando las NanoApps de Cruces, Chat y Configuración.
- Se reorganizan NanoFunciones en `nanofunciones/<funcion>/` y NanoActividades
  en `nanoactividades/<actividad>/` dentro de cada función. Modelos, contratos,
  repositorios y servicios se mueven a `lib/core/` sin duplicar implementaciones.
- Se incorpora `champ.db` en almacenamiento persistente por aplicación. El
  escritorio utiliza SQLite directamente y Chrome una API de bucle local.
- Se incorporan CRUD reutilizable, lotes transaccionales, fotos externas a la
  base deduplicadas por SHA-256, catálogo/razas iniciales idempotentes y
  persistencia para perfiles, likes, matches, conversaciones y mensajes.
- Se añade importación de preferencias anteriores, conservando los datos de
  origen y las identidades de conversaciones. La importación depende de que
  esas preferencias estén disponibles en el entorno/origen actual.
- Se añaden migraciones 1–3 y respaldo antes de actualizar una base existente.
  La versión 3 corrige el caso detectado en pruebas donde el UPSERT de un like
  podía volver a insertar un match desde un trigger. La pareja ordenada tiene
  una clave única y los reintentos se verifican con dos conexiones.
- Se añaden respaldos de SQLite e imágenes con `VACUUM INTO`, `integrity_check`,
  manifiesto de hashes y publicación únicamente después de verificar la copia.
  Configuración permite crear un respaldo y consultar sus rutas reales.
- Se añaden `tool/champ_api.dart` y `tool/champ_db.dart`, y se crea
  `ARQUITECTURA.md` (ambos documentos de arquitectura/historial faltaban).
- Se empaquetan las cuatro fotos del catálogo demo y se copian a almacenamiento
  persistente. Se conservan las fuentes en `assets/catalogo/FUENTES.md`; las
  tarjetas usan bytes locales y dejan de depender de URLs externas.
- La importación no se da por completada si un origen no tiene preferencias.
  Al encontrarlas después, acumula fichas y mensajes sin sustituir datos nuevos.
- Validación en Ubuntu/WSL: `flutter analyze --no-pub` sin incidencias,
  `flutter test --no-pub` con 24 pruebas aprobadas y `flutter build web --no-pub`
  correcto. Se verificaron reapertura de datos/fotos, matches únicos, rollback,
  importación, migración, reapertura del respaldo y reinicio real de la API.
- Se dejó iniciada la API de desarrollo en `127.0.0.1:8787`; `/health` confirmó
  el esquema 3 y la base persistente de WSL se creó en
  `/home/rolo/.local/share/RHIA/Champ/champ.db`.
- Pendiente manual: flujo visual en Chrome con API, selección de fotos en los
  sistemas destino y empaquetados de escritorio. No se ha añadido sincronización
  cloud ni entre equipos.
