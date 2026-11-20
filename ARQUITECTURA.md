# Champ · RH+IA

Perdidos y encontrados utiliza AppRescateCanino → AppPerdidosEncontrados y sus
vistas → GestionarAvisos → ConsultarAvisos/GuardarAviso/ResolverAviso/SeleccionarFotoAviso
→ RepositorioAvisosPerros. El contacto reutiliza GestionarChat y sus actividades.
Las pantallas no abren la base ni consultan Firebase directamente. Detalles en
[perdidos_encontrados.md](docs/perdidos_encontrados.md).

Comunidad, Eventos y ChatEventos tienen ahora NanoApps y NanoFunciones separadas,
con ocho NanoActividades especificas. Las pantallas no consultan repositorios
directamente. La actividad generica PersistirComunidad y sus vistas anteriores
se sustituyen por esa separacion; vease [estructura_comunidad.md](docs/estructura_comunidad.md).

La etapa de Comunidad agrega `microapps/comunidad_social`, las NanoApps Comunidad,
Eventos y ChatEventos con sus NanoFunciones y NanoActividades. El repositorio inyectable
`RepositorioComunidadFirestore` comparte los eventos entre cuentas; SQLite
conserva el alcance local anterior. No se crean tablas locales ni se migran
datos. El shell mantiene el controlador durante la sesion y lo destruye al
cambiar de cuenta. Detalles en [Comunidad y eventos](docs/comunidad_eventos.md).

Actualizado: 2026-10-29. Inicio y Mis perros comparten el perfil y estado de Cruces.

Inicio es la entrada del shell después del login. El shell compone Inicio,
Mis perros, Cruces y Chat mediante `AppComunidadCanina`; mantiene una sola
instancia de `GestionarCruces`. Las NanoApps Inicio y Mis perros reciben ese
controlador, observan sus cambios y no lo destruyen. Mis perros reutiliza
`EditarPerfilCruce`, sus validaciones y su persistencia. No hay cambios de
esquema, borrado de perfiles ni una segunda base de datos.
La API local conserva su alcance por aplicación: estas pantallas no publican
el perfil en Firebase ni añaden separación de datos por cuenta.

La extensión de chat entre cuentas añade `CanalChatUsuarios`,
`RepositorioChatFirestore` y `ChatUsuariosActividad` a la jerarquía existente.
El shell inyecta la identidad de sesión y conserva AlmacenChat/SQLite para el
historial local y matches demo. El modelo admite participantes y remitente;
las escuchas remotas se cancelan al cambiar de chat o destruir el controlador.
Véase [docs/chat.md](docs/chat.md) para el esquema, reglas, activación y límites.
Las descripciones históricas de Firebase como identidad exclusivamente se
refieren a la etapa anterior: ahora también aloja el chat nuevo entre cuentas.

## Jerarquía y responsabilidades

`App → MicroApp → NanoApp → NanoFunción → NanoActividad → repositorio/servicio core`

- `lib/main.dart`: inicia `ChampApp`. No contiene reglas de negocio.
- `lib/app_champ.dart`: orquestador principal. Inyecta `ServiciosChamp`, conecta
  navegación, sesión, controladores y el acceso del match a su conversación.
  `ChampEntrada` observa la sesión y muestra Login o un único `ChampShell`.
- `lib/navegacion/catalogo_pantallas.dart`: títulos e índices del menú y las
  pantallas provisionales. El catálogo se movió fuera de `core`; los módulos
  funcionales se componen mediante sus MicroApps en el orquestador. Carro se añade
  al final del menú para conservar los índices previos.
- `lib/microapps/acceso/app_acceso.dart`: conecta la NanoApp Login con su sesión.
- `lib/microapps/comercio/app_comercio.dart`: conecta Membership y Carro con el
  mismo repositorio local.
- `lib/microapps/comunidad_canina/app_comunidad_canina.dart`: agrupa Cruces y Chat.
- `lib/microapps/datos_locales/app_datos_locales.dart`: conecta la administración
  de los datos con la NanoApp de Configuración.
