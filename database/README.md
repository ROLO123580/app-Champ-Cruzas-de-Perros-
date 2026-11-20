# Bases de datos de las nueve apps

Primera base técnica, 29-10-2026. Los siete SQL son esquemas iniciales para
SQLite, aún sin conexión con Flutter. Se prepararon leyendo los catálogos de
pantallas de `C:/flutter_projects`. No contienen datos personales ni comerciales.

**Alcance actualizado:** la definición del usuario está en
[ALCANCE_APPS.md](ALCANCE_APPS.md). Tiene prioridad sobre las inferencias iniciales.
En particular, RH Comercio requiere un esquema de pagos divididos y reservas;
su SQL inicial de punto de venta queda como antecedente. El prototipo de Fenix
Fitness de esta carpeta tampoco sustituye el módulo nutricional ya integrado
en el proyecto vecino `fenix_fitness`.

| App | Estado encontrado | Base / entidades iniciales |
| --- | --- | --- |
| champ | SQLite y chat Firestore implementados | Se conserva su motor: documentos, imágenes, likes y matches; conversaciones remotas según `firestore.rules`. |
| fenix_controls | SQLite por API Python implementado | Se conservan `apps` y `logs`, con relación por `app_id`. |
| fenix_fitness | Pantallas iniciales | Personas, entrenadores/alumnos, consumos, gastos, objetivos, progreso. |
| legal_smart | Funciones jurídicas pendientes de definición | Solo núcleo común. Expedientes, clientes y fuentes jurídicas quedan pendientes de definir. |
| myfitmentor | Pantallas iniciales | Deportistas, clubes, equipos, integrantes, entrenamientos, evaluaciones y competiciones. |
| rh_comercio | Pantallas iniciales | Productos, movimientos de inventario, cajas, ventas, detalle y cobros. |
| rh_pay | Pantallas iniciales | Cuentas y solicitudes de operaciones; aún sin libro contable ni ejecución de pagos. |
| smartconvert_ia | Pantallas iniciales | Archivos, trabajos, extracciones, facturas importadas y costos de procesamiento. |
| taskflow_pro | Pantallas iniciales | Proyectos, tareas, dependencias, recursos, asignaciones y avances. |

## Uso

Desde la raíz de Champ, con Python 3 y sin dependencias adicionales:

```bash
python3 tool/preparar_bases.py verificar
python3 tool/preparar_bases.py crear --destino /tmp/rhia-bases-iniciales
```

`crear` genera siete archivos `.db` nuevos. Rechaza destinos que ya contengan
alguno de esos nombres. No abre las bases de Champ ni Fenix Controls: estas
deben seguir inicializándose con sus servicios y migraciones actuales.
Las bases nuevas son prototipos vacíos y no son aún bases de producción.
La primera ejecución dejó los siete archivos locales en `database/prototipos/`;
se excluyen del control de versiones. Los SQL son la fuente reproducible.

## Convenciones y decisiones iniciales

- Una base por app, con núcleo común repetido dentro de cada una. Ninguna app
  consulta directamente tablas de otra. Un futuro intercambio requiere API e
  identidades externas explícitas; un ID local no vincula automáticamente cuentas.
- IDs de texto generados por el servicio, fechas UTC ISO 8601 y moneda explícita.
  Los importes se expresan en unidades mínimas enteras, nunca en coma flotante.
  Para activos de RH Pay se define la escala en la cuenta (por ejemplo BTC: 8).
- Claves foráneas habilitadas en **cada conexión**. El servicio deberá comprobar
  identidad y autorización por usuario antes de exponer datos; SQLite no implementa
  aquí permisos por fila. Estas bases son locales y no deben exponerse directamente.
- Archivos guardados fuera de SQLite; la tabla conserva ruta relativa y hash.
  El servicio deberá validar rutas, contenido y existencia al guardar y respaldar.
- Membership conserva catálogo y solicitudes. Una solicitud no acredita pago ni
  concede acceso. No se insertan planes ni precios inventados.
- Versionado inicial `user_version=1`. Cambios posteriores requieren migraciones
  transaccionales y respaldo previo; estos SQL son para bases nuevas únicamente.
- Balance, rendimiento, historial, Gantt y reportes se derivan de registros base.
  Evitamos guardar copias independientes que puedan quedar desactualizadas.

## Alcance pendiente antes de conectar las apps

El alcance confirmado de las nueve apps y las ampliaciones necesarias se detallan
en [ALCANCE_APPS.md](ALCANCE_APPS.md). Para Fenix Fitness hay que separar el gasto
energético del monetario si este último se incluye. Legal Smart requiere concretar
su primer flujo jurídico.
RH Pay requiere diseñar un libro contable de doble partida, conciliación,
idempotencia de proveedor y confirmación del servidor antes de representar
operaciones ejecutadas o saldos disponibles. Su esquema actual guarda solo
solicitudes. Facturas SII son registros importados, sin emisión ni conexión al SII.
Taskflow requiere validar ciclos de dependencias en el servicio.

Faltan los repositorios y APIs de las siete apps, autenticación y permisos,
respaldos de base y archivos, pruebas de flujos e integración Flutter. Este paquete
no cambia la configuración Firebase ni modifica bases existentes.
