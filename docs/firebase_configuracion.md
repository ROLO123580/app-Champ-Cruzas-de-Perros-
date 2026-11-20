# Google/Firebase de Champ: configuración y comprobaciones

## Activación real verificada

Se consultó el proyecto `champ-dog-app` con la sesión Firebase del propietario:

- Google estaba habilitado y `localhost` figura entre los dominios autorizados.
- Se habilitó correo/contraseña para los formularios existentes de ingreso y registro.
- Se habilitó la API de Firestore y se creó `(default)` en Santiago,
  `southamerica-west1`, edición Standard. La respuesta de creación indicó `freeTier: true`.
- Se compilaron y publicaron las reglas existentes de `firestore.rules` mediante
  `firebase deploy --only firestore:rules --project champ-dog-app --non-interactive`.
- Se conservó el archivo externo `~/.config/Champ/firebase.web.json`; su validación local pasó.

Estos resultados sustituyen los pendientes externos históricos descritos más abajo
para web. Android conserva sus requisitos propios. Falta comprobar manualmente
el ingreso Google, su restauración y el intercambio de mensajes entre dos cuentas.
No se crearon usuarios de prueba ni se escribió contenido de chat productivo.
La API SQLite conserva su ubicación y datos existentes.

Para abrir la versión web con Firebase, inicia primero `dart run tool/champ_api.dart`
y, en otra terminal, `bash tool/iniciar_champ_web.sh`. Abre
`http://localhost:8793` (hostname autorizado); mantén ambos procesos activos.

## Configuración recuperada para la ejecución local · 2026-10-21

El historial de terminal contiene una ejecución de Champ con el registro web
`champ-dog-app`. Se recuperaron sus cinco opciones en
`~/.config/Champ/firebase.web.json`, fuera del repositorio, sin copiar la
configuración de Fénix. El verificador web terminó con código 0. El propietario
confirma que ingresaba con Google en la ejecución anterior. Ejecutar con
`--dart-define-from-file` como indica README; omitirlo causa el aviso local de
configuración pendiente y no demuestra que Firebase esté desactivado.
La descripción histórica siguiente corresponde a la inspección previa a esta
recuperación; Firestore y sus reglas todavía requieren comprobación por separado.

Actualización 2026-10-21: Chat añade Cloud Firestore 7.0.0 sobre el mismo
Firebase inicializado por el login. Crear la base `(default)` y publicar
`firestore.rules` son pasos adicionales; véase [Chat](chat.md). No se añade
una segunda inicialización ni se modifica la persistencia SQLite existente.

Estado observado: 2026-10-20. La copia Windows inicial de Fénix es visual;
la copia funcional encontrada en `/home/rolo/flutter_projects/fenix_fitness`
sí tiene Firebase y Google. Su configuración corresponde al proyecto
`fenix-fitness-4ed48` y al paquete `com.example.fenix_fitness`, no a Champ.
No se trasladó esa configuración. No se dispone de acceso a Firebase
Console/Google Cloud del propietario; la auditoría de ambas copias está en
[reutilizacion_fenix.md](reutilizacion_fenix.md).

