# Login de Champ

Actualización 2026-10-21: el acceso actual también incluye correo/contraseña y
creación de cuenta. El chat entre cuentas usa el mismo Firebase y UID, con
Firestore; el historial SQLite se conserva. Las referencias más abajo a
Firebase exclusivamente para identidad describen la implementación anterior.
Consulta [Chat](chat.md) para configurar la nueva persistencia.

## Reutilización y rutas

El origen revisado es `C:/flutter_projects/fenix_fitness/lib/nanoapps/login/app_login.dart`.
Ese archivo contiene un Scaffold, título y botón `Entrar` con callback: no inicia
Google, no restaura una sesión y no incluye Firebase. Se reutilizó su NanoApp
como estructura de presentación; el acceso real y sus servicios son nuevos en
Champ. Fénix Fitness permanece sin cambios.

La composición es:

```text
App Champ (app_champ.dart)
  → MicroApp acceso (microapps/acceso/app_acceso.dart)
  → NanoApp login (nanoapps/login/app_login.dart)
  → NanoFunción gestionar_sesion (nanofunciones/gestionar_sesion/gestionar_sesion.dart)
  → NanoActividad autenticar_google (nanoactividades/autenticar_google/autenticar_google.dart)
  → ServicioAutenticacion (core/servicios/autenticacion.dart)
  → AutenticacionFirebase (core/servicios/autenticacion_firebase.dart)
```

`core/modelos/sesion.dart` representa únicamente UID, nombre, correo y foto
públicos. `core/servicios/configuracion_firebase.dart` lee opciones de Champ.
Los controladores son inyectables y el orquestador es dueño de su ciclo de vida.
Login no hace push de rutas: el orquestador muestra Login o el contenido según
la sesión, evitando acumular pantallas al entrar o salir.

## Comportamiento implementado

Las dependencias resueltas son `firebase_core 5.0.0`, `firebase_auth 7.0.0` y
`google_sign_in 7.2.0`. Chrome usa `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`;
no utiliza el botón ni `authenticate()` de google_sign_in web. Android utiliza
`GoogleSignIn.instance.initialize()` una vez, `authenticate()` y credenciales
Firebase creadas con `cuenta.authentication.idToken`. El SDK Firebase se
inicializa una vez y proporciona la restauración y cierre de sesión.

La NanoFunción espera la restauración inicial, mantiene una suscripción al estado
del SDK, bloquea solicitudes repetidas y comunica carga, cancelación y error.
Al destruirla cancela su suscripción y no actualiza pantallas por resultados
tardíos. Una falla transitoria de restauración permite reintentar la conexión;
una inicialización Firebase exitosa se comparte y se verifica contra las
opciones de Champ antes de reutilizarla. No solicita permisos de contactos ni
autorización de Drive.

La presentación usa `nanoapps/login/widgets/boton_ingresar_google.dart`, con el
logotipo Google empaquetado, fondo blanco, borde y texto «Ingresar con Google».
El widget se mantiene visible durante la restauración; muestra carga y bloquea
acciones repetidas mientras hay una operación en curso. Solo presenta y entrega
la pulsación: el acceso continúa por la NanoFunción y NanoActividad existentes.
La procedencia del logotipo original se registra en
[assets/login/FUENTES.md](../assets/login/FUENTES.md).

No hay autenticación simulada en producción. Sin configuración, el botón muestra
un diálogo con el ajuste pendiente, sin llamar al SDK ni crear una sesión. La
pantalla mantiene un aviso breve y el detalle técnico queda dentro del diálogo.
Linux, Windows,
macOS e iOS requieren su propio registro antes de habilitar este login.

## Configuración externa

Ver [configuración Firebase por plataforma](firebase_configuracion.md).

