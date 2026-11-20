import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const {initializeApp,deleteApp}=require('firebase/app');
const {getFirestore,connectFirestoreEmulator,doc,setDoc,getDoc,getDocs,collection,updateDoc,serverTimestamp,terminate}=require('firebase/firestore');
const host=process.env.FIRESTORE_EMULATOR_HOST;
assert(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host));
const [hostname,port]=host.split(':');
const cuentas=['piloto-a','piloto-b','piloto-c','piloto-d'].map(uid=>{
 const app=initializeApp({projectId:'demo-champ',apiKey:'demo'},`ficha-${uid}`);
 const db=getFirestore(app);connectFirestoreEmulator(db,hostname,Number(port),{mockUserToken:{sub:uid}});return {uid,app,db};
});
let rechazos=0;
async function no(fn){await assert.rejects(fn,e=>e.code==='permission-denied');rechazos++;}
try{
 for(const {uid,db} of cuentas){
   assert.equal((await getDoc(doc(db,'fichas_privadas_champ',uid))).exists(),false);
   await setDoc(doc(db,'fichas_privadas_champ',uid),{contenido:JSON.stringify({miPerro:{nombre:`Perro de ${uid}`},decisiones:{},matches:[]}),revision:1,actualizado:serverTimestamp()});
 }
 for(const {uid,db} of cuentas){
   assert.equal(JSON.parse((await getDoc(doc(db,'fichas_privadas_champ',uid))).data().contenido).miPerro.nombre,`Perro de ${uid}`);
   for(const otro of cuentas.filter(c=>c.uid!==uid)){
     await no(()=>getDoc(doc(db,'fichas_privadas_champ',otro.uid)));
     await no(()=>updateDoc(doc(db,'fichas_privadas_champ',otro.uid),{contenido:'{}',revision:2,actualizado:serverTimestamp()}));
   }
   await no(()=>getDocs(collection(db,'fichas_privadas_champ')));
   await no(()=>updateDoc(doc(db,'fichas_privadas_champ',uid),{revision:1,actualizado:serverTimestamp()}));
   await updateDoc(doc(db,'fichas_privadas_champ',uid),{revision:2,actualizado:serverTimestamp()});
 }
 console.log(`OK: cuatro fichas propias, sin listado publico, revisiones y ${rechazos} rechazos.`);
}finally{await Promise.all(cuentas.map(async({app,db})=>{await terminate(db);await deleteApp(app);}));}
