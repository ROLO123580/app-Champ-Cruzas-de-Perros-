# Entorno simulado (señuelo) de Champ

Proyecto Firebase **separado** con 15 cuentas y datos ficticios que interactúan en
todas las funciones. Es la base del futuro entorno señuelo: cuando las APIs exijan
firma de la app, el tráfico sin firma válida podrá derivarse aquí, lejos de los
datos reales. Los scripts se niegan a usar `champ-dog-app`.

## Qué se crea

| Función | Datos simulados |
| --- | --- |
| Cuentas | 15 cuentas `sim01@champ-sim.test` … `sim15@champ-sim.test`, con nombre visible |
| Cruces / Mis perros | 15 fichas privadas, una por cuenta, con 15 perros de 8 razas (macho/hembra para cruzar) |
| Perdidos y encontrados | 5 avisos (3 perdidos, 2 encontrados), con y sin microchip; con las fichas suman 20 perros |
| Paseos | 5 paseadores en distintas ciudades y 7 reservas: aceptadas (agenda bloqueada), solicitadas y rechazadas |
| Comunidad | 10 publicaciones en el muro y 3 eventos/paseos grupales con inscritos y mensajes |
| Chat | 5 conversaciones privadas entre cuentas |

Contraseña común: `ChampSim-2026!`, o la que definas en `CHAMP_SIM_PASSWORD`.
Al terminar, las cuentas con su UID quedan en `~/.config/Champ/simulacion_cuentas.json`.
El script se puede repetir: no duplica datos.

## Pasos (una vez)

1. En https://console.firebase.google.com crea un proyecto nuevo, por ejemplo `champ-sim`.
2. En ese proyecto:
   - **Agrega una app web** (ícono `</>`).
   - Ve a **Authentication → Sign-in method** y habilita **Correo electrónico/contraseña**.
   - Ve a **Firestore Database → Crear base de datos**.
3. En Ubuntu, desde la raíz de Champ:

   ```bash
   bash tool/simulacion/preparar_sim.sh champ-sim
   ```

4. Abre Champ conectada al entorno simulado:

   ```bash
   bash tool/simulacion/champ_sim.sh
   ```

   Entra con `sim01@champ-sim.test`; para ver otra perspectiva, usa otra cuenta, como `sim03` (paseadora) o `sim05` (perro perdido).

## Probar en el emulador local (sin tocar Firebase)

```bash
npx firebase-tools emulators:exec --only auth,firestore --project demo-champ \
  "node tool/simulacion/sembrar_simulacion.mjs --emulador"
```