- `lib/microapps/datos_locales/api/servidor_local.dart`: API HTTP local, sin Flutter
  ni cuentas. `tool/champ_api.dart` es su punto de entrada para todos los clientes.
- `lib/nanoapps/cruces/app_cruces.dart`, `chat/app_chat.dart` y
  `configuracion/app_configuracion.dart`: presentación e interacción.
- `lib/nanoapps/cruces/widgets/editar_perfil.dart`: formulario de perfil; delega
  acciones en la NanoFunción y no abre bases ni archivos.
- `lib/nanoapps/login/widgets/boton_ingresar_google.dart`: componente de
  presentación reutilizable con logotipo Google local, carga y accesibilidad.
  La NanoApp Login conecta su pulsación con la NanoFunción de sesión. Si falta
  configuración, ofrece el detalle en un diálogo sin abrir una sesión simulada.

Las rutas de funciones y actividades son:

```text
lib/nanoapps/
  chat/nanofunciones/gestionar_chat/
    gestionar_chat.dart
    nanoactividades/
      persistir_chat/persistir_chat.dart
      seleccionar_foto/seleccionar_foto.dart
  cruces/nanofunciones/gestionar_cruces/
    gestionar_cruces.dart
    nanoactividades/
      persistir_cruces/persistir_cruces.dart
      seleccionar_foto/seleccionar_foto.dart
  configuracion/nanofunciones/gestionar_base_local/
    gestionar_base_local.dart
    nanoactividades/administrar_base/administrar_base.dart
  login/nanofunciones/gestionar_sesion/
    gestionar_sesion.dart
    nanoactividades/autenticar_google/autenticar_google.dart
  membership/nanofunciones/gestionar_membership/
    gestionar_membership.dart
    nanoactividades/persistir_membership/persistir_membership.dart
  carro/nanofunciones/gestionar_carro/
    gestionar_carro.dart
    nanoactividades/persistir_carro/persistir_carro.dart
```

Las NanoFunciones validan y coordinan los comportamientos. Las NanoActividades
delegan tareas concretas en los contratos y servicios de `core`. Las interfaces
de repositorio permiten seguir probando el flujo anterior sin usar la base real.

## Core y migración de rutas

Se movieron los archivos existentes y se actualizaron sus importaciones; no se
dejaron copias funcionales en las carpetas antiguas.

| Responsabilidad | Ruta actual |
| --- | --- |
| Modelos de perros y estado de cruces | `lib/core/modelos/cruces.dart` |
| Conversaciones y mensajes | `lib/core/modelos/chat.dart` |
| Contratos de repositorio | `lib/core/repositorios/contratos.dart` |
| Repositorios locales | `lib/core/repositorios/cruces_local.dart`, `chat_local.dart` |
| Catálogo inicial y razas | `lib/core/catalogos/perfiles_demo.dart`, `repositorios/datos_iniciales.dart` |
| Fotos y referencias persistentes | `lib/core/repositorios/fotos_locales.dart` |
| Lectura del almacenamiento anterior | `lib/core/repositorios/legado/preferencias_*.dart` |
| Conexiones y dependencias | `lib/core/servicios/servicios_champ.dart` |
| Selección y validación de fotos | `lib/core/servicios/seleccionar_foto.dart` |
| CRUD, lotes, imágenes y respaldos | `lib/core/persistencia/base_local.dart` |
| SQLite y migraciones | `lib/core/persistencia/sqlite_local.dart` |
| Cliente API | `lib/core/persistencia/http_local.dart` |
| Creación del cliente API para todos los destinos | `lib/core/persistencia/crear_servicio.dart` |
| Datos públicos de sesión y errores de acceso | `lib/core/modelos/sesion.dart` |
| Contrato y SDK de autenticación | `lib/core/servicios/autenticacion.dart`, `autenticacion_firebase.dart` |
| Opciones Firebase de Champ por plataforma | `lib/core/servicios/configuracion_firebase.dart` |
| Planes, precios explícitos e intención de contratación | `lib/core/modelos/membership.dart` |
| Catálogo, selección y Carro mediante la API local | `lib/core/repositorios/membership_local.dart` |

