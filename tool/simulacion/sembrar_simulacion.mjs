// Siembra un entorno SEÑUELO de Champ con cuentas y datos ficticios.
//
// Nunca apunta al proyecto real: se niega a usar champ-dog-app. Úsalo con un
// proyecto Firebase separado (p. ej. champ-sim) o con el emulador local.
//
//   Proyecto señuelo:
//     node tool/simulacion/sembrar_simulacion.mjs --config ~/.config/Champ/firebase.sim.json
//   Emulador (pruebas):
//     npx firebase-tools emulators:exec --only auth,firestore --project demo-champ \
//       "node tool/simulacion/sembrar_simulacion.mjs --emulador"
//
// Es idempotente: puede ejecutarse varias veces sin duplicar datos.
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { DATOS } from './datos_simulacion.mjs';

const require = createRequire(import.meta.url);
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, updateProfile, signOut } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, writeBatch,
  serverTimestamp, terminate, runTransaction } = require('firebase/firestore');

const PROYECTO_REAL = 'champ-dog-app';
const args = process.argv.slice(2);
const emulador = args.includes('--emulador');
const iConfig = args.indexOf('--config');
let config;
if (emulador) {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Ejecuta dentro de "firebase emulators:exec --only auth,firestore".');
  }
  config = { apiKey: 'demo', projectId: 'demo-champ', appId: 'demo' };
} else if (iConfig >= 0 && args[iConfig + 1]) {
  const leido = JSON.parse(readFileSync(args[iConfig + 1], 'utf8'));
  // Acepta el formato de la app (FIREBASE_*) o el de Firebase (apiKey, ...).
  config = leido.FIREBASE_API_KEY ? {
    apiKey: leido.FIREBASE_API_KEY, appId: leido.FIREBASE_APP_ID,
    messagingSenderId: leido.FIREBASE_MESSAGING_SENDER_ID, projectId: leido.FIREBASE_PROJECT_ID,
    authDomain: leido.FIREBASE_AUTH_DOMAIN,
  } : leido;
} else {
  console.error('Uso: --config <firebase.sim.json> | --emulador');
  process.exit(64);
}
if (config.projectId === PROYECTO_REAL) {
  console.error(`ALTO: ${PROYECTO_REAL} es el proyecto real. Los datos falsos van solo en el señuelo.`);
  process.exit(2);
}
const CLAVE = process.env.CHAMP_SIM_PASSWORD || 'ChampSim-2026!';
const HORA = 1800000;
const ahora = Date.now();
const bloqueFuturo = (dias, hora) => {
  const d = new Date(ahora + dias * 86400000);
  d.setHours(hora, 0, 0, 0);
  return Math.floor(d.getTime() / HORA) * HORA;
};

// Una app Firebase por cuenta, para escribir con la identidad de cada usuario.
const sesiones = new Map();
async function sesion(u) {
  if (sesiones.has(u.correo)) return sesiones.get(u.correo);
  const app = initializeApp(config, `sim-${u.correo}`);
  const auth = getAuth(app);
  const db = getFirestore(app);
  if (emulador) {
    connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
    const [h, p] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    connectFirestoreEmulator(db, h, Number(p));
  }
  let cred;
  try {
    cred = await signInWithEmailAndPassword(auth, u.correo, CLAVE);
  } catch (e) {
    if (!['auth/user-not-found', 'auth/invalid-credential', 'auth/invalid-login-credentials'].includes(e.code)) throw e;
    cred = await createUserWithEmailAndPassword(auth, u.correo, CLAVE);
  }
  if (cred.user.displayName !== u.nombre) await updateProfile(cred.user, { displayName: u.nombre });
  const s = { app, auth, db, uid: cred.user.uid, nombre: u.nombre, usuario: u };
  sesiones.set(u.correo, s);
  return s;
}
const existe = async (s, ruta) => (await getDoc(doc(s.db, ruta))).exists();
const cuenta = { creados: 0, existentes: 0 };
async function crearSiFalta(s, ruta, datos) {
  if (await existe(s, ruta)) { cuenta.existentes++; return false; }
  await setDoc(doc(s.db, ruta), datos);
  cuenta.creados++;
  return true;
}

