// Solo usa Firebase Emulator Suite y un proyecto demo; nunca producción.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp, deleteApp } = require('firebase/app');
const {
  getFirestore, connectFirestoreEmulator, doc, collection, query, where,
  getDoc, getDocs, runTransaction, serverTimestamp, writeBatch, setDoc,
  updateDoc, deleteDoc, onSnapshot, terminate,
} = require('firebase/firestore');

const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Ejecuta este script con firebase emulators:exec --only firestore --project demo-champ');
const [hostname, puerto] = host.split(':');
assert(['127.0.0.1', 'localhost'].includes(hostname));
const apps = [];
function cuenta(uid) {
  const app = initializeApp({ projectId: 'demo-champ', apiKey: 'demo' }, uid ?? 'sin-sesion');
  const db = getFirestore(app);
  connectFirestoreEmulator(db, hostname, Number(puerto), uid ? { mockUserToken: { sub: uid } } : {});
  apps.push({ app, db });
  return db;
}
const ana = cuenta('ana');
const pedro = cuenta('pedro');
const tercero = cuenta('tercero');
const anonimo = cuenta();
const identidad = createHash('sha256').update(JSON.stringify(['ana', 'pedro'])).digest('hex');
const id = `usuarios_${identidad}`;
const chat = db => doc(db, 'chats', id);
const mensaje = (db, mid) => doc(db, 'chats', id, 'mensajes', mid);
const denegado = accion => assert.rejects(accion, e => e.code === 'permission-denied');
async function abrir(db) {
  await runTransaction(db, async tx => {
    const actual = await tx.get(chat(db));
    if (!actual.exists()) tx.set(chat(db), {
      participantes: ['ana', 'pedro'], fecha: serverTimestamp(),
      actualizada: serverTimestamp(), ultimoTexto: '',
    });
  });
}
async function enviar(db, uid, mid, texto) {
  const lote = writeBatch(db);
  lote.set(mensaje(db, mid), { remitenteId: uid, texto, fecha: serverTimestamp() });
  lote.update(chat(db), { ultimoTexto: texto, actualizada: serverTimestamp() });
  await lote.commit();
}
try {
  await Promise.all([abrir(ana), abrir(pedro)]);
  assert.equal((await getDocs(query(collection(ana, 'chats'), where('participantes', 'array-contains', 'ana')))).size, 1);
  assert.equal((await getDocs(query(collection(tercero, 'chats'), where('participantes', 'array-contains', 'tercero')))).size, 0);
  await denegado(() => getDoc(chat(tercero)));
  await denegado(() => getDoc(chat(anonimo)));
  let cancelar;
  const recibido = new Promise((resolve, reject) => {
    cancelar = onSnapshot(collection(pedro, 'chats', id, 'mensajes'), s => {
      if (s.docs.some(d => d.data().texto === 'Hola Pedro')) resolve();
    }, reject);
  });
  await enviar(ana, 'ana', 'uno', 'Hola Pedro');
  let temporizador;
  try {
    await Promise.race([recibido, new Promise((_, reject) => {
      temporizador = setTimeout(() => reject(new Error('Sin recepción en tiempo real')), 10000);
    })]);
  } finally { clearTimeout(temporizador); cancelar(); }
  await enviar(pedro, 'pedro', 'dos', 'Hola Ana');
  assert.equal((await getDocs(collection(ana, 'chats', id, 'mensajes'))).size, 2);
  await denegado(() => enviar(ana, 'pedro', 'suplantado', 'Falso'));
  await denegado(() => enviar(tercero, 'tercero', 'intruso', 'Falso'));
  await denegado(() => enviar(ana, 'ana', 'vacio', ''));
  await denegado(() => enviar(ana, 'ana', 'largo', 'a'.repeat(4001)));
  await denegado(() => updateDoc(chat(ana), { participantes: ['ana', 'tercero'] }));
  await denegado(() => updateDoc(mensaje(ana, 'uno'), { texto: 'Editado' }));
  await denegado(() => deleteDoc(mensaje(ana, 'uno')));
  await denegado(() => setDoc(doc(tercero, 'chats', 'suplantado'), {
    participantes: ['ana', 'pedro'], fecha: serverTimestamp(),
    actualizada: serverTimestamp(), ultimoTexto: '',
  }));
  console.log('Chat: envío y recepción entre dos cuentas, reapertura y 10 rechazos de seguridad verificados.');
} finally {
  await Promise.all(apps.map(async ({ app, db }) => { await terminate(db); await deleteApp(app); }));
}
