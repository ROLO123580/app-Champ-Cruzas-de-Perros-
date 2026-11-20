// Solo Firebase Emulator Suite, proyecto demo-champ. Nunca produccion.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp, deleteApp } = require('firebase/app');
const { getFirestore, connectFirestoreEmulator, doc, collection, getDoc, getDocs,
  setDoc, updateDoc, runTransaction, serverTimestamp, terminate } = require('firebase/firestore');
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Ejecutar con FIRESTORE_EMULATOR_HOST o firebase emulators:exec.');
const [hostname, puerto] = host.split(':');
assert(['127.0.0.1', 'localhost'].includes(hostname));
const apps = [];
function cuenta(uid) {
  const app = initializeApp({ projectId: 'demo-champ', apiKey: 'demo' }, `eventos-${uid ?? 'anonimo'}`);
  const db = getFirestore(app);
  connectFirestoreEmulator(db, hostname, Number(puerto), uid ? { mockUserToken: { sub: uid } } : {});
  apps.push({ app, db }); return db;
}
const ana = cuenta('ana'), jaime = cuenta('jaime'), pedro = cuenta('pedro'), anonimo = cuenta();
const id = `evento-${Date.now()}`;
const evento = db => doc(db, 'eventos_champ', id);
const mensaje = (db, mid) => doc(db, 'eventos_champ', id, 'mensajes', mid);
let rechazos = 0;
const denegado = async accion => {
  await assert.rejects(accion, e => e.code === 'permission-denied');
  rechazos++;
};
const base = () => ({ autorUid: 'ana', autorNombre: 'Ana', titulo: 'Encuentro en el parque',
  descripcion: 'Nos vemos en la entrada.', lugar: 'Parque de prueba', zona: 'Centro',
  inicioMs: Date.now() + 86400000, duracion: 60, cupos: 2, tipo: 'evento',
  participantes: { ana: 'Ana' }, cancelado: false,
  creado: serverTimestamp(), actualizado: serverTimestamp() });
async function inscribir(db, uid) {
  await runTransaction(db, async tx => {
    const actual = (await tx.get(evento(db))).data();
    tx.update(evento(db), { participantes: { ...actual.participantes, [uid]: uid }, actualizado: serverTimestamp() });
  });
}
async function salir(db, uid) {
  await runTransaction(db, async tx => {
    const miembros = { ...(await tx.get(evento(db))).data().participantes };
    delete miembros[uid];
    tx.update(evento(db), { participantes: miembros, actualizado: serverTimestamp() });
  });
}
async function enviar(db, uid, mid, texto) {
  const miembros = (await getDoc(evento(db))).data().participantes;
  await setDoc(mensaje(db, mid), { uid, nombre: miembros[uid] ?? uid, texto, fecha: serverTimestamp() });
}
try {
  await denegado(() => getDoc(evento(anonimo)));
  await denegado(() => setDoc(evento(pedro), base()));
  await setDoc(evento(ana), base());
  assert.equal((await getDoc(evento(jaime))).data().lugar, 'Parque de prueba');
  await denegado(() => setDoc(doc(ana, 'eventos_champ', `${id}-pasado`), { ...base(), inicioMs: Date.now() - 10000 }));
  await denegado(() => setDoc(doc(ana, 'eventos_champ', `${id}-preinscritos`), { ...base(), participantes: { ana: 'Ana', jaime: 'jaime' } }));
  await denegado(() => setDoc(mensaje(jaime, 'intruso'), { uid: 'jaime', nombre: 'jaime', texto: 'Hola', fecha: serverTimestamp() }));
  await denegado(() => getDocs(collection(jaime, 'eventos_champ', id, 'mensajes')));
  const carrera = await Promise.allSettled([inscribir(jaime, 'jaime'), inscribir(pedro, 'pedro')]);
  assert.equal(carrera.filter(r => r.status === 'fulfilled').length, 1, 'Un solo cupo debe asignarse una sola vez');
  let actual = (await getDoc(evento(ana))).data();
  assert.equal(Object.keys(actual.participantes).length, 2);
  const ganador = 'jaime' in actual.participantes ? ['jaime', jaime] : ['pedro', pedro];
  const perdedor = ganador[0] === 'jaime' ? ['pedro', pedro] : ['jaime', jaime];
  await enviar(ganador[1], ganador[0], 'saludo', 'Nos vemos en la entrada');
  assert.equal((await getDocs(collection(ana, 'eventos_champ', id, 'mensajes'))).size, 1);
  await denegado(() => setDoc(mensaje(ganador[1], 'suplantado'), {
    uid: 'ana', nombre: 'Ana', texto: 'Falso', fecha: serverTimestamp() }));
  await denegado(() => enviar(ganador[1], ganador[0], 'vacio', ''));
  await denegado(() => updateDoc(evento(ganador[1]), { titulo: 'Otro evento', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(evento(ana), { participantes: { ...actual.participantes, extra: 'Intruso' }, actualizado: serverTimestamp() }));
  await salir(ganador[1], ganador[0]);
  await denegado(() => getDocs(collection(ganador[1], 'eventos_champ', id, 'mensajes')));
  await denegado(() => enviar(ganador[1], ganador[0], 'tras-salir', 'No debo poder enviar'));
  await inscribir(perdedor[1], perdedor[0]);
  await denegado(() => updateDoc(evento(perdedor[1]), { participantes: { [perdedor[0]]: perdedor[0] }, actualizado: serverTimestamp() }));
  await updateDoc(evento(ana), { cancelado: true, actualizado: serverTimestamp() });
  await denegado(() => enviar(perdedor[1], perdedor[0], 'cancelado', 'Evento cerrado'));
  await denegado(() => updateDoc(evento(ana), { cancelado: false, actualizado: serverTimestamp() }));
  const publicacion = doc(ana, 'muro_champ', id);
  await setDoc(publicacion, { autorUid: 'ana', autorNombre: 'Ana', texto: 'Bienvenidos al parque', creado: serverTimestamp() });
  assert.equal((await getDoc(doc(jaime, 'muro_champ', id))).data().texto, 'Bienvenidos al parque');
  await denegado(() => setDoc(doc(jaime, 'muro_champ', `${id}-falso`), {
    autorUid: 'ana', autorNombre: 'Ana', texto: 'Falso', creado: serverTimestamp() }));
  await denegado(() => getDoc(doc(anonimo, 'muro_champ', id)));
  console.log(`OK: muro, evento, carrera por ultimo cupo, chat, revocacion y ${rechazos} rechazos de permisos.`);
} finally {
  await Promise.all(apps.map(async ({ app, db }) => { await terminate(db); await deleteApp(app); }));
}
