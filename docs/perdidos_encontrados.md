# Perdidos y encontrados

Incluye listado, filtros por perdido/encontrado/resuelto, busqueda por zona/nombre
y terminacion del chip, Mis avisos, foto, formulario de alta/edicion, detalle,
contacto mediante el chat privado existente y cierre con nota.

## Estructura

App → MicroApp `AppRescateCanino` → NanoApp `AppPerdidosEncontrados` y sus vistas
FormularioAviso/DetalleAviso → NanoFuncion `GestionarAvisos` → NanoActividades:

- ConsultarAvisos: listado y observacion de la ficha.
- GuardarAviso: validacion y guardado con identidad estable.
- ResolverAviso: validacion de la nota y cierre del caso.
- SeleccionarFotoAviso: reutiliza el selector existente y prepara PNG reducido.

Las actividades usan `RepositorioAvisosPerros`; la implementacion Firestore guarda
en `avisos_perros/{id}`. Las pantallas no consultan Firebase ni SQLite directamente.
El shell conserva el controlador durante la sesion y abre chats entre UIDs mediante
GestionarChat y sus actividades existentes. El boton de contacto no envia mensajes
automaticamente ni entrega correo/telefono del autor.

## Microchip

El microchip implantado contiene identificacion que necesita un lector cercano.
No transmite coordenadas ni permite seguimiento GPS. Fuente:
[AVMA](https://avma.org/microchipping-animals-faq).

Se registra si tiene chip (si/no/no se sabe) y opcionalmente sus ultimos cuatro
digitos. No se publica el numero completo. Pegar un numero completo causa error
de validacion, sin recortarlo silenciosamente. Una coincidencia parcial no prueba
identidad ni propiedad y no sustituye la lectura/cotejo correspondiente.
No se conecta con registros oficiales ni lectores fisicos en esta etapa.
No hay rastreo en tiempo real; el lugar es una referencia reportada por el usuario.

## Fotos y persistencia

El selector admite las imagenes existentes de hasta 1 MB y 20 megapixeles. La
actividad genera una copia PNG de hasta 80 KiB, con lado mayor de hasta 640 px,
reduciendola mas cuando sea necesario. La foto se comparte dentro del documento
Firestore con limite de 120000 caracteres base64. No depende del disco del autor.
Se muestran hasta los 50 avisos mas recientes y se filtran dentro de ese conjunto;
no es una busqueda exhaustiva de todos los registros historicos.
Para un volumen mayor conviene paginar y separar fotos en almacenamiento dedicado.

El formulario conserva texto/foto durante un fallo mientras siga abierto. Pide
confirmacion al descartar cambios; no guarda borradores persistentes. Solo confirma
exito despues de completar la transaccion. No altera las fichas de Mis perros ni
los datos SQLite existentes.

## Reglas y activacion

Las cuentas autenticadas pueden leer los avisos. Solo el autor crea en su nombre,
edita su aviso activo o lo cierra con una nota. No se permite reabrir, editar un
aviso cerrado, cambiar autor/fecha de creacion ni borrar documentos desde el cliente.
Las reglas rechazan campos adicionales, chip completo, fechas futuras, fotos fuera
de limite y cierre ajeno. La imagen sigue siendo contenido del usuario; una imagen
invalida recibida muestra un marcador, sin romper la ficha.

Es necesario publicar el archivo actualizado `firestore.rules` en el Firebase real
de Champ para usar los avisos entre cuentas. No se despliega automaticamente:

```bash
firebase deploy --only firestore:rules --project ID_REAL_DE_CHAMP
```

Antes de desplegar, revisar el proyecto y las reglas actualmente publicadas. El
archivo conserva el muro, eventos y chats privados de las etapas anteriores.

## Validacion

96 pruebas Flutter aprobadas (ocho nuevas de avisos), analisis sin incidencias,
compilacion web y tres capturas con datos de prueba. Pruebas a 320 px con texto
ampliado, guardado/edicion/cierre, conservacion ante fallos, foto reducida y chip.
El emulador Firestore comprobo intercambio entre cuentas, fotos, edicion/cierre y
21 rechazos de permisos. Tambien se verificaron de nuevo eventos/grupos y privados.

```bash
flutter test test/avisos_perros_test.dart
firebase emulators:exec --only firestore --project demo-champ 'node tool/verificar_avisos_emulador.mjs'
```

No se crean avisos ficticios en produccion, no se despliegan reglas ni se modifica
la base personal durante estas pruebas. Los ejemplos de las capturas no representan
un perro perdido real.