try {
  // 1. Cuentas
  const usuarios = [];
  for (const u of DATOS.usuarios) usuarios.push(await sesion(u));
  const u = (n) => usuarios[n - 1];
  console.log(`Cuentas listas: ${usuarios.length}`);

  // 1b. Directorio de contactos del chat (UID → nombre visible)
  for (const s of usuarios) {
    await crearSiFalta(s, `perfiles_publicos/${s.uid}`, { nombre: s.nombre, actualizado: serverTimestamp() });
  }

  // 2. Fichas privadas de Cruces (un perro por cuenta)
  for (const s of usuarios) {
    const p = s.usuario.perro;
    const estado = {
      miPerro: { id: `sim-perro-${s.usuario.n}`, nombre: p.nombre, raza: p.raza, sexo: p.sexo,
        edadMeses: p.edadMeses, ciudad: s.usuario.ciudad, responsable: s.nombre,
        descripcion: p.descripcion, foto: null, imagenUrl: null, interesDemo: false },
      decisiones: {}, matches: [],
    };
    await crearSiFalta(s, `fichas_privadas_champ/${s.uid}`, {
      contenido: JSON.stringify(estado), revision: 1, actualizado: serverTimestamp(),
    });
  }

  // 3. Paseadores
  for (const pz of DATOS.paseadores) {
    const s = u(pz.usuario);
    await crearSiFalta(s, `paseadores_champ/${s.uid}`, {
      nombre: s.nombre, zona: pz.zona, descripcion: pz.descripcion, condiciones: pz.condiciones,
      disponibilidad: pz.disponibilidad, duracion: pz.duracion, activo: true, revision: 1,
      actualizado: serverTimestamp(),
    });
  }

  // 4. Reservas de paseo (algunas aceptadas, con sus bloques de agenda)
  for (const [i, r] of DATOS.reservas.entries()) {
    const cliente = u(r.cliente);
    const paseador = u(r.paseador);
    const id = `sim-reserva-${String(i + 1).padStart(2, '0')}`;
    const perfil = (await getDoc(doc(cliente.db, `paseadores_champ/${paseador.uid}`))).data();
    const inicioMs = bloqueFuturo(r.dias, r.hora);
    const nueva = await crearSiFalta(cliente, `reservas_paseos/${id}`, {
      clienteUid: cliente.uid, clienteNombre: cliente.nombre, paseadorUid: paseador.uid,
      paseadorNombre: perfil.nombre, perro: cliente.usuario.perro.nombre, zona: r.zona,
      inicioMs, bloqueInicial: inicioMs / HORA, duracion: perfil.duracion,
      condiciones: perfil.condiciones, perfilRevision: perfil.revision, nota: r.nota,
      estado: 'solicitada', creado: serverTimestamp(), actualizado: serverTimestamp(),
    });
    if (nueva && r.estado !== 'solicitada') {
      const lote = writeBatch(paseador.db);
      if (r.estado === 'aceptada') {
        for (let b = 0; b < perfil.duracion / 30; b++) {
          const bloque = inicioMs / HORA + b;
          lote.set(doc(paseador.db, `bloques_paseadores/${paseador.uid}_${bloque}`),
            { reservaId: id, paseadorUid: paseador.uid, bloque });
        }
      }
      lote.update(doc(paseador.db, `reservas_paseos/${id}`), { estado: r.estado, actualizado: serverTimestamp() });
      await lote.commit();
    }
  }

  // 5. Avisos de perros perdidos y encontrados
  for (const [i, a] of DATOS.avisos.entries()) {
    const s = u(a.usuario);
    await crearSiFalta(s, `avisos_perros/sim-aviso-${String(i + 1).padStart(2, '0')}`, {
      autorUid: s.uid, autorNombre: s.nombre, tipo: a.tipo, nombre: a.nombre, raza: a.raza,
      zona: a.zona, lugar: a.lugar, descripcion: a.descripcion,
      fechaVistaMs: ahora - a.horasAtras * 3600000, chip: a.chip, chipUltimos: a.chipUltimos ?? '',
      foto: '', resuelto: false, notaCierre: '', creado: serverTimestamp(), actualizado: serverTimestamp(),
    });
  }

  // 6. Muro de la comunidad
  for (const [i, m] of DATOS.muro.entries()) {
    const s = u(m.usuario);
    await crearSiFalta(s, `muro_champ/sim-muro-${String(i + 1).padStart(2, '0')}`, {
      autorUid: s.uid, autorNombre: s.nombre, texto: m.texto, creado: serverTimestamp(),
    });
  }

  // 7. Eventos, inscripciones y mensajes del evento
  for (const [i, e] of DATOS.eventos.entries()) {
    const autor = u(e.autor);
    const ruta = `eventos_champ/sim-evento-${String(i + 1).padStart(2, '0')}`;
    await crearSiFalta(autor, ruta, {
      autorUid: autor.uid, autorNombre: autor.nombre, titulo: e.titulo, descripcion: e.descripcion,
      lugar: e.lugar, zona: e.zona, inicioMs: bloqueFuturo(e.dias, e.hora), duracion: e.duracion,
      cupos: e.cupos, tipo: e.tipo, participantes: { [autor.uid]: autor.nombre }, cancelado: false,
      creado: serverTimestamp(), actualizado: serverTimestamp(),
    });
    for (const n of e.inscritos) {
      const s = u(n);
      await runTransaction(s.db, async (tx) => {
        const ref = doc(s.db, ruta);
        const actual = (await tx.get(ref)).data();
        if (actual.participantes[s.uid]) return;
        tx.update(ref, { participantes: { ...actual.participantes, [s.uid]: s.nombre }, actualizado: serverTimestamp() });
      });
    }
    for (const [j, m] of e.mensajes.entries()) {
      const s = u(m.usuario);
      await crearSiFalta(s, `${ruta}/mensajes/sim-${String(j + 1).padStart(2, '0')}`, {
        uid: s.uid, nombre: s.nombre, texto: m.texto, fecha: serverTimestamp(),
      });
    }
  }

  // 8. Chats privados entre cuentas (mismo ID estable que usa la app)
  for (const c of DATOS.chats) {
    const [a, b] = [u(c.entre[0]), u(c.entre[1])];
    const participantes = [a.uid, b.uid].sort();
    const id = 'usuarios_' + createHash('sha256').update(JSON.stringify(participantes)).digest('hex');
    await crearSiFalta(a, `chats/${id}`, {
      participantes, fecha: serverTimestamp(), actualizada: serverTimestamp(), ultimoTexto: '',
    });
    for (const [j, m] of c.mensajes.entries()) {
      const s = m.de === 0 ? a : b;
      const ruta = `chats/${id}/mensajes/sim-${String(j + 1).padStart(2, '0')}`;
      if (await existe(s, ruta)) { cuenta.existentes++; continue; }
      const lote = writeBatch(s.db);
      lote.set(doc(s.db, ruta), { remitenteId: s.uid, texto: m.texto, fecha: serverTimestamp() });
      lote.update(doc(s.db, `chats/${id}`), { actualizada: serverTimestamp(), ultimoTexto: m.texto });
      await lote.commit();
      cuenta.creados++;
    }
  }

  // Registro de cuentas creadas, para revisar o borrar después.
  const registro = usuarios.map((s) => ({ correo: s.usuario.correo, nombre: s.nombre, uid: s.uid }));
  const salida = process.env.CHAMP_SIM_REGISTRO || 'simulacion_cuentas.json';
  writeFileSync(salida, JSON.stringify({ projectId: config.projectId, cuentas: registro }, null, 2));
  const perros = DATOS.usuarios.length + DATOS.avisos.length;
  console.log(`OK proyecto ${config.projectId}: ${usuarios.length} cuentas, ${perros} perros ` +
    `(${DATOS.usuarios.length} fichas + ${DATOS.avisos.length} avisos), ${DATOS.paseadores.length} paseadores, ` +
    `${DATOS.reservas.length} reservas, ${DATOS.muro.length} publicaciones, ${DATOS.eventos.length} eventos, ` +
    `${DATOS.chats.length} chats. Documentos nuevos: ${cuenta.creados}, ya existentes: ${cuenta.existentes}.`);
  console.log(`Cuentas guardadas en ${salida}. Contraseña común: la de CHAMP_SIM_PASSWORD (o la predeterminada).`);
} finally {
  for (const s of sesiones.values()) {
    await signOut(s.auth).catch(() => {});
    await terminate(s.db).catch(() => {});
    await deleteApp(s.app).catch(() => {});
  }
}