Champ incorpora `firebase_core 5.0.0`, `firebase_auth 7.0.0` y
`google_sign_in 7.2.0`, según la resolución de dependencias de esta integración.
Chrome usa `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`; Android usa
`GoogleSignIn.instance.initialize/authenticate` y una credencial `idToken` de
Google para Firebase. Firebase se inicializa en el servicio de autenticación;
no se debe añadir otra inicialización en una pantalla o en `main.dart`.
El flujo coincide con la [documentación oficial de autenticación federada](https://firebase.google.com/docs/auth/flutter/federated-auth).

## Archivos y ajustes que faltan

| Elemento | Situación local al inspeccionar | Acción externa |
| --- | --- | --- |
| Proyecto Firebase para Champ | No hay un ID verificado | Seleccionar o crear el proyecto que el propietario destina a Champ. No copiar el de otra app sin verificar los registros. |
| Registro web | Sin valores reales disponibles | Registrar la app web Champ en ese proyecto y copiar sus valores reales a un archivo de defines externo. |
| Authentication → Sign-in method → Google | No verificable desde el repositorio | Habilitar Google y elegir correo de soporte. |
| Authentication → Sign-in method → Email/Password | No verificable desde el repositorio | Habilitar correo/contraseña para los formularios de inicio y creación de cuenta reutilizados de Fénix. |
| Authentication → Settings → Authorized domains | No verificable desde el repositorio | Para Chrome local, autorizar `localhost`; si se usa `127.0.0.1`, revisar y autorizar ese hostname. Sin esquema, puerto ni ruta. |
| `android/app/google-services.json` | Ausente | Descargarlo del registro Android de Champ después de configurar Google y las firmas. |
| Registro Android | `applicationId` y namespace reales: `com.example.champ` | Registrar exactamente ese paquete mientras no se acuerde cambiarlo. El de Fénix es `com.example.fenix_fitness` y no corresponde. |
| Huellas de firma en Firebase/Google Cloud | No verificables remotamente | Agregar las de debug usadas al compilar; antes de distribuir, también release y firma de Google Play, cuando existan. |
| Firma release | Gradle conserva la firma debug de la plantilla | Configurar una firma propia antes de distribuir. No se generó un certificado de producción. |

Android incorpora `com.google.gms.google-services 4.5.0`, versión de la
[guía oficial de configuración Android](https://firebase.google.com/docs/android/setup).
La aplicación del plugin queda condicionada a la presencia del JSON real; antes
de procesarlo Gradle valida paquete, proyecto, número y appId Android. Cuando
se envían defines, también compara proyecto/appId/sender con el archivo.
La ausencia del JSON permite abrir Champ con el aviso de configuración pendiente;
no habilita autenticación por sí misma. El manifiesto incluye permiso INTERNET
y restringe HTTP sin cifrar a `localhost`, `127.0.0.1` y `10.0.2.2`.

Los proyectos Firebase creados después del 28-04-2025 no autorizan `localhost`
por defecto; debe verificarse en consola. Véase la
[guía oficial de dominios autorizados](https://firebase.google.com/docs/auth/faq-and-troubleshooting).

## Chrome: valores y ejecución

El servicio `lib/core/servicios/configuracion_firebase.dart` consume las siguientes
claves de `--dart-define` o `--dart-define-from-file`:

| Clave | Valor obtenido del registro web real |
| --- | --- |
| `FIREBASE_API_KEY` | `apiKey` |
| `FIREBASE_APP_ID` | `appId`, del tipo web |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` |
| `FIREBASE_PROJECT_ID` | `projectId` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain`, solo hostname |
| `FIREBASE_STORAGE_BUCKET` | `storageBucket`, opcional; no cambia dónde guarda Champ sus imágenes |

Guarda estas claves y sus valores reales como un objeto JSON plano en
`$HOME/.config/Champ/firebase.web.json`. El archivo puede estar fuera del
repositorio. No contiene contraseña de Google ni claves privadas; no se necesita
una cuenta de servicio para iniciar sesión desde Flutter.

Desde Ubuntu/WSL, en la raíz de Champ:

```bash
dart run tool/verificar_firebase.dart --platform web --defines "$HOME/.config/Champ/firebase.web.json"
flutter run -d chrome --dart-define-from-file="$HOME/.config/Champ/firebase.web.json"
```

La API de datos de Champ debe continuar activa en otra terminal, como antes:

```bash
dart run tool/champ_api.dart
```

La ventana emergente se inicia al pulsar el botón. Permite popups si Chrome los
bloquea. En Google Cloud revisa el cliente OAuth web asociado al mismo proyecto
y el estado de la pantalla de consentimiento. Si está en modo de prueba y limita
usuarios, agrega la cuenta de prueba autorizada. Conserva el URI de callback de
Firebase que muestra la consola; si cambias `authDomain`, también debe coincidir
el callback del cliente OAuth. No hace falta trasladar el acceso a la API SQLite
ni crear colecciones cloud.

La CLI es una alternativa para recuperar opciones registradas:
`firebase login`, `dart pub global activate flutterfire_cli` y
`flutterfire configure --platforms=web,android` desde Champ. Elige el proyecto
real y revisa los archivos producidos. Esta app lee los defines anteriores;
un `lib/firebase_options.dart` generado no se importa automáticamente. Copia sus
valores correspondientes al JSON de cada plataforma. La CLI puede modificar
configuraciones de plataforma; revisa el diff. Véase la
[configuración oficial de FlutterFire](https://firebase.google.com/docs/flutter/setup).

## Android: registro, OAuth y firma

1. En Firebase → Configuración del proyecto → Tus apps, registra Android con
   `com.example.champ`. Comprueba que el proyecto sea el mismo del registro web.
2. Obtén las huellas del entorno que realmente compilará. Desde `android/`,
   `./gradlew signingReport` en Ubuntu o `gradlew.bat signingReport` en Windows.
   Esas órdenes requieren JDK/SDK y pueden descargar Gradle. No reutilices una
   huella de otro equipo sin comprobar el certificado.
3. En ese registro Android agrega SHA-1 y SHA-256. Habilita Google en
   Authentication y descarga de nuevo `google-services.json`. Verifica
   `client_info.android_client_info.package_name == com.example.champ` y que
   `project_info.project_id` sea el proyecto elegido.
4. Copia el archivo real a `android/app/google-services.json`. La integración
   Gradle lo procesa cuando existe. No lo sustituyas por JSON de Fénix.
5. Verifica el cliente OAuth Android del mismo paquete y SHA-1. El cliente OAuth
   web del proyecto (`client_type: 3` en el JSON) permite obtener el ID token.
   Si no está disponible por los recursos de Google Services, pasa su ID real
   mediante `GOOGLE_SERVER_CLIENT_ID`; no uses el ID del cliente Android como
   `serverClientId`. La [documentación oficial del plugin Android](https://pub.dev/packages/google_sign_in_android)
   describe esta asociación.
6. Ejecuta `dart run tool/verificar_firebase.dart --platform android` antes de
   volver a compilar. Si además pasas opciones por defines, crea un JSON Android
   independiente con el `appId` Android; no reutilices el `appId` web.

Sin defines Android, Firebase obtiene sus opciones nativas del JSON procesado
por Gradle. Si suministras alguna de las cuatro opciones Firebase básicas por
defines, debes suministrarlas todas. `GOOGLE_SERVER_CLIENT_ID` es independiente
y opcional cuando el JSON ya aporta el cliente web.

Para mantener la API vinculada a loopback al probar Android por USB o emulador,
ejecuta `adb reverse tcp:8787 tcp:8787`. La app puede seguir usando
`http://127.0.0.1:8787`. ADB y la API deben corresponder al mismo equipo/entorno;
WSL y Windows no comparten automáticamente su servidor ADB. La política HTTP
de Android permite el acceso local previsto, mientras Google usa HTTPS.

### Entorno Android observado

En Windows hay Android Studio/JBR, pero no se encontró SDK en
`C:/Users/USER/AppData/Local/Android/Sdk`, `adb`/Java no estaban en PATH ni había
certificado debug en `C:/Users/USER/.android/debug.keystore`.
`android/local.properties` apunta a Ubuntu/WSL:

- SDK: `/home/rolo/Android/Sdk`; plataformas `android-34`, `android-36` y
  build-tools `36.0.0` presentes.
- La compilación debug instaló además plataforma `android-35` y CMake `3.22.1`;
  generó correctamente el APK sin JSON, con acceso pendiente de configurar.
- Java y keytool en `/usr/bin`; adb en `Sdk/platform-tools/adb`.
- `adb devices` sin dispositivos conectados. No se hallaron directorios locales
  `Sdk/emulator` ni `~/.android/avd`; no se comprobó presentación Android.
- Certificado debug leído de `/home/rolo/.android/debug.keystore`:
  SHA-1 `CC:1F:0F:A8:62:B1:9F:CE:1B:42:92:1B:3B:0B:69:11:88:39:D8:FA`.
- SHA-256 del mismo certificado:
  `34:9E:5D:DF:54:9F:B6:6E:D4:CE:B5:73:25:54:59:E8:98:6D:80:4A:74:BB:5E:F7:0F:97:3F:F2:65:25:14:9F`.

Estas son huellas públicas de debug observadas; no prueban que estén registradas
en Firebase ni corresponden a una firma de producción.

## Alcance de la comprobación

`tool/verificar_firebase.dart` solo lee archivos locales, sin imprimir API keys,
tokens ni contraseñas. Valida presencia y coherencia de paquete, proyecto,
appId y cliente OAuth; termina con código 1 cuando falta configuración. No llama
a Firebase Console ni autentica a un usuario. Las pruebas con dobles verifican
los estados de la UI/controlador; no equivalen a un ingreso real de Google.

Se ejecutó el verificador contra el estado real del repositorio: código 1 en
Chrome por faltar las cinco opciones web; código 1 en Android por faltar
`google-services.json`. No se generaron valores ficticios para obtener código 0.

Pendiente, una vez completados los registros reales: ingreso correcto; cancelar
selector/popup; error de red y dominio no autorizado; nombre/foto; restauración
al recargar Chrome y relanzar Android; cierre de sesión; atrás sin duplicados;
y conservación de contenido SQLite después de salir y reiniciar. El SDK conserva
sus credenciales; Champ no añade credenciales a las tablas de contenido.
