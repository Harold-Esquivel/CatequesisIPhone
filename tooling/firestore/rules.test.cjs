const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, collection, query, where, limit, getDocs, writeBatch } = require('firebase/firestore');
let env;
let catequista;
let superior;
const today = '2026-10-23';
const report = (uid = 'ana', grupoId = 'grupo-1', fechaId = today) => ({
  grupoId, fechaId, createdBy: uid, fotos: {pizarra: {url: 'https://example.com/pizarra.jpg'}},
});
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-catequesis', firestore: {
    host: '127.0.0.1', port: 8087,
    rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
  }});
  catequista = env.authenticatedContext('ana', {email: 'ana@catequista.com'}).firestore();
  superior = env.authenticatedContext('superior', {email: 'directora@superior.com'}).firestore();
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'grupos/grupo-1'), {nombre: 'Comunión', catequistaIds: ['ana']});
    await setDoc(doc(db, 'grupos/grupo-2'), {nombre: 'Otro grupo', catequistaIds: ['otra']});
    await setDoc(doc(db, 'configuracion/diasAsistencia'), {dias: [today]});
  });
});
test('consulta del grupo vacío funciona aunque get del documento inexistente sea denegado', async () => {
  await assertFails(getDoc(doc(catequista, `reportesClase/grupo-1_${today}`)));
  const reports = query(collection(catequista, 'reportesClase'), where('grupoId', '==', 'grupo-1'),
    where('fechaId', '==', today), limit(1));
  assert.equal((await assertSucceeds(getDocs(reports))).empty, true);
  const batch = writeBatch(catequista);
  batch.set(doc(catequista, `reportesClase/grupo-1_${today}`), report());
  batch.set(doc(collection(catequista, 'notificacionesSuperiores')), report());
  await assertSucceeds(batch.commit());
  assert.equal((await assertSucceeds(getDocs(reports))).size, 1);
  await assertSucceeds(setDoc(doc(catequista, `reportesClase/grupo-1_${today}`), report()));
});
test('catequista asignado puede crear incidencia y notificación en el mismo lote', async () => {
  const batch = writeBatch(catequista);
  batch.set(doc(collection(catequista, 'incidencias')), {...report(), asunto: 'Incidencia de prueba'});
  batch.set(doc(collection(catequista, 'notificacionesSuperiores')), report());
  await assertSucceeds(batch.commit());
});
test('sin asignación, sin clase o con autor ajeno no se guardan reportes ni incidencias', async () => {
  for (const data of [report('ana', 'grupo-2'), report('ana', 'grupo-1', '2026-10-24'), report('otra')]) {
    for (const name of ['reportesClase', 'incidencias', 'notificacionesSuperiores']) {
      await assertFails(setDoc(doc(collection(catequista, name)), data));
    }
  }
});
test('no se pueden consultar fotos de otro grupo ni acceder sin sesión', async () => {
  await assertFails(getDocs(query(collection(catequista, 'reportesClase'), where('grupoId', '==', 'grupo-2'))));
  await assertFails(getDocs(collection(catequista, 'reportesClase')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'reportesClase')));
});
test('superior puede guardar reportes e incidencias propios y crear grupo sin catequista', async () => {
  await assertSucceeds(setDoc(doc(superior, 'grupos/sin-asignar'), {nombre: 'Nuevo', catequistaIds: [], catequistaId: ''}));
  await assertSucceeds(setDoc(doc(superior, 'reportesClase/manual'), {createdBy: 'superior', fotos: {}}));
  await assertSucceeds(setDoc(doc(superior, 'incidencias/manual'), {createdBy: 'superior', asunto: 'Nota'}));
  await assertFails(setDoc(doc(superior, 'reportesClase/autor-ajeno'), {createdBy: 'ana', fotos: {}}));
});
test('solo el superior puede crear perfiles y modificar o eliminar integrantes', async () => {
  await assertSucceeds(setDoc(doc(superior, 'catequistas/nuevo'), {nombre: 'Nuevo', activo: true, eliminado: false}));
  await assertFails(setDoc(doc(catequista, 'catequistas/nuevo'), {nombre: 'Otro'}));
  await assertSucceeds(setDoc(doc(superior, 'alumnos/pedro'), {nombre: 'Pedro', grupoId: 'grupo-1', asistencia: 0}));
  await assertFails(setDoc(doc(catequista, 'alumnos/pedro'), {nombre: 'Cambiado'}, {merge: true}));
  await assertFails(setDoc(doc(catequista, 'alumnos/pedro'), {eliminado: true}, {merge: true}));
  await assertSucceeds(setDoc(doc(superior, 'alumnos/pedro'), {eliminado: true, grupoId: ''}, {merge: true}));
});
test('catequista eliminado pierde acceso con su sesión previa y no puede reactivarse', async () => {
  await assertSucceeds(setDoc(doc(superior, 'catequistas/ana'), {nombre: 'Ana', grupo: 'grupo-1', activo: false, eliminado: true}));
  await assertSucceeds(getDoc(doc(catequista, 'catequistas/ana')));
  await assertFails(getDocs(query(collection(catequista, 'grupos'), where('catequistaIds', 'array-contains', 'ana'))));
  await assertFails(getDoc(doc(catequista, 'configuracion/diasAsistencia')));
  await assertFails(setDoc(doc(catequista, 'reportesClase/nuevo'), report()));
  await assertFails(setDoc(doc(catequista, 'catequistas/ana'), {activo: true, eliminado: false}, {merge: true}));
  await assertFails(setDoc(doc(catequista, 'notificacionesSuperiores/nuevo'), report()));
});
