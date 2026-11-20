// Cuatro identidades ficticias, solo emulador local.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const {initializeApp,deleteApp}=require('firebase/app');
const {getFirestore,connectFirestoreEmulator,doc,setDoc,getDoc,getDocs,collection,query,where,updateDoc,serverTimestamp,runTransaction,terminate}=require('firebase/firestore');
const host=process.env.FIRESTORE_EMULATOR_HOST;
assert(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host),'Solo emulador local');
const [hostname,port]=host.split(':');
const apps=[];
function cuenta(uid){const app=initializeApp({projectId:'demo-champ',apiKey:'demo'},`reservas-${uid}`);const db=getFirestore(app);connectFirestoreEmulator(db,hostname,Number(port),{mockUserToken:{sub:uid}});apps.push({app,db});return db;}
const p=cuenta('paseador'),a=cuenta('cliente-a'),b=cuenta('cliente-b'),c=cuenta('ajeno');
const inicio=Math.ceil((Date.now()+86400000)/1800000)*1800000;
const prefix=`prueba-${Date.now()}`;
const ref=(db,id)=>doc(db,'reservas_paseos',id);
const perfil={nombre:'Paseador',zona:'Parque',descripcion:'Paseos tranquilos',condiciones:'Sin cobros durante la prueba',disponibilidad:'Coordinar por chat',duracion:120,activo:true,revision:1,actualizado:serverTimestamp()};
function datos(uid){return {clienteUid:uid,clienteNombre:uid,paseadorUid:'paseador',paseadorNombre:'Paseador',perro:'Luna',zona:'Entrada parque',inicioMs:inicio,bloqueInicial:inicio/1800000,duracion:120,condiciones:perfil.condiciones,perfilRevision:1,nota:'',estado:'solicitada',creado:serverTimestamp(),actualizado:serverTimestamp()};}
let rechazos=0;
async function denegado(fn){await assert.rejects(fn,e=>e.code==='permission-denied');rechazos++;}
async function aceptar(id){return runTransaction(p,async tx=>{const r=await tx.get(ref(p,id));const d=r.data();const refs=Array.from({length:d.duracion/30},(_,i)=>doc(p,'bloques_paseadores',`paseador_${d.bloqueInicial+i}`));for(const r of refs){if((await tx.get(r)).exists())throw Error('Horario ocupado');}refs.forEach((r,i)=>tx.set(r,{reservaId:id,paseadorUid:'paseador',bloque:d.bloqueInicial+i}));tx.update(ref(p,id),{estado:'aceptada',actualizado:serverTimestamp()});});}
try{
 await setDoc(doc(p,'paseadores_champ','paseador'),perfil);
 await denegado(()=>setDoc(doc(c,'paseadores_champ','paseador'),{...perfil,revision:2}));
 await denegado(()=>updateDoc(doc(p,'paseadores_champ','paseador'),{revision:1,actualizado:serverTimestamp()}));
 await setDoc(ref(a,`${prefix}-a`),datos('cliente-a'));
 await setDoc(ref(b,`${prefix}-b`),datos('cliente-b'));
 await denegado(()=>getDoc(ref(c,`${prefix}-a`)));
 await denegado(()=>getDocs(collection(c,'reservas_paseos')));
 assert.equal((await getDocs(query(collection(a,'reservas_paseos'),where('clienteUid','==','cliente-a')))).size,1);
 await denegado(()=>updateDoc(ref(a,`${prefix}-a`),{estado:'aceptada',actualizado:serverTimestamp()}));
 await denegado(()=>updateDoc(ref(p,`${prefix}-a`),{estado:'aceptada',actualizado:serverTimestamp()}));
 await denegado(()=>setDoc(ref(a,`${prefix}-cobro`),{...datos('cliente-a'),pagado:true}));
 const race=await Promise.allSettled([aceptar(`${prefix}-a`),aceptar(`${prefix}-b`)]);
 assert.equal(race.filter(r=>r.status==='fulfilled').length,1,'Una sola reserva puede ocupar los cuatro bloques');
 const ganador=race[0].status==='fulfilled'?'a':'b', cliente=ganador==='a'?a:b;
 const id=`${prefix}-${ganador}`;
 await denegado(()=>updateDoc(ref(p,id),{estado:'enCurso',actualizado:serverTimestamp()}));
 await denegado(()=>updateDoc(ref(c,id),{estado:'cancelada',actualizado:serverTimestamp()}));
 await runTransaction(cliente,async tx=>{const s=await tx.get(ref(cliente,id));const d=s.data();for(let i=0;i<4;i++)tx.delete(doc(cliente,'bloques_paseadores',`paseador_${d.bloqueInicial+i}`));tx.update(ref(cliente,id),{estado:'cancelada',actualizado:serverTimestamp()});});
 await aceptar(`${prefix}-${ganador==='a'?'b':'a'}`);
 await denegado(()=>updateDoc(ref(p,id),{estado:'aceptada',actualizado:serverTimestamp()}));
 console.log(`OK: cuatro usuarios, privacidad, carrera de reservas, liberacion de horario y ${rechazos} rechazos.`);
}finally{await Promise.all(apps.map(async({app,db})=>{await terminate(db);await deleteApp(app);}));}
