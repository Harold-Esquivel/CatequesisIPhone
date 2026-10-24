import 'package:catequesis/services/user_management.dart';
import 'package:catequesis/services/groups.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editar catequista actualiza su nombre en todos los grupos', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('catequistas').doc('ana').set({
      'nombre': 'Ana',
      'email': 'ana@catequista.com',
    });
    for (final id in ['uno', 'dos']) {
      await db.collection('grupos').doc(id).set({
        'nombre': id,
        'catequistaIds': ['ana'],
        'catequistas': [
          {'uid': 'ana', 'nombre': 'Ana', 'email': 'ana@catequista.com'},
        ],
        'catequistaId': 'ana',
        'catequista': {'uid': 'ana', 'nombre': 'Ana'},
      });
    }
    await UserManagementService(db).updateCatequista(
      id: 'ana',
      nombre: 'Ana María',
      telefono: '971000000',
      cedula: '12345678',
    );
    expect(
      (await db.collection('catequistas').doc('ana').get())['nombre'],
      'Ana María',
    );
    for (final group in (await db.collection('grupos').get()).docs) {
      expect(group['catequistas'][0]['nombre'], 'Ana María');
      expect(group['catequista']['nombre'], 'Ana María');
    }
    await UserManagementService(db).deleteCatequista('ana');
    final profile = await db.collection('catequistas').doc('ana').get();
    expect(profile['eliminado'], true);
    expect(profile['activo'], false);
    for (final group in (await db.collection('grupos').get()).docs) {
      expect(group['catequistaIds'], isEmpty);
      expect(group['catequistas'], isEmpty);
      expect(group.data()['catequista'], isNull);
    }
  });
  test(
    'eliminar catequista conserva a los demás y los reportes históricos',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('catequistas').doc('ana').set({'nombre': 'Ana'});
      await db.collection('grupos').doc('grupo').set({
        'catequistaIds': ['ana', 'luis'],
        'catequistas': [
          {'uid': 'ana', 'nombre': 'Ana'},
          {'uid': 'luis', 'nombre': 'Luis'},
        ],
        'catequistaId': 'ana',
        'catequista': {'uid': 'ana', 'nombre': 'Ana'},
      });
      await db.collection('reportesClase').doc('historial').set({
        'createdBy': 'ana',
        'grupoId': 'grupo',
      });
      await UserManagementService(db).deleteCatequista('ana');
      final group = await db.collection('grupos').doc('grupo').get();
      expect(group['catequistaIds'], ['luis']);
      expect(group['catequista']['nombre'], 'Luis');
      expect(
        (await db.collection('reportesClase').doc('historial').get()).exists,
        true,
      );
    },
  );
  test(
    'editar y eliminar alumno actualiza el grupo y conserva su asistencia',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('grupos').doc('grupo').set({
        'alumnos': ['alumno', 'otro'],
      });
      final ref = db.collection('alumnos').doc('alumno');
      await ref.set({'nombre': 'Pedro', 'grupoId': 'grupo', 'asistencia': 3});
      await ref.collection('asistencias').doc('2026-10-23').set({
        'presente': true,
      });
      final service = UserManagementService(db);
      await service.updateAlumno(
        id: 'alumno',
        nombre: 'Pedro José',
        telefonoApoderado: '971135384',
      );
      expect((await ref.get())['asistencia'], 3);
      expect((await ref.get())['nombre'], 'Pedro José');
      await service.deleteAlumno('alumno');
      expect((await ref.get())['eliminado'], true);
      expect(
        (await db
                .collection('alumnos')
                .where('grupoId', isEqualTo: 'grupo')
                .get())
            .docs,
        isEmpty,
      );
      expect((await db.collection('grupos').doc('grupo').get())['alumnos'], [
        'otro',
      ]);
      expect(
        (await ref.collection('asistencias').doc('2026-10-23').get()).exists,
        true,
      );
    },
  );
  test(
    'renombrar grupo actualiza los nombres guardados de alumnos y catequistas',
    () async {
      final db = FakeFirebaseFirestore();
      await db.collection('catequistas').doc('ana').set({'nombre': 'Ana'});
      await db.collection('grupos').doc('grupo').set({
        'nombre': 'Nombre antiguo',
        'catequistaIds': ['ana'],
        'alumnos': ['alumno'],
      });
      await db.collection('alumnos').doc('alumno').set({
        'nombre': 'Pedro',
        'grupoId': 'grupo',
        'grupoNombre': 'Nombre antiguo',
      });
      await GroupService(db).save(
        groupDoc: await db.collection('grupos').doc('grupo').get(),
        nombre: 'Confirmación',
        sala: '1',
        descripcion: '',
        catequistaIds: ['ana'],
      );
      expect(
        (await db.collection('alumnos').doc('alumno').get())['grupoNombre'],
        'Confirmación',
      );
      expect(
        (await db.collection('catequistas').doc('ana').get())['grupoNombre'],
        'Confirmación',
      );
    },
  );
}
