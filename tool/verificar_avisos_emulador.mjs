// Solo emulador local y proyecto demo-champ; nunca datos de produccion.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { initializeApp, deleteApp } = require('firebase/app');
const { getFirestore, connectFirestoreEmulator, doc, collection, getDoc, getDocs,
  setDoc, updateDoc, deleteDoc, serverTimestamp, terminate } = require('firebase/firestore');
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Ejecutar con firebase emulators:exec --only firestore --project demo-champ');
const [hostname, port] = host.split(':');
assert(['127.0.0.1', 'localhost'].includes(hostname));
const apps = [];
function cuenta(uid) {
  const app = initializeApp({ projectId: 'demo-champ', apiKey: 'demo' }, `avisos-${uid ?? 'anonimo'}`);
  const db = getFirestore(app);
  connectFirestoreEmulator(db, hostname, Number(port), uid ? { mockUserToken: { sub: uid } } : {});
  apps.push({ app, db }); return db;
}
const ana = cuenta('ana'), jaime = cuenta('jaime'), anonimo = cuenta();
const id = `aviso-${Date.now()}`;
const aviso = db => doc(db, 'avisos_perros', id);
const foto = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jCr0AAAAASUVORK5CYII=';
const base = () => ({ autorUid: 'ana', autorNombre: 'Ana', tipo: 'perdido', nombre: 'Toby', raza: 'Mestizo',
  zona: 'Santiago', lugar: 'Parque central', descripcion: 'Collar azul', fechaVistaMs: Date.now() - 3600000,
  chip: 'si', chipUltimos: '1234', foto, resuelto: false, notaCierre: '',
  creado: serverTimestamp(), actualizado: serverTimestamp() });
let rechazos = 0;
async function denegado(accion) {
  await assert.rejects(accion, e => e.code === 'permission-denied'); rechazos++;
}
let n = 0;
const crearMal = cambios => setDoc(doc(ana, 'avisos_perros', `${id}-mal-${++n}`), { ...base(), ...cambios });
try {
  await denegado(() => getDoc(aviso(anonimo)));
  await denegado(() => setDoc(aviso(jaime), base()));
  await setDoc(aviso(ana), base());
  assert.equal((await getDoc(aviso(jaime))).data().chipUltimos, '1234');
  assert.equal((await getDoc(aviso(jaime))).data().foto, foto);
  await denegado(() => crearMal({ numeroChip: '123456789012345' }));
  await denegado(() => crearMal({ chipUltimos: '123456789012345' }));
  await denegado(() => crearMal({ chip: 'no', chipUltimos: '1234' }));
  await denegado(() => crearMal({ chip: 'desconocido', chipUltimos: '1234' }));
  await denegado(() => crearMal({ foto: 'iVBORw0KGgo' + 'A'.repeat(120000) }));
  await denegado(() => crearMal({ foto: 'esto no es una foto' }));
  await denegado(() => crearMal({ fechaVistaMs: Date.now() + 86400000 }));
  await denegado(() => crearMal({ zona: '' }));
  await denegado(() => crearMal({ resuelto: true, notaCierre: 'Cerrado al crear' }));
  await denegado(() => updateDoc(aviso(jaime), { descripcion: 'Cambio ajeno', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(aviso(jaime), { resuelto: true, notaCierre: 'Ajeno', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(aviso(ana), { autorUid: 'jaime', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(aviso(ana), { creado: serverTimestamp(), actualizado: serverTimestamp() }));
  await updateDoc(aviso(ana), { nombre: 'Toby actualizado', lugar: 'Entrada del parque', actualizado: serverTimestamp() });
  assert.equal((await getDoc(aviso(jaime))).data().lugar, 'Entrada del parque');
  await denegado(() => updateDoc(aviso(ana), { resuelto: true, notaCierre: '', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(aviso(ana), { resuelto: true, notaCierre: 'Vuelto', descripcion: 'Cambiar al cerrar', actualizado: serverTimestamp() }));
  await updateDoc(aviso(ana), { resuelto: true, notaCierre: 'Ya volvio a casa', actualizado: serverTimestamp() });
  assert.equal((await getDoc(aviso(jaime))).data().resuelto, true);
  await denegado(() => updateDoc(aviso(ana), { descripcion: 'Cambio despues del cierre', actualizado: serverTimestamp() }));
  await denegado(() => updateDoc(aviso(ana), { resuelto: false, notaCierre: '', actualizado: serverTimestamp() }));
  await denegado(() => deleteDoc(aviso(ana)));
  await denegado(() => getDocs(collection(anonimo, 'avisos_perros')));
  assert((await getDocs(collection(jaime, 'avisos_perros'))).size >= 1);
  console.log(`OK: avisos compartidos, foto, microchip parcial, edicion, cierre y ${rechazos} rechazos de permisos.`);
} finally {
  await Promise.all(apps.map(async ({ app, db }) => { await terminate(db); await deleteApp(app); }));
}