## Sesión y comercio

Se revisaron `C:/flutter_projects/fenix_fitness/lib`, sus dependencias y documentos.
Se conservan las rutas de sus NanoApps Login y Membership y su estructura de
navegación. Esa copia contiene presentación provisional: no incluye autenticación,
Carro, planes, precios ni beneficios reales. Fénix no se modifica; la inspección
y los hashes verificados están en [docs/reutilizacion_fenix.md](docs/reutilizacion_fenix.md).

El servicio usa las versiones resueltas `firebase_core 5.0.0`, `firebase_auth 7.0.0`
y `google_sign_in 7.2.0`. Chrome abre Google con Firebase `signInWithPopup` desde
el botón; Android usa `GoogleSignIn.instance.initialize/authenticate` y un ID token
para Firebase. La inicialización exitosa de Firebase se comparte y no se repite
desde pantallas. El servicio espera la restauración inicial y el controlador
mantiene una suscripción que cancela al destruirse. Las solicitudes concurrentes
de entrada/salida se bloquean; cancelación, error y reintento se presentan en UI.

`app_champ.dart` conserva un único navegador y decide la entrada por estado de
sesión, sin apilar pantallas al entrar/salir. Un cambio de UID descarta las rutas
secundarias y crea un shell nuevo. La barra lateral muestra nombre/foto disponibles
y ofrece Cerrar sesión. El cierre solo utiliza el SDK: no borra contenido local.
Tokens y credenciales quedan bajo la gestión de Firebase/Google y no se escriben
en `champ.db`. Firebase se incorpora exclusivamente para identidad; la API local
de contenido conserva su alcance de aplicación local, sin autorización multiusuario.

Las opciones web se reciben mediante defines; Android puede usar sus recursos
nativos desde `android/app/google-services.json`. Gradle valida que ese archivo
registre `com.example.champ` y coincida con los defines Android si se suministran.
El plugin Google Services se aplica cuando existe el archivo real. Sin configuración
válida, Login informa el ajuste pendiente y no permite una entrada simulada.
Los registros, proveedor, dominios, huellas y comandos están documentados en
[docs/firebase_configuracion.md](docs/firebase_configuracion.md); el verificador local
es `tool/verificar_firebase.dart`. No se ha verificado acceso a las consolas externas.

Membership consulta `planes_membership` por la misma API. El catálogo inicial
permanece vacío porque el origen no aporta condiciones reales. Los precios se
guardan como enteros en unidades menores, con moneda, decimales y período explícitos.
Las pruebas tienen planes identificados como fixtures, que no se insertan en la
base habitual. La UI muestra planes, beneficios, precio y selección cuando el
catálogo real esté publicado; permite revisar Carro y quitar la selección.

`membership/estado` conserva en un único documento versionado el plan seleccionado
y su intención de contratación: sin selección, seleccionado o pendiente. La
selección y Carro comparten ese documento. No existe un servicio de pagos ni una
autoridad que acredite membresías activas; la UI lo indica y `membresiaActiva` es
falso. Cambiar un documento local o iniciar sesión nunca concede permisos pagados.
Para dejar pendiente se comprueba que el plan siga disponible y que sus condiciones
coincidan con las seleccionadas. Detalles en [docs/membership.md](docs/membership.md).

Estas colecciones utilizan la tabla documental existente: se mantiene esquema 3,
sin nuevas tablas ni migraciones destructivas. Son datos por aplicación, compartidos
entre sesiones; cerrar sesión no borra selección, fichas, catálogos, fotos ni matches.

## Una base por aplicación

No hay particiones por usuario, sesión, cuenta o plan. La raíz predeterminada es:

| Entorno | Carpeta de Champ |
| --- | --- |
| Ubuntu/Linux, incluida la API en WSL | `${XDG_DATA_HOME:-$HOME/.local/share}/RHIA/Champ` |
| Windows | `%LOCALAPPDATA%\RHIA\Champ` |
| macOS | `$HOME/Library/Application Support/RHIA/Champ` |

Dentro de esa raíz se conservan `champ.db`, `imagenes/` y `respaldos/`. SQLite
puede crear `champ.db-wal` y `champ.db-shm` mientras está en uso. La ubicación no
depende del directorio de código, de `build/` ni del almacenamiento del navegador.
`CHAMP_DATA_DIR` permite elegir otra **ruta absoluta y persistente** al iniciar
la API. La app y la consola no utilizan esa variable para abrir archivos.
Las pruebas usan explícitamente carpetas temporales
aisladas; la aplicación normal no utiliza esa ruta de pruebas.

En WSL la raíz predeterminada del servidor es la de Ubuntu, no la de Windows.
Chrome, escritorio y consola comparten los datos al apuntar a la misma API.
La ruta persistente corresponde al sistema del servidor; no se mezclan
automáticamente bases situadas en carpetas diferentes.

## Acceso local desde escritorio y Chrome

Todos los clientes usan `HttpLocal`, incluidos los destinos de escritorio y
`tool/champ_db.dart`. `crearServicioBase()` no selecciona SQLite según la plataforma.
El flujo es App → MicroApp → NanoApp → NanoFunción → NanoActividad → repositorio
core → API local → SQLite y carpeta de imágenes. El servidor centraliza la lectura,
escritura, eliminación lógica de registros, fotos, likes, matches y respaldos.

Solo la API utiliza `sqlite3` mediante FFI. En Linux se carga el runtime
`libsqlite3.so.0`; si falta, Ubuntu requiere el paquete `libsqlite3-0`. En Windows
y macOS se usa la biblioteca SQLite del sistema compatible con el paquete.
No se requiere un servicio cloud ni una suscripción.

Chrome y escritorio utilizan el mismo cliente HTTP. La API escucha en
`127.0.0.1:8787` y es el único proceso operativo que abre el archivo.
Acepta orígenes de bucle local, valida Host y JSON, limita solicitudes a 16 MB y
no expone SQL arbitrario ni rutas de archivos proporcionadas por el navegador.
Las fotos se transportan en base64 y se escriben como archivos en el servidor;
el base64 no se conserva en las filas SQLite. No hay fallback silencioso a memoria
o preferencias si la API no está disponible.

La API debe estar iniciada antes de utilizar la aplicación o la consola. La app
configura su URL con `--dart-define=CHAMP_API_URL=...`; la consola acepta la variable
de entorno `CHAMP_API_URL`. Si no se configura, ambas usan `http://127.0.0.1:8787`.
macOS tiene permiso `com.apple.security.network.client` en Debug y Release.
El selector local de archivos y las fotos de semilla son entradas que se envían
a la API, no un acceso directo a la persistencia. La lectura de preferencias
antiguas permanece exclusivamente para importarlas al servidor y conservarlas.

## Esquema, conservación y concurrencia

Se utiliza `PRAGMA user_version`, transacciones `BEGIN IMMEDIATE`, espera de
bloqueos de cinco segundos, WAL y `synchronous=FULL`.

1. Versión 1: `documentos(coleccion,id,datos)` e `imagenes(referencia,ruta,tamano)`.
   El JSON estructurado contiene colecciones `perfiles`, `razas`, `catalogos`,
   `conversaciones`, `mensajes`, `ajustes` y `meta`. La clave de cada registro es
   compuesta por colección e identificador. No se guarda el estado entero como
   un único documento de preferencias.
2. Versión 2: `likes` y `matches`, más índice de intereses por destino.
3. Versión 3: triggers idempotentes para inserciones y actualizaciones de likes.
   Solo un interés recíproco crea el match. La pareja se ordena y tiene clave
   primaria `(perro_a,perro_b)`, evitando duplicados aunque lleguen reintentos
   desde distintas conexiones. Los matches históricos se conservan.

