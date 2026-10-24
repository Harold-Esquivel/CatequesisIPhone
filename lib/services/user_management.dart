import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserManagementService {
  UserManagementService(this.firestore);
  final FirebaseFirestore firestore;

  Future<void> createCatequista({
    required String nombre,
    required String usuario,
    required String password,
    required String telefono,
    required String cedula,
  }) async {
    final login = usuario.trim().toLowerCase();
    final email = login.contains('@') ? login : '$login@catequista.com';
    if (nombre.trim().isEmpty ||
        !RegExp(r'^[a-z0-9._+-]+@catequista\.com$').hasMatch(email)) {
      throw ArgumentError(
        'Escribe el nombre y un usuario válido (sin espacios).',
      );
    }
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }
    // A separate Auth instance keeps the superior signed in while creating the account.
    final app = await Firebase.initializeApp(
      name: 'crear-catequista-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    User? created;
    var profileSaved = false;
    try {
      created = (await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).user!;
      await firestore.collection('catequistas').doc(created.uid).set({
        'nombre': nombre.trim(),
        'email': email,
        'telefono': telefono.trim(),
        'cedula': cedula.trim(),
        'rol': 'Catequista',
        'grupo': 'No asignado',
        'grupos': <String>[],
        'activo': true,
        'eliminado': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      profileSaved = true;
    } catch (_) {
      if (!profileSaved && created != null) {
        try {
          await created.delete();
        } catch (_) {
          /* Original error remains actionable. */
        }
      }
      rethrow;
    } finally {
      try {
        await auth.signOut();
      } finally {
        await app.delete();
      }
    }
  }

  Future<void> updateCatequista({
    required String id,
    required String nombre,
    required String telefono,
    required String cedula,
  }) async {
    if (nombre.trim().isEmpty) throw ArgumentError('El nombre es obligatorio.');
    await _changeCatequista(id, {
      'nombre': nombre.trim(),
      'telefono': telefono.trim(),
      'cedula': cedula.trim(),
    }, remove: false);
  }

  Future<void> deleteCatequista(String id) => _changeCatequista(id, {
    'activo': false,
    'eliminado': true,
    'grupos': <String>[],
    'grupo': 'No asignado',
    'grupoNombre': FieldValue.delete(),
    'deletedAt': FieldValue.serverTimestamp(),
  }, remove: true);

  Future<void> _changeCatequista(
    String id,
    Map<String, dynamic> changes, {
    required bool remove,
  }) async {
    final profileRef = firestore.collection('catequistas').doc(id);
    final profile = (await profileRef.get()).data();
    if (profile == null) throw StateError('No se encontró el catequista.');
    final groups = await firestore.collection('grupos').get();
    final batch = firestore.batch();
    batch.update(profileRef, {
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final group in groups.docs) {
      final data = group.data();
      final ids = <String>{
        ...List<String>.from(data['catequistaIds'] ?? []),
        if ((data['catequistaId'] ?? '').toString().isNotEmpty)
          data['catequistaId'].toString(),
      };
      if (!ids.contains(id)) continue;
      final people =
          (data['catequistas'] is List
                  ? data['catequistas'] as List
                  : data['catequista'] is Map
                  ? [data['catequista']]
                  : <dynamic>[])
              .whereType<Map>()
              .map((p) => Map<String, dynamic>.from(p))
              .toList();
      if (remove) {
        ids.remove(id);
        people.removeWhere((p) => p['uid'] == id);
      } else {
        for (final person in people) {
          if (person['uid'] == id) person['nombre'] = changes['nombre'];
        }
      }
      batch.update(group.reference, {
        'catequistaIds': ids.toList(),
        'catequistas': people,
        'catequistaId': people.isEmpty ? '' : people.first['uid'],
        'catequista': people.isEmpty ? FieldValue.delete() : people.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateAlumno({
    required String id,
    required String nombre,
    required String telefonoApoderado,
  }) async {
    if (nombre.trim().isEmpty) throw ArgumentError('El nombre es obligatorio.');
    await firestore.collection('alumnos').doc(id).update({
      'nombre': nombre.trim(),
      'telefonoApoderado': telefonoApoderado.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAlumno(String id) async {
    final ref = firestore.collection('alumnos').doc(id);
    await firestore.runTransaction((transaction) async {
      final student = (await transaction.get(ref)).data();
      if (student == null) return;
      final groupId = (student['grupoId'] ?? '').toString();
      final groupRef = groupId.isEmpty
          ? null
          : firestore.collection('grupos').doc(groupId);
      final group = groupRef == null ? null : await transaction.get(groupRef);
      transaction.update(ref, {
        'eliminado': true,
        'activo': false,
        'grupoAnteriorId': groupId,
        'grupoId': '',
        'grupoNombre': '',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      if (group != null && group.exists) {
        transaction.update(group.reference, {
          'alumnos': FieldValue.arrayRemove([id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

String userManagementError(Object error) {
  if (error is ArgumentError) return error.message.toString();
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ese usuario ya existe. Elige otro nombre de usuario.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet y vuelve a intentar.';
      case 'operation-not-allowed':
        return 'La creación de cuentas necesita habilitar el acceso con contraseña.';
    }
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'No tienes permiso para administrar usuarios. Vuelve a entrar como superior.';
  }
  return 'No se pudo guardar el cambio. Revisa tu conexión e intenta de nuevo.';
}
