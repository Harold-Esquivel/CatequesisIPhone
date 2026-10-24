import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  GroupService(this.firestore);
  final FirebaseFirestore firestore;

  Future<void> save({
    required DocumentSnapshot? groupDoc,
    required String nombre,
    required String sala,
    required String descripcion,
    required List<String> catequistaIds,
  }) async {
    final cleanNombre = nombre.trim();
    if (cleanNombre.isEmpty) {
      throw ArgumentError('El nombre del grupo es obligatorio');
    }
    final groupRef =
        groupDoc?.reference ?? firestore.collection('grupos').doc();
    final oldData = groupDoc?.data() as Map<String, dynamic>? ?? {};
    final oldCatequistaIds = <String>{
      if (oldData['catequistaIds'] is List)
        ...List<String>.from(oldData['catequistaIds']),
      if ((oldData['catequistaId'] ?? '').toString().trim().isNotEmpty)
        (oldData['catequistaId'] ?? '').toString().trim(),
    };
    final selectedCatequistaIds = catequistaIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final catequistasInfo = <Map<String, dynamic>>[];

    for (final catequistaId in selectedCatequistaIds) {
      final catequistaDoc = await firestore
          .collection('catequistas')
          .doc(catequistaId)
          .get();
      final catequistaData = catequistaDoc.data() ?? {};
      if (!catequistaDoc.exists ||
          catequistaData['eliminado'] == true ||
          catequistaData['activo'] == false) {
        throw StateError('El catequista seleccionado ya no está disponible.');
      }

      catequistasInfo.add({
        'uid': catequistaId,
        'nombre': catequistaData['nombre'] ?? 'Catequista',
        'email': catequistaData['email'] ?? '',
      });
    }

    final firstCatequista = catequistasInfo.isNotEmpty
        ? catequistasInfo.first
        : <String, dynamic>{};
    final saveData = <String, dynamic>{
      'id': groupRef.id,
      'nombre': cleanNombre,
      'sala': sala.trim().isEmpty ? 'Sin sala' : sala.trim(),
      'descripcion': descripcion.trim(),
      'catequistaIds': selectedCatequistaIds,
      'catequistas': catequistasInfo,
      'catequistaId': firstCatequista['uid'] ?? '',
      'catequista': catequistasInfo.isEmpty
          ? FieldValue.delete()
          : firstCatequista,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (groupDoc == null) {
      saveData['alumnos'] = <String>[];
      saveData['createdAt'] = FieldValue.serverTimestamp();
    }

    final students = groupDoc == null
        ? null
        : await firestore
              .collection('alumnos')
              .where('grupoId', isEqualTo: groupRef.id)
              .get();
    final batch = firestore.batch();
    for (final student
        in students?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
      batch.update(student.reference, {
        'grupoNombre': cleanNombre,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(groupRef, saveData, SetOptions(merge: true));

    final removedCatequistaIds = oldCatequistaIds.difference(
      selectedCatequistaIds.toSet(),
    );

    for (final catequistaId in removedCatequistaIds) {
      batch.set(
        firestore.collection('catequistas').doc(catequistaId),
        {
          'grupos': FieldValue.arrayRemove([groupRef.id]),
          'grupo': 'No asignado',
          'grupoNombre': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final catequistaId in selectedCatequistaIds) {
      batch.set(
        firestore.collection('catequistas').doc(catequistaId),
        {
          'grupos': FieldValue.arrayUnion([groupRef.id]),
          'grupo': groupRef.id,
          'grupoNombre': cleanNombre,
          'sala': saveData['sala'],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