Chrome necesita los valores reales de la app web de Champ mediante
`--dart-define` o un archivo JSON pasado a `--dart-define-from-file`:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET` opcional (Login no guarda contenido en Storage).

Android puede leer el registro nativo desde
`android/app/google-services.json`, con paquete `com.example.champ`, o recibir
las cuatro opciones Firebase anteriores correspondientes a Android. Las
opciones parcialmente definidas se rechazan. `GOOGLE_SERVER_CLIENT_ID` es el
cliente **web** OAuth de ese mismo proyecto y se pasa cuando la configuración
nativa no lo proporciona. Nunca se debe copiar la identidad de Fénix.

Habilitar Google en Authentication, comprobar dominios autorizados de la app web
y registrar SHA-1/SHA-256 de las firmas Android requiere acceso a las consolas.
Los cambios de `dart-define` requieren reiniciar/compilar la aplicación.

## Conservación y límites

No se modifican tablas ni migraciones SQLite. Tokens y credenciales pertenecen
al SDK de autenticación; no se escriben en SQLite ni preferencias propias.
Cerrar sesión no solicita borrar fichas, fotos, catálogos, likes, matches,
mensajes, selección de plan ni respaldos. La base sigue siendo por aplicación.
Firebase se utiliza exclusivamente para identidad: los datos de Champ continúan
por su API local. El acceso Google no convierte la API local en un servidor
multiusuario ni autoriza el pago de una membresía.

## Pruebas y pendientes

`test/login_test.dart` cubre con un servicio falso explícito: restauración,
suscripción única, ingreso, cancelación, error, reintento, cierre, bloqueo de
duplicados, configuración incompleta, dispose y presentación de estados.
Incluye el botón con carga y bloqueo de pulsaciones, además de abrir y cerrar
el detalle de configuración sin iniciar una sesión.
`test/soporte/autenticacion_falsa.dart` nunca se importa en el código productivo.
Estos casos prueban el comportamiento del controlador y las pantallas, no el
proveedor externo. Los resultados de ejecución se registran en CHANGELOG.md.

Ejecución final: los once casos de Login y los tres de navegación de
`test/navegacion_acceso_test.dart` pasaron dentro de la suite de 60 pruebas.
`flutter analyze` no informó incidencias. Antes del ajuste del widget se
compilaron web y APK debug, y se observó Login en Chrome con el botón genérico
deshabilitado. Las capturas de esa revisión inicial permanecen en
`build/validacion_chrome*.png`; no representan el nuevo botón de Google.

El widget actual también se verificó en Chrome debug de escritorio real: logotipo visible,
botón «Ingresar con Google» habilitado para consultar el ajuste pendiente y
apertura/cierre del diálogo mediante una pulsación real. No se observaron
excepciones JavaScript ni solicitudes fallidas. El plugin web carga su script
`accounts.google.com/gsi/client` al arrancar; esa carga no representa un ingreso
ni un flujo OAuth iniciado por el botón. Evidencia local en
`build/boton_google_chrome.png`, `_dialogo.png` y `.json`.

La vista de 390 × 844 mostró el botón y su diálogo sin desbordamientos. La
emulación CDP `mobile: true` produjo una aserción debug del motor Flutter
`_viewInsets.isNonNegative`, incluso al navegar antes de aplicar la emulación;
esa observación queda en `build/boton_google_chrome_movil_emulacion.json`.
No se presenta esa emulación como una prueba Android sin errores. La revisión
final de escritorio quedó sin errores y con el diálogo cerrado.

El ingreso real, cancelación real de popup/selector, nombre/foto de Google,
restauración de credenciales reales y cierre con Google quedan pendientes hasta
disponer del registro Firebase y la configuración válida de Champ, así como de
un navegador/dispositivo conectado para la prueba manual.

Referencias oficiales consultadas:
[Firebase: autenticación federada Flutter](https://firebase.google.com/docs/auth/flutter/federated-auth),
[Google Sign-In 7.2.0](https://pub.dev/packages/google_sign_in/versions/7.2.0),
[API de GoogleSignIn](https://pub.dev/documentation/google_sign_in/7.2.0/google_sign_in/GoogleSignIn-class.html).