Se respalda antes de actualizar una base existente y se rechazan versiones
futuras. Cada paso vuelve a comprobar su versión dentro de la transacción.
Un fallo de un lote revierte todos sus cambios. El catálogo se inserta de manera
idempotente y no reemplaza fichas existentes.

Las conversaciones de matches mantienen el identificador previo para preservar
su historial. Mensajes y conversaciones se insertan por identidad; reabrir un
match no crea otra conversación. El perfil activo sigue siendo único en la UI;
la base permite acumular otras fichas y catálogos mediante el módulo CRUD.

Editar una ficha y volver a ver descartados utilizan operaciones específicas.
El guardado de perfil no vuelve a escribir el historial de decisiones; los
intereses demo solo se insertan cuando no existen. La revisión de descartados
elimina únicamente filas que siguen teniendo `decision='pasar'` dentro de una
transacción. Ambas acciones vuelven a leer el estado persistido para conservar
las decisiones más recientes de otra ventana.

El repositorio de Chat reconoce las identidades cargadas o ya confirmadas y
guarda solo registros pendientes. Serializa sus guardados y agrupa importaciones
en lotes de hasta 100 registros, con un objetivo de 512 KiB por lote (los mensajes
normales tienen hasta 4000 caracteres; una fila excepcional mayor ocupa su propio
lote). Cada lote se confirma antes de actualizar la caché de identidades. Si
falla una importación larga, los lotes confirmados permanecen y el reintento
continúa sin duplicarlos. Ya no se reenvía todo el historial en cada mensaje ni
se vuelve a guardar una foto antigua. La atomicidad corresponde a cada lote,
no a una importación completa de varios lotes.

Las identidades nuevas de fichas, mensajes y conversaciones independientes usan
128 bits aleatorios mediante `lib/core/servicios/identificadores.dart`, evitando
depender de relojes y contadores por pestaña. La NanoFunción asigna la identidad
del perfil; el formulario entrega los datos. Los identificadores previos y los
de conversaciones de matches se conservan.

## Imágenes y respaldos

Cada foto propia se guarda como `imagenes/<sha256>.img`, usando un archivo
intermedio y escritura con flush antes de registrar su referencia. Las fotos
son inmutables y se deduplican por contenido. Se conserva el límite existente
de selección de 1 MB y 20 megapíxeles; desaparece el límite anterior de 4 MB para
el historial. Las cuatro fotos ilustrativas del catálogo se empaquetan en
`assets/catalogo/`, con fuentes documentadas en `FUENTES.md`. Al inicializar la
app se copian a la carpeta persistente y se actualizan las referencias de los
perfiles. Las URLs originales se conservan solo como procedencia: las tarjetas
muestran bytes locales y no realizan solicitudes externas. El marcador
`fotos_catalogo_v1` hace la importación reanudable e idempotente.

`BaseLocal.respaldar()` crea una instantánea mediante `VACUUM INTO`, abre esa copia,
verifica `integrity_check`, copia las imágenes de su registro y comprueba sus
hashes. Escribe `manifest.json` con los SHA-256 de SQLite y de cada foto y solo
entonces publica la carpeta de respaldo. Un trabajo incompleto conserva el
nombre oculto `.incompleto` y no se informa como respaldo correcto. Las imágenes
no se eliminan al borrar un documento: pueden pertenecer a mensajes, referencias
o respaldos, y su conservación hace segura la copia mientras otra conexión escribe.

Configuración ofrece **Respaldar base y fotos** y muestra las rutas reales. La
herramienta `tool/champ_db.dart` es cliente de la misma API para consultar,
crear/actualizar, eliminar registros y respaldar. Para recuperar una instantánea,
detén la API y vuelve a iniciarla usando la carpeta completa del respaldo como
`CHAMP_DATA_DIR`; no copies solo el `.db` sobre una base abierta. Aún no hay una
interfaz gráfica de restauración ni limpieza de imágenes sin referencias.

