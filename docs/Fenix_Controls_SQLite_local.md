# Cómo iniciar Fénix Controls con SQLite local

SQLite ya está integrado en `tool/fenix_api.py` mediante el módulo `sqlite3` de Python. No se instala un servidor de base de datos ni se ejecuta SQL manualmente: el servicio crea la carpeta, el archivo y las tablas al iniciar. Sí debes mantener abierto el servicio HTTP local que conecta Flutter con SQLite.

## Primera instalación (Windows con Ubuntu/WSL)

Necesitas Git, Python 3 en Ubuntu, Flutter y Chrome. Cada persona instala su copia y tiene su propia base local; GitHub comparte código, no sincroniza registros.

En una terminal Ubuntu:

```bash
cd /mnt/c/flutter_projects
git clone https://github.com/ROLO123580/fenix_controls.git
cd fenix_controls
flutter pub get
python3 -c "import sqlite3; print(sqlite3.sqlite_version)"
```

Si esa carpeta ya existe, no la reemplaces ni vuelvas a clonar encima: usa el proyecto existente. GitHub puede solicitar autenticación; utiliza tu propia cuenta con acceso al repositorio privado.

## Inicio diario

Terminal A, en Ubuntu:

```bash
cd /mnt/c/flutter_projects/fenix_controls
bash tool/start_service.sh
```

Espera el mensaje `Fenix Controls: http://127.0.0.1:8791` y la ruta SQLite. Conserva la terminal abierta. En WSL el script utiliza `%LOCALAPPDATA%\FenixControls\fenix_controls.db` de Windows. En Linux sin WSL utiliza `~/.local/share/FenixControls`. La ruta anunciada al iniciar es la referencia definitiva.

Terminal B, en Ubuntu:

```bash
cd /mnt/c/flutter_projects/fenix_controls
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8795
```

Espera la compilación y abre Chrome en **http://localhost:8795**. Ese es el puerto de la interfaz; 8791 corresponde a los datos. Puedes usar `flutter run -d chrome` si quieres que Flutter lance Chrome automáticamente.

## Comprobar el guardado

Crea una app de prueba, añade una entrada a su bitácora y recarga. Detén la web con `q` y la API con Ctrl+C. Inicia ambos servicios de nuevo con los mismos comandos y comprueba que el registro siga presente. Esta comprobación usa tu base local: elimina después el registro de prueba desde la interfaz si no lo necesitas.

## Respaldos y datos

El servicio crea respaldos al iniciar y antes de cada escritura, en `respaldos/` junto a la base. La cabecera permite crear un respaldo manual. Copia periódicamente los respaldos completos a otro disco. No reemplaces el archivo SQLite mientras el servicio esté activo; consulta README para restaurarlo.

Las bases, fotos privadas, contraseñas y respaldos no deben subirse al repositorio. El archivo `.gitignore` excluye las bases locales. GitHub privado controla acceso al código; no convierte esta API local en un servicio compartido ni añade autenticación a la aplicación.

## Problemas habituales

- **Puerto 8791 ocupado:** revisa si el servicio ya está abierto. No ejecutes dos servicios contra la misma base.
- **La interfaz abre, pero no guarda:** comprueba la Terminal A y los errores visibles. Tras una interrupción recarga para comprobar si se guardó antes de repetir.
- **No aparecen mis registros:** comprueba el usuario, la ruta anunciada y `FENIX_DATA_DIR`. Otra ruta significa otra base.
- **Falta Python o Flutter:** instala/configura la herramienta correspondiente en Ubuntu; las herramientas Windows y WSL pueden usar rutas diferentes.
- **Chrome Windows no alcanza localhost:** revisa el reenvío localhost de WSL y prueba el navegador en Ubuntu.

## Acceso de tu colaborador al repositorio

Mantén el repositorio como Private. En GitHub abre Settings → Collaborators → Add people, selecciona el usuario exacto y envía la invitación. La otra persona debe aceptarla con su propia cuenta. Conserva únicamente a ese colaborador y revisa por separado las integraciones autorizadas. Un colaborador de un repositorio personal puede modificar el código; no necesita tu contraseña.
