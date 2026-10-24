import 'package:catequesis/services/groups.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'crear grupo sin catequista y asignarlo o desasignarlo después',
    () async {
      final db = FakeFirebaseFirestore();
      final service = GroupService(db);
      await service.save(
        groupDoc: null,
        nombre: '  Primera comunión  ',
        sala: '',
        descripcion: '',
        catequistaIds: [],
      );
      DocumentSnapshot<Map<String, dynamic>> group =
          (await db.collection('grupos').get()).docs.single;
      final groupId = group.id;
      expect(group['nombre'], 'Primera comunión');
      expect(group['sala'], 'Sin sala');
      expect(group['catequistaIds'], isEmpty);
      expect(group['catequistaId'], '');
      expect(group.data()?['catequista'], isNull);
      expect(group['alumnos'], isEmpty);

      await db.collection('catequistas').doc('ana').set({
        'nombre': 'Ana',
        'email': 'ana@catequista.com',
      });
      await service.save(
        groupDoc: group,
        nombre: 'Primera comunión',
        sala: '1',
        descripcion: '',
        catequistaIds: ['ana', 'ana', ''],
      );
      group = await db.collection('grupos').doc(groupId).get();
      expect(group['catequistaIds'], ['ana']);
      expect(group['catequista']['nombre'], 'Ana');
      expect((await db.collection('catequistas').doc('ana').get())['grupos'], [
        groupId,
      ]);

      await db.collection('grupos').doc(groupId).update({
        'alumnos': ['alumno-1'],
      });
      group = await db.collection('grupos').doc(groupId).get();
      await service.save(
        groupDoc: group,
        nombre: 'Primera comunión',
        sala: '1',
        descripcion: '',
        catequistaIds: [],
      );
      group = await db.collection('grupos').doc(groupId).get();
      expect(group['catequistaIds'], isEmpty);
      expect(group['catequistas'], isEmpty);
      expect(group['catequistaId'], '');
      expect(group.data()?['catequista'], isNull);
      expect(group['alumnos'], ['alumno-1']);
      final catequista = await db.collection('catequistas').doc('ana').get();
      expect(catequista['grupos'], isEmpty);
      expect(catequista['grupo'], 'No asignado');
    },
  );
}