No existen caducidades por tiempo o cuenta. La conservación depende del disco,
sus permisos y los respaldos; no protege frente a borrar la carpeta o perder el
equipo. Es recomendable copiar respaldos completos a otro dispositivo.

## Importación del trabajo anterior

Al cargar cada repositorio se importan `champ.cruces.v1` y `champ.chat.v1` desde
las preferencias disponibles en ese entorno. Las fotos se extraen a disco y los
marcadores de importación quedan en `meta`. El origen no se borra. Reintentar la
importación no duplica conversaciones, mensajes ni matches; un origen corrupto
no se marca como importado. Tampoco se marca una importación cuando no hay
preferencias en ese origen: otro origen con datos podrá importarlas después.
Se acumulan fichas y mensajes antiguos sin reemplazar la ficha activa o los
registros nuevos que ya existan en SQLite.

Las preferencias de Chrome dependen de su origen anterior (esquema, host y puerto).
Para importar datos antiguos hay que abrir la app en ese mismo origen. Después
de importar, el puerto de Flutter deja de determinar dónde están los datos.
Las preferencias de Windows tampoco son legibles automáticamente desde Ubuntu.

## Comprobaciones

Se ejecutaron en Ubuntu/WSL. Las pruebas de almacenamiento usan SQLite real y
HTTP local; la autenticación se sustituye explícitamente en pruebas automatizadas:

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: **60 pruebas aprobadas** después de incorporar el
  widget de Google y sus regresiones de interacción.
- `flutter build web --no-pub`: compilación correcta.
- Cierre y reapertura de SQLite: ficha, bytes de fotos, likes, match y chat.
- Dos procesos Dart separados: el primero escribe y termina; el segundo recupera
  ficha, PNG y likes desde disco y repite la reciprocidad conservando la misma fila
  de match, incluida su fecha (`test/reinicio_proceso_test.dart` y helper
  `test/soporte/proceso_datos.dart`).
- Likes recíprocos repetidos y en dos conexiones: un único match.
- Edición de ficha y revisión de descartados con otra conexión modificando
  decisiones: se conserva el estado más reciente (`test/cruces_concurrencia_test.dart`).
- Chat incremental: registros pendientes, importación superior a 16 MiB en lotes,
  fallo entre lotes, confirmación perdida y guardados simultáneos
  (`test/chat_incremental_test.dart`).
- CRUD y rollback de un lote inválido.
- Migración v1 → v3 conservando registros e imágenes y respaldando antes.
- Migración v2 → v3 conservando el match y permitiendo repetir el like.
- Fotos del catálogo importadas a disco una vez y recuperadas sin fuentes externas.
- Rechazo de referencias inexistentes y de respaldos con fotos dañadas.
- Copia bajo WAL: manifest verificado y reapertura de la instantánea con fotos.
- Importación de preferencias sin borrar el origen ni duplicar matches.
- Importación tardía desde otro origen sin sustituir datos nuevos.
- Reinicio de un servidor HTTP real: recuperación por cliente HTTP desde disco;
  rechazo de un origen web externo.
- `test/acceso_api_test.dart`: fábrica HTTP también en el entorno nativo, CRUD,
  imágenes, fichas, likes, matches únicos, descartados, Chat y respaldos mediante
  la API, conservando los datos después de reiniciar el servidor.
- Consola en procesos Dart con `CHAMP_API_URL`: consulta la misma base del servidor
  y no crea una base alternativa aunque `CHAMP_DATA_DIR` señale otra carpeta.
- Consola de desarrollo consultada por API: confirmó
  `/home/rolo/.local/share/RHIA/Champ/champ.db`, esquema 3.
- API de desarrollo iniciada en WSL: `/health` respondió
  `{"aplicacion":"Champ","version":3}`. Base real creada en
  `/home/rolo/.local/share/RHIA/Champ/champ.db`, con fotos en `imagenes/`.
