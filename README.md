# Champ

Perdidos y encontrados incorpora avisos con foto, zona, microchip informado,
edicion, contacto por chat y cierre del caso. Consulte
[Perdidos y encontrados](docs/perdidos_encontrados.md) para alcance, identificacion
por chip, reglas Firestore y pruebas. El chip no proporciona rastreo GPS.

La separacion de NanoApps, NanoFunciones y NanoActividades esta documentada en
[Estructura de Comunidad](docs/estructura_comunidad.md). Para validar y compilar
usa `bash tool/validar_champ.sh` o `tool/validar_champ.ps1`.

## Comunidad y eventos

Comunidad incorpora muro de texto, eventos en parques, inscripcion por cupos y
chat de participantes. Paseos muestra los paseos compartidos y Chat agrega una
pestana de eventos. Requiere publicar las nuevas reglas en el Firebase propio de
Champ; consulta [Comunidad y eventos](docs/comunidad_eventos.md) para activacion,
pruebas y limites. La base SQLite existente se conserva.

Aplicación para descubrir perros, guardar likes y matches y conversar con sus
responsables. El catálogo inicial y los intereses recibidos son de demostración;
el chat entre cuentas está integrado con Firestore y requiere activar el
Firebase propio de Champ. Consulta [Chat](docs/chat.md).

## Ejecutar en Ubuntu / Chrome

Desde la raíz del proyecto:

```bash
flutter pub get
```

En una terminal inicia el servicio de datos y déjalo abierto:

```bash
dart run tool/champ_api.dart
```

En otra terminal inicia Champ con su configuración Firebase guardada:

```bash
bash tool/iniciar_champ_web.sh
```

Abre `http://localhost:8793` y mantén ambas terminales abiertas. El script lee
`~/.config/Champ/firebase.web.json` (o `CHAMP_FIREBASE_DEFINES`) y permite cambiar
el puerto web con `CHAMP_WEB_PORT`.

Champ muestra Login con Google y correo/contraseña. Para habilitar el acceso real necesita el
registro Firebase propio de Champ; sin él se presenta el ajuste pendiente.
Consulta [configuración por plataforma](docs/firebase_configuracion.md) y
[Login](docs/login.md). Con los valores web reales guardados fuera del proyecto:

```bash
flutter run -d chrome --dart-define-from-file="$HOME/.config/Champ/firebase.web.json"
```

La sesión Google conserva los datos locales existentes. Las conversaciones
nuevas entre cuentas usan Firestore; el historial local no se sube automáticamente.
El menú incluye **Membership**, **Carro** y **Cerrar sesión**. Membership carga
planes publicados en la API local; el catálogo está vacío hasta disponer de las
condiciones reales de Fénix/Champ. Seleccionar o dejar pendiente un plan no acredita
un pago. Consulta [Membership y Carro](docs/membership.md) y la
[revisión del proyecto de referencia](docs/reutilizacion_fenix.md).

La API muestra la ubicación de `champ.db` y escucha en `127.0.0.1:8787`. Ese es
el puerto de los datos; Flutter puede elegir su propio puerto. En Ubuntu la raíz
predeterminada es `~/.local/share/RHIA/Champ/`, con `champ.db`, `imagenes/` y
`respaldos/`. Los datos pertenecen a la aplicación, no a una cuenta o plan, y no
tienen fecha de vencimiento. Conservarlos también requiere cuidar el disco y
guardar respaldos fuera de ese equipo.

El servidor en Ubuntu necesita `libsqlite3.so.0`, disponible en el paquete
`libsqlite3-0`. Chrome y escritorio acceden a todo mediante la misma API.
Para escritorio, mantén la API iniciada y ejecuta `flutter run -d linux`,
`flutter run -d windows` o `flutter run -d macos`, en el sistema correspondiente.
Los empaquetados de escritorio aún necesitan validación manual.

