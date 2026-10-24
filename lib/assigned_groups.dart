import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignedGroupNames extends StatelessWidget {
  const AssignedGroupNames({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('grupos')
            .where('catequistaIds', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('No se pudieron cargar los grupos');
          }
          if (!snapshot.hasData) return const Text('Cargando grupos…');
          final names =
              snapshot.data!.docs
                  .map(
                    (doc) =>
                        (doc.data()['nombre'] ?? 'Grupo sin nombre').toString(),
                  )
                  .toList()
                ..sort();
          return Text(
            names.isEmpty ? 'No asignado' : names.join(', '),
            style: const TextStyle(fontWeight: FontWeight.w700),
          );
        },
      );
}