- Pruebas de interfaz: crear perfil, deslizar, match → chat y reabrir mensajes.
- `test/login_test.dart`: once casos de restauración, entrada, cancelación,
  error/reintento, cierre, configuración, solicitudes duplicadas y liberación de
  suscripciones con `AutenticacionFalsa`, nunca utilizada en producción. Incluye
  estado de carga del botón y diálogo de configuración sin llamar al proveedor.
- `test/navegacion_acceso_test.dart`: tres casos de entrada/salida sin rutas
  duplicadas, cancelación/error recuperables y Membership → Carro con selección
  conservada al salir y reabrir SQLite. La identidad es falsa; la base es real y
  aislada. Se verifica que el cierre no elimina el contenido.
- `test/membership_test.dart` y `test/membership_api_test.dart`: once casos con
  planes fixture. Incluyen navegación, reentrada y recarga de catálogo, fallo y
  reintento, estados sin permisos, reinicio HTTP conservando catálogo/selección/
  pendiente/ficha/match y rechazo de condiciones cambiadas entre dos clientes.
- `flutter build apk --debug --no-pub`: APK Android compilado en WSL sin JSON
  Firebase, con Login pendiente de configuración. El SDK instaló plataforma 35 y
  CMake 3.22.1. La compilación avisó de plugins Firebase que aún aplican KGP y de
  versiones XML del SDK; no impidieron generar el APK.
- Verificador Firebase local: informa las cinco opciones web ausentes y
  `android/app/google-services.json` ausente. No se inventaron registros.
- Validación inicial de Login en Chrome, anterior al widget de Google:
  visible a 1280 × 900 y
  390 × 844, sin desbordamientos;
  botón Google deshabilitado y explicación de configuración pendiente. Inspección
  CDP sin excepciones JavaScript ni solicitudes fallidas durante la observación.
  Capturas e informes regenerables en `build/validacion_chrome.png`,
  `build/validacion_chrome_movil.png` y sus `.json`. El tamaño móvil en Chrome
  no constituye una comprobación de Android nativo.
- La consola por API confirmó de nuevo la base habitual
  `/home/rolo/.local/share/RHIA/Champ/champ.db`, esquema 3, sin crear otra base.
- Revisión del widget actual en Chrome debug de escritorio: logotipo Google original local,
  botón visible, clic real abre el ajuste pendiente y Entendido cierra el diálogo.
  Sin excepciones JS ni solicitudes fallidas observadas. El plugin carga su
  script web al inicio, pero el clic sin configuración no inicia OAuth.
  Capturas e informe en `build/boton_google_chrome*`.
  La emulación móvil CDP mostró el widget sin desbordamientos y registró una
  aserción debug del motor sobre insets; no equivale a una prueba Android.

Las pruebas de interfaz del recorrido match → chat usan el adaptador de
preferencias de prueba; la entrada y navegación a Chat utilizan servicios SQLite
aislados. Las pruebas de conservación, concurrencia, lotes y procesos utilizan
SQLite real en carpetas temporales verificadas; la prueba de API utiliza HTTP
real en bucle local. No se escriben fichas de prueba en la base habitual.

La validación real de Google (ingreso, popup/selector, foto, restauración y cierre)
requiere los registros Firebase de Champ, Google habilitado, dominios web y huellas
Android. No hay dispositivo/emulador Android conectado; el APK compilado no
constituye una comprobación visual ni de autenticación en Android. También quedan
pendientes el ciclo visual completo de contenido en Chrome, selección nativa de
fotos y empaquetados Windows/macOS. El catálogo de perros y sus intereses iniciales
siguen identificados como demostración; no hay mensajería entre equipos. Membership
necesita el catálogo comercial real y un servicio verificable de pagos para
acreditar membresías activas. Véanse los documentos de cada módulo.

Referencias técnicas: [sqlite3](https://pub.dev/packages/sqlite3/versions/2.9.4) y
[instantáneas con VACUUM INTO](https://www.sqlite.org/lang_vacuum.html).