`CHAMP_DATA_DIR` permite indicar otra carpeta persistente absoluta al proceso
API. La ubicación depende del sistema que ejecuta ese servidor; los clientes
que apuntan a la misma API utilizan esa misma base y carpeta de imágenes.
Al cambiar entre ellos ejecuta `flutter clean` y `flutter pub get` para regenerar
las rutas de dependencias del sistema actual.

Para usar otro puerto de datos: `dart run tool/champ_api.dart 8788` y
`flutter run -d chrome --dart-define=CHAMP_API_URL=http://127.0.0.1:8788`.
El mismo `--dart-define` se aplica a los destinos de escritorio. Para la consola
de mantenimiento, configura la variable de entorno `CHAMP_API_URL` con esa URL.

## Cruces y Chat

Al entrar se abre **Inicio**, con el resumen del perfil, los intereses y matches
locales y accesos a Mis perros, Cruces, Chat y Configuración. **Mis perros**
permite crear y editar el perfil actual y su foto mediante el mismo controlador
y almacenamiento que usa Cruces. Por ahora se admite un perfil propio por
instalación; no se crean copias al cambiar de pantalla.

En Cruces, crea el perfil de tu perro, añade una foto opcional y
descubre candidatos con filtros de raza y ciudad. Desliza a la derecha para
indicar interés o a la izquierda para pasar; también hay botones. Un like mutuo
genera un único match y permite abrir o retomar su conversación en Chat.

Las fichas, decisiones, matches y el historial de chat local se conservan en SQLite.
El chat entre usuarios guarda conversaciones y mensajes en Firestore, con acceso
por participante. Comparte tu ID desde Chat e introduce el de la otra cuenta en
Conversación. Requiere crear Firestore y publicar las reglas incluidas; los
detalles y límites están en [docs/chat.md](docs/chat.md).
Las fotos propias se copian a disco y se referencian desde la base. Las cuatro
fotos ilustrativas del catálogo se incluyen en `assets/catalogo/` y se copian al
mismo almacenamiento persistente, por lo que no requieren conexión externa.
La selección admite PNG, JPEG y WebP de hasta 1 MB y 20 megapíxeles. Se eliminó
el límite anterior de 4 MB para el historial.

Se importa el almacenamiento anterior disponible (`champ.chat.v1` y
`champ.cruces.v1`) sin borrarlo. Para importar preferencias antiguas de Chrome,
abre el mismo origen de entonces (host y puerto). Los datos nuevos de SQLite
ya no dependen del origen ni de la limpieza de almacenamiento del navegador.

## Respaldos y mantenimiento

En **Configuración → Respaldar base y fotos** se crea una instantánea consistente
con manifiesto de hashes. Para administrar los mismos datos desde consola,
mantén la API iniciada: esta herramienta también utiliza HTTP.

```bash
dart run tool/champ_db.dart estado
dart run tool/champ_db.dart respaldar
dart run tool/champ_db.dart listar perfiles
dart run tool/champ_db.dart listar razas
```

El módulo también permite `guardar colección id archivo.json` y
`eliminar colección id`. El JSON debe incluir el mismo `id`.
Para recuperar una copia, detén la API y vuelve a iniciarla con
la carpeta completa del respaldo como `CHAMP_DATA_DIR`. No reemplaces solo el
archivo SQLite mientras la aplicación está abierta.

## Arquitectura y validación

Se mantiene **App → MicroApp → NanoApp → NanoFunción → NanoActividad**.
`main.dart` inicia y `app_champ.dart` orquesta módulos, navegación y servicios.
Los modelos, contratos, repositorios y servicios están en `lib/core/`.
Consulta [ARQUITECTURA.md](ARQUITECTURA.md) para las rutas, migraciones y límites;
[CHANGELOG.md](CHANGELOG.md) registra los cambios y resultados reales.

```bash
flutter analyze
flutter test
flutter build web
```

REA no aparece configurado en este proyecto ni estuvo disponible como herramienta
de la sesión. En Windows, los plugins requieren Modo de desarrollador para sus
enlaces simbólicos. Se conserva el permiso macOS para leer archivos seleccionados.
