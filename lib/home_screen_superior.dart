import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'settings_screen.dart';

class HomeSuperiorScreen extends StatefulWidget {
  const HomeSuperiorScreen({super.key});

  @override
  State<HomeSuperiorScreen> createState() => _HomeSuperiorScreenState();
}

class _HomeSuperiorScreenState extends State<HomeSuperiorScreen> {
  static const String _cloudinaryCloudName = 'izwqrc3a';
  static const String _cloudinaryUploadPreset = 'reportes_unsigned';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  int _selectedModuleIndex = 0;
  int _selectedReportMonth = DateTime.now().month;
  int _selectedReportYear = DateTime.now().year;
  String? _selectedReportGroupId;
  String _selectedReportGroupName = '';
  String? _selectedReportDateId;
  int _selectedReportView = 0;
  bool _savingIncidence = false;
  bool _savingClassReport = false;
  String? _selectedIncidenceAlumnoId;
  XFile? _incidencePhoto;
  final TextEditingController _incidenceSubjectController =
      TextEditingController();
  final Map<String, XFile> _classReportPhotos = {};

  final List<String> _modules = [
    'Mi perfil',
    'Grupos',
    'Lecciones',
    'Clases',
    'Reportes',
  ];
  final List<IconData> _moduleIcons = [
    Icons.person,
    Icons.groups,
    Icons.menu_book_outlined,
    Icons.event_available_outlined,
    Icons.assessment_outlined,
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _incidenceSubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(child: _buildTopBar()),
      ),
      body: IndexedStack(
        index: _selectedModuleIndex,
        children: [
          _buildPerfilModule(),
          _buildGruposModule(),
          _buildLeccionesModule(),
          _buildAsistenciaModule(),
          _buildReportesModule(),
        ],
      ),
      bottomNavigationBar: _buildSuperiorBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFFF5F3F2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, size: 22, color: Color(0xFF1E2A44)),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (value == 'help') {
                _showSnackBar('Ayuda pendiente de configurar');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: _buildTopMenuItem(
                  icon: Icons.tune,
                  label: 'Ajustes',
                  color: const Color(0xFF1E2A44),
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: _buildTopMenuItem(
                  icon: Icons.help_outline,
                  label: 'Ayuda',
                  color: const Color(0xFF1E2A44),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: _buildTopMenuItem(
                  icon: Icons.logout,
                  label: 'Salir',
                  color: const Color(0xFFB83357),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'ESCJ Catequesis',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildNotificationButton(),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE5E1DE),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.grey[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildTopMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salir'),
        content: const Text('Deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notificacionesSuperiores')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: _showNotificationsSheet,
              icon: const Icon(
                Icons.notifications_none,
                color: Color(0xFF1E2A44),
              ),
              tooltip: 'Notificaciones',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB83357),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notificacionesSuperiores')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = <QueryDocumentSnapshot>[
                ...(snapshot.data?.docs ?? <QueryDocumentSnapshot>[]),
              ];
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final createdA = dataA['createdAt'];
                final createdB = dataB['createdAt'];
                if (createdA is Timestamp && createdB is Timestamp) {
                  return createdB.compareTo(createdA);
                }
                return 0;
              });
              final visibleDocs = docs.take(30).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notificaciones',
                            style: TextStyle(
                              color: Color(0xFF1E2A44),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: visibleDocs.isEmpty
                              ? null
                              : () => _markNotificationsRead(visibleDocs),
                          child: const Text('Marcar leidas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: visibleDocs.isEmpty
                          ? _buildInlineEmptyState(
                              icon: Icons.notifications_none,
                              title: 'Sin notificaciones',
                              message:
                                  'Los avisos de reportes e incidencias apareceran aqui.',
                            )
                          : ListView.builder(
                              itemCount: visibleDocs.length,
                              itemBuilder: (context, index) {
                                final doc = visibleDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final read = data['read'] == true;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    read
                                        ? Icons.notifications_none
                                        : Icons.notifications_active,
                                    color: read
                                        ? Colors.grey[500]
                                        : const Color(0xFFB83357),
                                  ),
                                  title: Text(
                                    (data['title'] ?? 'Notificacion')
                                        .toString(),
                                    style: TextStyle(
                                      fontWeight: read
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                          (data['message'] ?? '').toString(),
                                          _formatDateTime(data['createdAt']),
                                        ]
                                        .where((item) => item.trim().isNotEmpty)
                                        .join(' | '),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _markNotificationsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.set(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Widget _buildSuperiorBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F2),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 6,
      ),
      child: Row(
        children: List.generate(_modules.length, (index) {
          final selected = _selectedModuleIndex == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedModuleIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFB83357) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFB83357)
                          : const Color(0xFFE5E1DE),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _moduleIcons[index],
                        size: 20,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF1E2A44),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _modules[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF1E2A44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGruposModule() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Grupos de catequesis',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showGroupDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Crear grupo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('grupos')
                .orderBy('nombre')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final grupos = snapshot.data?.docs ?? [];

              if (grupos.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Aun no hay grupos',
                  message:
                      'Crea un grupo, asigna un catequista y agrega alumnos.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: grupos.length,
                itemBuilder: (context, index) => _buildGroupCard(grupos[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(DocumentSnapshot groupDoc) {
    final data = groupDoc.data() as Map<String, dynamic>? ?? {};
    final nombre = (data['nombre'] ?? 'Grupo sin nombre').toString();
    final sala = (data['sala'] ?? 'Sin sala').toString();
    final descripcion = (data['descripcion'] ?? '').toString();
    final catequistas = _readCatequistasFromGroup(data);
    final catequistaNombre = catequistas.isEmpty
        ? 'Sin catequista'
        : catequistas
              .map(
                (catequista) =>
                    (catequista['nombre'] ?? 'Catequista').toString(),
              )
              .join(', ');
    final alumnos = data['alumnos'] is List
        ? List<String>.from(data['alumnos'])
        : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Sala: $sala | Catequista: $catequistaNombre'),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5E1DE),
          child: Text(
            alumnos.length.toString(),
            style: const TextStyle(
              color: Color(0xFF1E2A44),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          if (descripcion.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(descripcion),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showGroupDialog(groupDoc: groupDoc),
                icon: const Icon(Icons.edit),
                label: const Text('Editar grupo'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAlumnoDialog(groupId: groupDoc.id, groupName: nombre),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Agregar alumno'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showMoveAlumnoDialog(
                  fromGroupId: groupDoc.id,
                  fromGroupName: nombre,
                ),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Mover alumno'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('alumnos')
                .where('grupoId', isEqualTo: groupDoc.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                );
              }

              final alumnosDocs = snapshot.data?.docs ?? [];

              if (alumnosDocs.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Este grupo todavia no tiene alumnos.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return Column(
                children: alumnosDocs.map((doc) {
                  final alumno = doc.data() as Map<String, dynamic>? ?? {};
                  final alumnoNombre = (alumno['nombre'] ?? 'Alumno')
                      .toString();
                  final telefonoApoderado =
                      (alumno['telefonoApoderado'] ?? 'N/A').toString();
                  final asistencia = alumno['asistencia'] ?? 0;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(alumnoNombre),
                    subtitle: Text(
                      'UID: ${doc.id} | Apoderado: $telefonoApoderado',
                    ),
                    trailing: Text('$asistencia asist.'),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _readCatequistasFromGroup(
    Map<String, dynamic> data,
  ) {
    final rawCatequistas = data['catequistas'];

    if (rawCatequistas is List) {
      return rawCatequistas
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final legacyCatequista = data['catequista'];
    if (legacyCatequista is Map && legacyCatequista.isNotEmpty) {
      return [Map<String, dynamic>.from(legacyCatequista)];
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> _showGroupDialog({DocumentSnapshot? groupDoc}) async {
    final data = groupDoc?.data() as Map<String, dynamic>? ?? {};
    final nombreController = TextEditingController(
      text: (data['nombre'] ?? '').toString(),
    );
    final salaController = TextEditingController(
      text: (data['sala'] ?? '').toString(),
    );
    final descripcionController = TextEditingController(
      text: (data['descripcion'] ?? '').toString(),
    );
    final selectedCatequistaIds = <String>{
      if (data['catequistaIds'] is List)
        ...List<String>.from(data['catequistaIds']),
      if ((data['catequistaId'] ?? '').toString().trim().isNotEmpty)
        (data['catequistaId'] ?? '').toString().trim(),
    };

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(groupDoc == null ? 'Crear grupo' : 'Editar grupo'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del grupo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: salaController,
                        decoration: const InputDecoration(labelText: 'Sala'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descripcionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('catequistas')
                            .orderBy('nombre')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final catequistas = snapshot.data?.docs ?? [];

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (catequistas.isEmpty) {
                            return Text(
                              'No hay catequistas registrados aun.',
                              style: TextStyle(color: Colors.grey[600]),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Catequistas asignados',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...catequistas.map((doc) {
                                final catequista =
                                    doc.data() as Map<String, dynamic>? ?? {};
                                final nombre = (catequista['nombre'] ?? doc.id)
                                    .toString();
                                final selected = selectedCatequistaIds.contains(
                                  doc.id,
                                );

                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: selected,
                                  title: Text(nombre),
                                  subtitle: Text(doc.id),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedCatequistaIds.add(doc.id);
                                      } else {
                                        selectedCatequistaIds.remove(doc.id);
                                      }
                                    });
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final saved = await _saveGroup(
                        groupDoc: groupDoc,
                        nombre: nombreController.text,
                        sala: salaController.text,
                        descripcion: descripcionController.text,
                        catequistaIds: selectedCatequistaIds.toList(),
                      );
                      if (saved && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      _disposeDialogControllers([
        nombreController,
        salaController,
        descripcionController,
      ]);
    }
  }

  Future<bool> _saveGroup({
    required DocumentSnapshot? groupDoc,
    required String nombre,
    required String sala,
    required String descripcion,
    required List<String> catequistaIds,
  }) async {
    final cleanNombre = nombre.trim();

    if (cleanNombre.isEmpty) {
      _showSnackBar('El nombre del grupo es obligatorio');
      return false;
    }

    try {
      final groupRef =
          groupDoc?.reference ?? _firestore.collection('grupos').doc();
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
        final catequistaDoc = await _firestore
            .collection('catequistas')
            .doc(catequistaId)
            .get();
        final catequistaData = catequistaDoc.data() ?? {};

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
        'catequista': firstCatequista,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (groupDoc == null) {
        saveData['alumnos'] = <String>[];
        saveData['createdAt'] = FieldValue.serverTimestamp();
      }

      final batch = _firestore.batch();
      batch.set(groupRef, saveData, SetOptions(merge: true));

      final removedCatequistaIds = oldCatequistaIds.difference(
        selectedCatequistaIds.toSet(),
      );

      for (final catequistaId in removedCatequistaIds) {
        batch.set(
          _firestore.collection('catequistas').doc(catequistaId),
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
          _firestore.collection('catequistas').doc(catequistaId),
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
      _showSnackBar('Grupo guardado');
      return true;
    } catch (e) {
      _showSnackBar('No se pudo guardar el grupo: $e');
      return false;
    }
  }

  Future<void> _showAlumnoDialog({
    required String groupId,
    required String groupName,
  }) async {
    final nombreController = TextEditingController();
    final telefonoApoderadoController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Agregar alumno a $groupName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoApoderadoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono de apoderado',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'El alumno no tendra cuenta. Firebase generara un UID unico para guardar su asistencia.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final saved = await _saveAlumno(
                  groupId: groupId,
                  groupName: groupName,
                  nombre: nombreController.text,
                  telefonoApoderado: telefonoApoderadoController.text,
                );
                if (saved && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Crear alumno'),
            ),
          ],
        ),
      );
    } finally {
      _disposeDialogControllers([
        nombreController,
        telefonoApoderadoController,
      ]);
    }
  }

  void _disposeDialogControllers(List<TextEditingController> controllers) {
    // El dialogo se anima al cerrarse; esperar evita desechar un controlador
    // mientras el TextField aun sigue conectado al arbol de widgets.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  Future<bool> _saveAlumno({
    required String groupId,
    required String groupName,
    required String nombre,
    required String telefonoApoderado,
  }) async {
    final cleanNombre = nombre.trim();

    if (cleanNombre.isEmpty) {
      _showSnackBar('El nombre del alumno es obligatorio');
      return false;
    }

    final alumnoRef = _firestore.collection('alumnos').doc();
    final groupRef = _firestore.collection('grupos').doc(groupId);
    final batch = _firestore.batch();

    batch.set(alumnoRef, {
      'uid': alumnoRef.id,
      'nombre': cleanNombre,
      'telefonoApoderado': telefonoApoderado.trim().isEmpty
          ? 'N/A'
          : telefonoApoderado.trim(),
      'grupoId': groupId,
      'grupoNombre': groupName,
      'asistencia': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(groupRef, {
      'alumnos': FieldValue.arrayUnion([alumnoRef.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      _showSnackBar('Alumno creado con UID ${alumnoRef.id}');
      return true;
    } catch (e) {
      _showSnackBar('No se pudo crear el alumno: $e');
      return false;
    }
  }

  Future<void> _showMoveAlumnoDialog({
    required String fromGroupId,
    required String fromGroupName,
  }) async {
    String? selectedAlumnoId;
    String? selectedTargetGroupId;
    final dataFuture = Future.wait([
      _firestore
          .collection('alumnos')
          .where('grupoId', isEqualTo: fromGroupId)
          .get(),
      _firestore.collection('grupos').orderBy('nombre').get(),
    ]);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Mover alumno de $fromGroupName'),
              content: FutureBuilder<List<QuerySnapshot>>(
                future: dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 96,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final alumnos = [...(snapshot.data?[0].docs ?? [])];
                  alumnos.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    return (dataA['nombre'] ?? '').toString().compareTo(
                      (dataB['nombre'] ?? '').toString(),
                    );
                  });
                  final targetGroups = [
                    ...(snapshot.data?[1].docs ?? []),
                  ].where((doc) => doc.id != fromGroupId).toList();

                  if (alumnos.isEmpty) {
                    return const Text(
                      'Este grupo no tiene alumnos para mover.',
                    );
                  }

                  if (targetGroups.isEmpty) {
                    return const Text('No hay otro grupo disponible.');
                  }

                  return SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedAlumnoId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Alumno',
                            border: OutlineInputBorder(),
                          ),
                          items: alumnos.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                (data['nombre'] ?? 'Alumno').toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAlumnoId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTargetGroupId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Grupo destino',
                            border: OutlineInputBorder(),
                          ),
                          items: targetGroups.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                (data['nombre'] ?? 'Grupo sin nombre')
                                    .toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTargetGroupId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final moved = await _moveAlumnoToGroup(
                      alumnoId: selectedAlumnoId,
                      fromGroupId: fromGroupId,
                      targetGroupId: selectedTargetGroupId,
                    );
                    if (moved && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Mover'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _moveAlumnoToGroup({
    required String? alumnoId,
    required String fromGroupId,
    required String? targetGroupId,
  }) async {
    if (alumnoId == null || alumnoId.trim().isEmpty) {
      _showSnackBar('Elige un alumno');
      return false;
    }

    if (targetGroupId == null || targetGroupId.trim().isEmpty) {
      _showSnackBar('Elige el grupo destino');
      return false;
    }

    if (fromGroupId == targetGroupId) {
      _showSnackBar('El grupo destino debe ser diferente');
      return false;
    }

    try {
      final alumnoRef = _firestore.collection('alumnos').doc(alumnoId);
      final targetGroupRef = _firestore.collection('grupos').doc(targetGroupId);
      final alumnoDoc = await alumnoRef.get();
      final targetGroupDoc = await targetGroupRef.get();

      if (!alumnoDoc.exists || !targetGroupDoc.exists) {
        _showSnackBar('No se encontro el alumno o el grupo destino');
        return false;
      }

      final alumnoData = alumnoDoc.data() ?? <String, dynamic>{};
      final currentGroupId = (alumnoData['grupoId'] ?? fromGroupId).toString();
      final targetGroupData = targetGroupDoc.data() ?? <String, dynamic>{};
      final targetGroupName = (targetGroupData['nombre'] ?? 'Grupo sin nombre')
          .toString();
      final batch = _firestore.batch();

      batch.update(alumnoRef, {
        'grupoId': targetGroupId,
        'grupoNombre': targetGroupName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        _firestore.collection('grupos').doc(currentGroupId),
        {
          'alumnos': FieldValue.arrayRemove([alumnoId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(targetGroupRef, {
        'alumnos': FieldValue.arrayUnion([alumnoId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      _showSnackBar('Alumno movido a $targetGroupName');
      return true;
    } catch (e) {
      _showSnackBar('No se pudo mover el alumno: $e');
      return false;
    }
  }

  Widget _buildReportesModule() {
    final groupId = _selectedReportGroupId;
    if (groupId == null) {
      return _buildSuperiorReportGroupsView();
    }

    final dateId = _selectedReportDateId;
    if (dateId != null) {
      return _buildSuperiorClassDayDetailView(
        groupId: groupId,
        groupName: _selectedReportGroupName,
        dateId: dateId,
      );
    }

    return _buildSuperiorGroupMonthReportView(
      groupId: groupId,
      groupName: _selectedReportGroupName,
    );
  }

  Widget _buildSuperiorReportGroupsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('grupos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = [...(snapshot.data?.docs ?? [])];
        groups.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          return (dataA['nombre'] ?? '').toString().compareTo(
            (dataB['nombre'] ?? '').toString(),
          );
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Reportes por grupo',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige un grupo para ver sus clases por mes y revisar asistencia, incidencias y reportes.',
              style: TextStyle(color: Colors.grey[700], height: 1.35),
            ),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              _buildInlineEmptyState(
                icon: Icons.groups_outlined,
                title: 'Aun no hay grupos',
                message: 'Crea grupos para consultar reportes por dia.',
              )
            else
              ...groups.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['nombre'] ?? 'Grupo sin nombre').toString();
                final sala = (data['sala'] ?? 'No asignada').toString();
                final alumnos = data['alumnos'] is List
                    ? List<String>.from(data['alumnos'])
                    : <String>[];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE7EA),
                      child: Icon(Icons.groups, color: Color(0xFFB83357)),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Sala: $sala | Alumnos: ${alumnos.length}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _selectedReportGroupId = doc.id;
                        _selectedReportGroupName = name;
                        _selectedReportDateId = null;
                      });
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildSuperiorGroupMonthReportView({
    required String groupId,
    required String groupName,
  }) {
    final monthId = _selectedReportMonthId();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildSuperiorReportBackHeader(
          title: groupName,
          subtitle:
              'Clases de ${_monthName(_selectedReportMonth)} $_selectedReportYear',
          onBack: () {
            setState(() {
              _selectedReportGroupId = null;
              _selectedReportGroupName = '';
              _selectedReportDateId = null;
            });
          },
        ),
        const SizedBox(height: 14),
        _buildReportMonthSelector(),
        const SizedBox(height: 14),
        FutureBuilder<List<_GroupClassDaySummary>>(
          future: _loadGroupClassDays(groupId: groupId, monthId: monthId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final days = snapshot.data ?? <_GroupClassDaySummary>[];
            if (days.isEmpty) {
              return _buildInlineEmptyState(
                icon: Icons.event_busy,
                title: 'Sin clases en este mes',
                message:
                    'No hay dias habilitados ni registros para este grupo en $monthId.',
              );
            }

            return Column(
              children: days.map((summary) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1.3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.event_note_outlined,
                      color: Color(0xFFB83357),
                    ),
                    title: Text(
                      _formatReadableDate(summary.dateId),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'Asistencias: ${summary.asistencias} | Incidencias: ${summary.incidencias} | Reportes: ${summary.reportes}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _selectedReportDateId = summary.dateId;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportMonthSelector() {
    final currentYear = DateTime.now().year;
    final years = [for (var year = 2024; year <= currentYear; year++) year];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedReportMonth,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mes',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(_monthName(month)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedReportMonth = value;
                    _selectedReportDateId = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: _selectedReportYear,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
                items: years
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedReportYear = value;
                    _selectedReportDateId = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperiorClassDayDetailView({
    required String groupId,
    required String groupName,
    required String dateId,
  }) {
    return FutureBuilder<_GroupClassDayDetail>(
      future: _loadClassDayDetail(groupId: groupId, dateId: dateId),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildSuperiorReportBackHeader(
              title: _formatReadableDate(dateId),
              subtitle: groupName,
              onBack: () {
                setState(() {
                  _selectedReportDateId = null;
                });
              },
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (detail == null)
              _buildInlineEmptyState(
                icon: Icons.info_outline,
                title: 'Sin informacion',
                message: 'No se pudo cargar el detalle de este dia.',
              )
            else ...[
              _buildAttendanceDetailCard(detail),
              const SizedBox(height: 12),
              _buildIncidencesDetailCard(detail.incidencias),
              const SizedBox(height: 12),
              _buildClassReportsDetailCard(detail.reportes),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSuperiorReportBackHeader({
    required String title,
    required String subtitle,
    required VoidCallback onBack,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E2A44),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetailCard(_GroupClassDayDetail detail) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asistencia',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${detail.presentAlumnos.length} de ${detail.totalAlumnos} alumnos presentes',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            if (detail.presentAlumnos.isEmpty)
              Text(
                'No hay asistencias registradas para este dia.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detail.presentAlumnos
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor: const Color(0xFFEFF7EF),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidencesDetailCard(List<Map<String, dynamic>> incidencias) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incidencias',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (incidencias.isEmpty)
              Text(
                'No hay incidencias registradas.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...incidencias.map(_buildIncidenceDetailTile),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenceDetailTile(Map<String, dynamic> data) {
    final asunto = (data['asunto'] ?? 'Sin asunto').toString();
    final alumnos = (data['alumnoNombre'] ?? '').toString();
    final fotoUrl = (data['fotoUrl'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E1DE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fotoUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fotoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPhotoFallbackIcon(),
              ),
            )
          else
            _buildPhotoFallbackIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asunto,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  alumnos.trim().isEmpty ? 'Sin alumnos vinculados' : alumnos,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(data['createdAt']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassReportsDetailCard(List<Map<String, dynamic>> reportes) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (reportes.isEmpty)
              Text(
                'No hay reporte de aula registrado.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...reportes.map(_buildClassReportDetailTile),
          ],
        ),
      ),
    );
  }

  Widget _buildClassReportDetailTile(Map<String, dynamic> data) {
    final fotosRaw = data['fotos'];
    final fotos = fotosRaw is Map ? Map<String, dynamic>.from(fotosRaw) : {};
    final catequista = (data['catequistaNombre'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E1DE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (catequista.trim().isNotEmpty)
            Text(
              'Subido por $catequista',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (catequista.trim().isNotEmpty) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildReportPhotoPreview('Pizarra', fotos['pizarra']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportPhotoPreview('Mesas', fotos['mesas']),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReportPhotoPreview('Limpio', fotos['limpio']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(data['updatedAt'] ?? data['createdAt']),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPhotoPreview(String label, dynamic photoData) {
    final photo = photoData is Map ? Map<String, dynamic>.from(photoData) : {};
    final url = (photo['url'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.trim().isEmpty
                ? _buildPhotoFallbackIcon()
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPhotoFallbackIcon(),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<List<_GroupClassDaySummary>> _loadGroupClassDays({
    required String groupId,
    required String monthId,
  }) async {
    final summaries = <String, _GroupClassDaySummary>{};
    _GroupClassDaySummary ensureSummary(String dateId) {
      return summaries.putIfAbsent(dateId, () => _GroupClassDaySummary(dateId));
    }

    final configDoc = await _firestore
        .collection('configuracion')
        .doc('diasAsistencia')
        .get();
    final configData = configDoc.data() ?? {};
    final dias = configData['dias'] is List
        ? List<String>.from(configData['dias'])
        : <String>[];
    for (final dia in dias.where((dia) => dia.startsWith('$monthId-'))) {
      ensureSummary(dia);
    }

    final alumnosSnapshot = await _firestore
        .collection('alumnos')
        .where('grupoId', isEqualTo: groupId)
        .get();
    final endDateId = _nextMonthStartId(monthId);
    for (final alumno in alumnosSnapshot.docs) {
      final asistencias = await alumno.reference
          .collection('asistencias')
          .where('fecha', isGreaterThanOrEqualTo: '$monthId-01')
          .where('fecha', isLessThan: endDateId)
          .get();
      for (final asistencia in asistencias.docs) {
        final data = asistencia.data();
        final fecha = (data['fecha'] ?? asistencia.id).toString();
        if (data['presente'] == true) {
          ensureSummary(fecha).asistencias++;
        }
      }
    }

    final reportes = await _firestore
        .collection('reportesClase')
        .where('grupoId', isEqualTo: groupId)
        .where('mesId', isEqualTo: monthId)
        .get();
    for (final reporte in reportes.docs) {
      final data = reporte.data();
      final fecha = (data['fechaId'] ?? '').toString();
      if (fecha.isNotEmpty) ensureSummary(fecha).reportes++;
    }

    final incidencias = await _firestore
        .collection('incidencias')
        .where('grupoId', isEqualTo: groupId)
        .where('mesId', isEqualTo: monthId)
        .get();
    for (final incidencia in incidencias.docs) {
      final data = incidencia.data();
      final fecha = (data['fechaId'] ?? '').toString();
      if (fecha.isNotEmpty) ensureSummary(fecha).incidencias++;
    }

    final days = summaries.values.toList()
      ..sort((a, b) => b.dateId.compareTo(a.dateId));
    return days;
  }

  Future<_GroupClassDayDetail> _loadClassDayDetail({
    required String groupId,
    required String dateId,
  }) async {
    final alumnosSnapshot = await _firestore
        .collection('alumnos')
        .where('grupoId', isEqualTo: groupId)
        .get();
    final presentAlumnos = <String>[];

    for (final alumno in alumnosSnapshot.docs) {
      final alumnoData = alumno.data();
      final asistenciaDoc = await alumno.reference
          .collection('asistencias')
          .doc(dateId)
          .get();
      final asistenciaData = asistenciaDoc.data() ?? {};
      if (asistenciaDoc.exists && asistenciaData['presente'] == true) {
        presentAlumnos.add(
          (alumnoData['nombre'] ?? 'Alumno sin nombre').toString(),
        );
      }
    }
    presentAlumnos.sort();

    final incidenciasSnapshot = await _firestore
        .collection('incidencias')
        .where('grupoId', isEqualTo: groupId)
        .where('fechaId', isEqualTo: dateId)
        .get();
    final reportesSnapshot = await _firestore
        .collection('reportesClase')
        .where('grupoId', isEqualTo: groupId)
        .where('fechaId', isEqualTo: dateId)
        .get();

    return _GroupClassDayDetail(
      totalAlumnos: alumnosSnapshot.docs.length,
      presentAlumnos: presentAlumnos,
      incidencias: incidenciasSnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList(),
      reportes: reportesSnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList(),
    );
  }

  String _selectedReportMonthId() {
    final month = _selectedReportMonth.toString().padLeft(2, '0');
    return '$_selectedReportYear-$month';
  }

  String _nextMonthStartId(String monthId) {
    final parts = monthId.split('-');
    if (parts.length != 2) return '$monthId-32';
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final next = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return _dateId(next);
  }

  // ignore: unused_element
  Widget _buildLegacyReportesModule() {
    if (_selectedReportView == 1) {
      return _buildIncidenciasReportView();
    }

    if (_selectedReportView == 2) {
      return _buildClassReportView();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Reportes',
          style: TextStyle(
            color: Color(0xFF1E2A44),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _buildReportMenuButton(
          title: 'Incidencias',
          icon: Icons.report_problem_outlined,
          onTap: () {
            setState(() {
              _selectedReportView = 1;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildReportMenuButton(
          title: 'Reporte de Clase',
          icon: Icons.photo_library_outlined,
          onTap: () {
            setState(() {
              _selectedReportView = 2;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReportMenuButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 74,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E2A44),
          elevation: 1.5,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildReportHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedReportView = 0;
            });
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E2A44),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidenciasReportView() {
    final now = DateTime.now();
    final monthId = _monthId(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildReportHeader(
          'Incidencias',
          'Crea una incidencia y revisa solo las registradas este mes.',
        ),
        const SizedBox(height: 16),
        _buildIncidenceFormCard(),
        const SizedBox(height: 18),
        Text(
          'Incidencias de ${_monthName(now.month)} ${now.year}',
          style: const TextStyle(
            color: Color(0xFF1E2A44),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('incidencias')
              .where('mesId', isEqualTo: monthId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = [...(snapshot.data?.docs ?? [])];
            docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final createdA = dataA['createdAt'];
              final createdB = dataB['createdAt'];
              if (createdA is Timestamp && createdB is Timestamp) {
                return createdB.compareTo(createdA);
              }
              return 0;
            });

            if (docs.isEmpty) {
              return _buildInlineEmptyState(
                icon: Icons.event_note_outlined,
                title: 'Sin incidencias este mes',
                message: 'Cuando guardes una incidencia aparecera aqui.',
              );
            }

            return Column(
              children: docs
                  .map((doc) => _buildIncidenceListCard(doc))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncidenceFormCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear incidencia',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('alumnos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (context, snapshot) {
                final alumnos = snapshot.data?.docs ?? [];
                final selectedId =
                    alumnos.any((doc) => doc.id == _selectedIncidenceAlumnoId)
                    ? _selectedIncidenceAlumnoId
                    : null;

                return DropdownButtonFormField<String?>(
                  key: ValueKey(selectedId),
                  initialValue: selectedId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Elegir un alumno (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin alumno especifico'),
                    ),
                    ...alumnos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = (data['nombre'] ?? 'Alumno').toString();
                      final grupo = (data['grupoNombre'] ?? '').toString();

                      return DropdownMenuItem<String?>(
                        value: doc.id,
                        child: Text(
                          grupo.trim().isEmpty ? nombre : '$nombre - $grupo',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedIncidenceAlumnoId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _incidenceSubjectController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Asunto de la Incidencia',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildPhotoPickerTile(
              title: 'Foto de la incidencia',
              subtitle: 'Opcional',
              photo: _incidencePhoto,
              onPick: () async {
                final photo = await _pickReportPhoto();
                if (photo == null || !mounted) return;
                setState(() {
                  _incidencePhoto = photo;
                });
              },
              onClear: _incidencePhoto == null
                  ? null
                  : () {
                      setState(() {
                        _incidencePhoto = null;
                      });
                    },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savingIncidence ? null : _saveIncidence,
                icon: _savingIncidence
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _savingIncidence ? 'Guardando...' : 'Guardar incidencia',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidenceListCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final asunto = (data['asunto'] ?? 'Sin asunto').toString();
    final alumnoNombre = (data['alumnoNombre'] ?? '').toString();
    final grupoNombre = (data['grupoNombre'] ?? '').toString();
    final fotoUrl = (data['fotoUrl'] ?? '').toString();
    final createdAt = data['createdAt'];
    final subtitleParts = <String>[
      alumnoNombre.trim().isEmpty ? 'Sin alumno especifico' : alumnoNombre,
      if (grupoNombre.trim().isNotEmpty) grupoNombre,
      _formatDateTime(createdAt),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fotoUrl.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fotoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPhotoFallbackIcon(),
                ),
              )
            else
              _buildPhotoFallbackIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asunto,
                    style: const TextStyle(
                      color: Color(0xFF1E2A44),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleParts.join(' | '),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassReportView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildReportHeader(
          'Reporte de Clase',
          'Sube las tres fotos de como quedo el aula.',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fotos requeridas',
                  style: TextStyle(
                    color: Color(0xFF1E2A44),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _buildClassPhotoPicker('pizarra'),
                const SizedBox(height: 10),
                _buildClassPhotoPicker('mesas'),
                const SizedBox(height: 10),
                _buildClassPhotoPicker('limpio'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingClassReport ? null : _saveClassReport,
                    icon: _savingClassReport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _savingClassReport
                          ? 'Subiendo...'
                          : 'Guardar reporte de clase',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassPhotoPicker(String key) {
    return _buildPhotoPickerTile(
      title: _classPhotoLabel(key),
      subtitle: 'Obligatoria',
      photo: _classReportPhotos[key],
      icon: _classPhotoIcon(key),
      onPick: () async {
        final photo = await _pickReportPhoto();
        if (photo == null || !mounted) return;
        setState(() {
          _classReportPhotos[key] = photo;
        });
      },
      onClear: _classReportPhotos[key] == null
          ? null
          : () {
              setState(() {
                _classReportPhotos.remove(key);
              });
            },
    );
  }

  Widget _buildPhotoPickerTile({
    required String title,
    required String subtitle,
    required XFile? photo,
    required Future<void> Function() onPick,
    VoidCallback? onClear,
    IconData icon = Icons.photo_camera_outlined,
  }) {
    final fileName = photo?.name.trim();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E1DE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB83357)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          fileName == null || fileName.isEmpty ? subtitle : fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Quitar foto',
              ),
            IconButton(
              onPressed: onPick,
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Agregar foto',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoFallbackIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFB83357).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Color(0xFFB83357)),
    );
  }

  Future<XFile?> _pickReportPhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
    } catch (e) {
      _showSnackBar('No se pudo seleccionar la foto: $e');
      return null;
    }
  }

  Future<void> _saveIncidence() async {
    final asunto = _incidenceSubjectController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (asunto.isEmpty) {
      _showSnackBar('Escribe el asunto de la incidencia');
      return;
    }

    if (user == null) {
      _showSnackBar('Vuelve a iniciar sesion para guardar');
      return;
    }

    setState(() {
      _savingIncidence = true;
    });

    try {
      final now = DateTime.now();
      final docRef = _firestore.collection('incidencias').doc();
      final alumnoData = await _loadSelectedAlumnoData();
      Map<String, String>? photoInfo;

      if (_incidencePhoto != null) {
        photoInfo = await _uploadReportPhoto(
          photo: _incidencePhoto!,
          folder: 'incidencias',
          filePrefix: docRef.id,
        );
      }

      await docRef.set({
        'asunto': asunto,
        'alumnoId': _selectedIncidenceAlumnoId,
        'alumnoNombre': alumnoData['nombre'] ?? '',
        'grupoId': alumnoData['grupoId'] ?? '',
        'grupoNombre': alumnoData['grupoNombre'] ?? '',
        'fotoUrl': photoInfo?['url'] ?? '',
        'fotoPath': photoInfo?['path'] ?? '',
        'fotoProvider': photoInfo?['provider'] ?? '',
        'fotoPublicId': photoInfo?['publicId'] ?? '',
        'fechaId': _dateId(now),
        'mesId': _monthId(now),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'createdByEmail': user.email ?? '',
      });

      if (!mounted) return;
      setState(() {
        _selectedIncidenceAlumnoId = null;
        _incidencePhoto = null;
        _incidenceSubjectController.clear();
      });
      _showSnackBar('Incidencia guardada');
    } catch (e) {
      _showSnackBar('No se pudo guardar la incidencia: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingIncidence = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadSelectedAlumnoData() async {
    final alumnoId = _selectedIncidenceAlumnoId;

    if (alumnoId == null || alumnoId.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final snapshot = await _firestore.collection('alumnos').doc(alumnoId).get();
    if (!snapshot.exists) {
      return <String, dynamic>{};
    }

    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> _saveClassReport() async {
    final user = FirebaseAuth.instance.currentUser;
    final missingPhoto = [
      'pizarra',
      'mesas',
      'limpio',
    ].firstWhere((key) => _classReportPhotos[key] == null, orElse: () => '');

    if (missingPhoto.isNotEmpty) {
      _showSnackBar('Falta la foto de ${_classPhotoLabel(missingPhoto)}');
      return;
    }

    if (user == null) {
      _showSnackBar('Vuelve a iniciar sesion para guardar');
      return;
    }

    setState(() {
      _savingClassReport = true;
    });

    try {
      final now = DateTime.now();
      final docRef = _firestore.collection('reportesClase').doc();
      final fotos = <String, Map<String, String>>{};

      for (final key in ['pizarra', 'mesas', 'limpio']) {
        final uploaded = await _uploadReportPhoto(
          photo: _classReportPhotos[key]!,
          folder: 'clases/${docRef.id}',
          filePrefix: key,
        );
        fotos[key] = uploaded;
      }

      await docRef.set({
        'fotos': fotos,
        'fechaId': _dateId(now),
        'mesId': _monthId(now),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'createdByEmail': user.email ?? '',
      });

      if (!mounted) return;
      setState(() {
        _classReportPhotos.clear();
      });
      _showSnackBar('Reporte de clase guardado');
    } catch (e) {
      _showSnackBar('No se pudo guardar el reporte: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingClassReport = false;
        });
      }
    }
  }

  Future<Map<String, String>> _uploadReportPhoto({
    required XFile photo,
    required String folder,
    required String filePrefix,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'sin-usuario';
    final extension = _photoExtension(photo);
    final cloudinaryFolder = _cleanCloudinaryPath('reportes/$folder/$userId');
    final fileName =
        '${_cleanCloudinarySegment(filePrefix)}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bytes = await photo.readAsBytes();
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/$_cloudinaryCloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = _cloudinaryUploadPreset
          ..fields['folder'] = cloudinaryFolder
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = responseData['error'];
      final message = error is Map<String, dynamic>
          ? (error['message'] ?? 'error desconocido').toString()
          : 'error desconocido';
      throw Exception('Cloudinary no acepto la imagen: $message');
    }

    final secureUrl = (responseData['secure_url'] ?? '').toString();
    final publicId = (responseData['public_id'] ?? '').toString();
    if (secureUrl.isEmpty || publicId.isEmpty) {
      throw Exception('Cloudinary no devolvio la URL de la imagen');
    }

    return {
      'url': secureUrl,
      'path': publicId,
      'provider': 'cloudinary',
      'publicId': publicId,
      'assetId': (responseData['asset_id'] ?? '').toString(),
    };
  }

  String _photoExtension(XFile photo) {
    final name = photo.name.toLowerCase();
    final dotIndex = name.lastIndexOf('.');

    if (dotIndex >= 0 && dotIndex < name.length - 1) {
      final extension = name.substring(dotIndex + 1);
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
        return extension;
      }
    }

    final mimeType = photo.mimeType ?? '';
    if (mimeType.contains('png')) return 'png';
    if (mimeType.contains('webp')) return 'webp';
    if (mimeType.contains('heic')) return 'heic';
    return 'jpg';
  }

  String _cleanCloudinaryPath(String value) {
    return value
        .split('/')
        .map(_cleanCloudinarySegment)
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }

  String _cleanCloudinarySegment(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.trim().isEmpty ? 'archivo' : cleaned;
  }

  String _classPhotoLabel(String key) {
    switch (key) {
      case 'pizarra':
        return 'Pizarra';
      case 'mesas':
        return 'Mesas';
      case 'limpio':
        return 'Limpio';
      default:
        return key;
    }
  }

  IconData _classPhotoIcon(String key) {
    switch (key) {
      case 'pizarra':
        return Icons.draw_outlined;
      case 'mesas':
        return Icons.table_restaurant_outlined;
      case 'limpio':
        return Icons.cleaning_services_outlined;
      default:
        return Icons.photo_camera_outlined;
    }
  }

  String _monthId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String _monthName(int month) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (month < 1 || month > names.length) return '';
    return names[month - 1];
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate is! Timestamp) return 'Fecha pendiente';

    final date = rawDate.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatReadableDate(_dateId(date))} $hour:$minute';
  }

  Widget _buildInlineEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E1DE)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E2A44),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildReportSummary() {
    return FutureBuilder<List<int>>(
      future: _loadReportCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? [0, 0, 0];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Grupos',
                    value: counts[0].toString(),
                    icon: Icons.groups_outlined,
                    color: const Color(0xFF1E2A44),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Alumnos',
                    value: counts[1].toString(),
                    icon: Icons.school_outlined,
                    color: const Color(0xFFB83357),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMetricTile(
              title: 'Catequistas registrados',
              value: counts[2].toString(),
              icon: Icons.volunteer_activism_outlined,
              color: const Color(0xFFB83357),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lectura rapida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2A44),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Usa Recursos para actualizar Meet, versiculo y juegos. Usa Asistencia para habilitar los dias en que se puede pasar lista.',
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>> _loadReportCounts() async {
    final snapshots = await Future.wait([
      _firestore.collection('grupos').get(),
      _firestore.collection('alumnos').get(),
      _firestore.collection('catequistas').get(),
    ]);

    return snapshots.map((snapshot) => snapshot.docs.length).toList();
  }

  Widget _buildLeccionesModule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('configuracion')
          .doc('lecciones')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final reunionUrl = (data['reunionUrl'] ?? '').toString().trim();
        final whatsAppUrl = (data['whatsAppUrl'] ?? '').toString().trim();
        final juegos = _readJuegos(data);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Lecciones',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configura el link de reunion y crea tarjetas de juegos para los catequistas.',
              style: TextStyle(color: Colors.grey[700], height: 1.35),
            ),
            const SizedBox(height: 16),
            _buildLessonConfigCard(
              title: 'Meet',
              subtitle: reunionUrl.isEmpty
                  ? 'Sin link configurado'
                  : 'Link actual: $reunionUrl',
              icon: Icons.video_call_outlined,
              actionLabel: reunionUrl.isEmpty ? 'Agregar link' : 'Cambiar link',
              onTap: () => _showMeetLinkDialog(reunionUrl),
            ),
            const SizedBox(height: 12),
            _buildLessonConfigCard(
              title: 'WhatsApp de Catequesis',
              subtitle: whatsAppUrl.isEmpty
                  ? 'Sin WhatsApp configurado'
                  : 'WhatsApp configurado para los catequistas',
              icon: Icons.chat_outlined,
              actionLabel: whatsAppUrl.isEmpty ? 'Agregar' : 'Cambiar',
              onTap: () => _showWhatsAppDialog(whatsAppUrl),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Juegos',
                    style: TextStyle(
                      color: Color(0xFF1E2A44),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showGameLinkDialog(data: data),
                  icon: const Icon(Icons.add),
                  label: const Text('Juego'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (juegos.isEmpty)
              _buildInlineEmptyState(
                icon: Icons.sports_esports,
                title: 'Sin juegos',
                message:
                    'Agrega tarjetas con icono y link para los catequistas.',
              )
            else
              ...juegos.asMap().entries.map((entry) {
                return _buildGameConfigCard(
                  data: data,
                  index: entry.key,
                  juego: entry.value,
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildLessonConfigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF5F3F2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFB83357).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFB83357)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E2A44),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFFB83357),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameConfigCard({
    required Map<String, dynamic> data,
    required int index,
    required Map<String, dynamic> juego,
  }) {
    final titulo = (juego['titulo'] ?? 'Juego').toString();
    final url = (juego['url'] ?? '').toString();
    final iconKey = (juego['icono'] ?? 'sports_esports').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF5F3F2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A44).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _gameIconFromKey(iconKey),
            color: const Color(0xFF1E2A44),
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF1E2A44),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _showGameLinkDialog(
          data: data,
          editIndex: index,
          existingGame: juego,
        ),
        trailing: IconButton(
          onPressed: () => _deleteGameLink(data: data, index: index),
          icon: const Icon(Icons.delete_outline),
          color: const Color(0xFFB83357),
          tooltip: 'Eliminar juego',
        ),
      ),
    );
  }

  Widget _buildAsistenciaModule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('configuracion')
          .doc('diasAsistencia')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final dias = data['dias'] is List
            ? (List<String>.from(data['dias'])..sort())
            : <String>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Dias de clase',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estos dias habilitan asistencia, reportes e incidencias para los catequistas.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectSaturdayClassDay,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Agregar sabado'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectAnyClassDay,
                  icon: const Icon(Icons.event),
                  label: const Text('Dia cualquiera'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dias.isEmpty)
              _buildEmptyState(
                icon: Icons.event_busy,
                title: 'No hay dias habilitados',
                message: 'Agrega una fecha para permitir clase ese dia.',
              )
            else
              ...dias.map(
                (dia) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available),
                    title: Text(_formatReadableDate(dia)),
                    subtitle: Text(dia),
                    trailing: IconButton(
                      onPressed: () => _confirmRemoveAttendanceDay(dia),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Quitar dia',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _selectSaturdayClassDay() async {
    final initialSaturday = _nextSaturday(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialSaturday,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Seleccionar sabado de clase',
      cancelText: 'Cancelar',
      confirmText: 'Agregar',
      selectableDayPredicate: (date) => date.weekday == DateTime.saturday,
    );

    if (pickedDate == null) return;

    if (pickedDate.weekday != DateTime.saturday) {
      _showSnackBar('Elige un sabado para esta opcion');
      return;
    }

    final dateId = _dateId(pickedDate);
    await _addAttendanceDay(dateId, 'Sabado habilitado como clase');
  }

  Future<void> _selectAnyClassDay() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    final dateId = _dateId(pickedDate);
    final confirmed = await _confirmAction(
      title: 'Habilitar dia de clase',
      message:
          'Estas segura de habilitar ${_formatReadableDate(dateId)} como dia de clase?',
      confirmLabel: 'Habilitar',
    );

    if (!confirmed) return;

    await _addAttendanceDay(dateId, 'Dia habilitado como clase');
  }

  Future<void> _addAttendanceDay(String dateId, String successMessage) async {
    try {
      await _firestore.collection('configuracion').doc('diasAsistencia').set({
        'dias': FieldValue.arrayUnion([dateId]),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
      _showSnackBar(successMessage);
    } catch (e) {
      _showSnackBar('No se pudo habilitar el dia: $e');
    }
  }

  Future<void> _confirmRemoveAttendanceDay(String dateId) async {
    final confirmed = await _confirmAction(
      title: 'Eliminar dia de clase',
      message:
          'Estas segura de eliminar ${_formatReadableDate(dateId)} de los dias de clase?',
      confirmLabel: 'Eliminar',
    );

    if (!confirmed) return;

    try {
      await _firestore.collection('configuracion').doc('diasAsistencia').set({
        'dias': FieldValue.arrayRemove([dateId]),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
      _showSnackBar('Dia quitado');
    } catch (e) {
      _showSnackBar('No se pudo quitar el dia: $e');
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result == true;
  }

  String _dateId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _nextSaturday(DateTime from) {
    final normalized = DateTime(from.year, from.month, from.day);
    final daysUntilSaturday = DateTime.saturday - normalized.weekday;
    if (daysUntilSaturday >= 0) {
      return normalized.add(Duration(days: daysUntilSaturday));
    }
    return normalized.add(Duration(days: daysUntilSaturday + 7));
  }

  String _formatReadableDate(String dateId) {
    final parts = dateId.split('-');
    if (parts.length != 3) return dateId;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  List<Map<String, dynamic>> _readJuegos(Map<String, dynamic> data) {
    final raw = data['juegosVideos'];

    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _showMeetLinkDialog(String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Link de reunion Meet'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Link de Meet',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final saved = await _saveMeetLink('');
                  if (saved && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Eliminar link'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final saved = await _saveMeetLink(controller.text);
                  if (saved && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showWhatsAppDialog(String currentValue) async {
    await _showLessonTextDialog(
      title: 'WhatsApp de Catequesis',
      label: 'Numero con codigo de pais o link de WhatsApp',
      helperText: 'Ejemplo: 51999999999 o https://wa.me/51999999999',
      currentValue: currentValue,
      fieldName: 'whatsAppUrl',
      emptyMessage: 'WhatsApp eliminado',
      successMessage: 'WhatsApp actualizado',
      keyboardType: TextInputType.url,
    );
  }

  Future<void> _showLessonTextDialog({
    required String title,
    required String label,
    required String helperText,
    required String currentValue,
    required String fieldName,
    required String emptyMessage,
    required String successMessage,
    required TextInputType keyboardType,
  }) async {
    final controller = TextEditingController(text: currentValue);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                helperText: helperText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final saved = await _saveLessonText(
                    fieldName: fieldName,
                    value: '',
                    successMessage: emptyMessage,
                  );
                  if (saved && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Eliminar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final saved = await _saveLessonText(
                    fieldName: fieldName,
                    value: controller.text,
                    successMessage: successMessage,
                  );
                  if (saved && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showGameLinkDialog({
    required Map<String, dynamic> data,
    int? editIndex,
    Map<String, dynamic>? existingGame,
  }) async {
    final titleController = TextEditingController(
      text: (existingGame?['titulo'] ?? '').toString(),
    );
    final urlController = TextEditingController(
      text: (existingGame?['url'] ?? '').toString(),
    );
    var selectedIcon = (existingGame?['icono'] ?? 'sports_esports').toString();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  editIndex == null ? 'Agregar juego' : 'Editar juego',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del juego',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Link del juego',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _lessonGameIcons.containsKey(selectedIcon)
                            ? selectedIcon
                            : 'sports_esports',
                        decoration: const InputDecoration(
                          labelText: 'Icono',
                          border: OutlineInputBorder(),
                        ),
                        items: _lessonGameIcons.keys.map((key) {
                          return DropdownMenuItem(
                            value: key,
                            child: Row(
                              children: [
                                Icon(_gameIconFromKey(key)),
                                const SizedBox(width: 10),
                                Text(_gameIconLabel(key)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedIcon = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final saved = await _saveGameLink(
                        data: data,
                        editIndex: editIndex,
                        title: titleController.text,
                        url: urlController.text,
                        iconKey: selectedIcon,
                      );
                      if (saved && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      urlController.dispose();
    }
  }

  Future<bool> _saveMeetLink(String url) async {
    try {
      await _firestore.collection('configuracion').doc('lecciones').set({
        'reunionUrl': url.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      _showSnackBar(
        url.trim().isEmpty ? 'Link eliminado' : 'Link de Meet actualizado',
      );
      return true;
    } catch (e) {
      _showSnackBar('No se pudo guardar el link: $e');
      return false;
    }
  }

  Future<bool> _saveLessonText({
    required String fieldName,
    required String value,
    required String successMessage,
  }) async {
    try {
      await _firestore.collection('configuracion').doc('lecciones').set({
        fieldName: value.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      _showSnackBar(successMessage);
      return true;
    } catch (e) {
      _showSnackBar('No se pudo guardar la informacion: $e');
      return false;
    }
  }

  Future<bool> _saveGameLink({
    required Map<String, dynamic> data,
    required int? editIndex,
    required String title,
    required String url,
    required String iconKey,
  }) async {
    final cleanTitle = title.trim();
    final cleanUrl = url.trim();

    if (cleanTitle.isEmpty || cleanUrl.isEmpty) {
      _showSnackBar('Completa nombre y link del juego');
      return false;
    }

    final juegos = _readJuegos(data);
    final game = {
      'titulo': cleanTitle,
      'url': cleanUrl,
      'icono': _lessonGameIcons.containsKey(iconKey)
          ? iconKey
          : 'sports_esports',
    };

    if (editIndex != null && editIndex >= 0 && editIndex < juegos.length) {
      juegos[editIndex] = game;
    } else {
      juegos.add(game);
    }

    return _saveGameLinks(juegos, successMessage: 'Juego guardado');
  }

  Future<void> _deleteGameLink({
    required Map<String, dynamic> data,
    required int index,
  }) async {
    final juegos = _readJuegos(data);
    if (index < 0 || index >= juegos.length) return;
    juegos.removeAt(index);
    await _saveGameLinks(juegos, successMessage: 'Juego eliminado');
  }

  Future<bool> _saveGameLinks(
    List<Map<String, dynamic>> juegos, {
    required String successMessage,
  }) async {
    try {
      await _firestore.collection('configuracion').doc('lecciones').set({
        'juegosVideos': juegos,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      _showSnackBar(successMessage);
      return true;
    } catch (e) {
      _showSnackBar('No se pudieron guardar los juegos: $e');
      return false;
    }
  }

  static const Map<String, IconData> _lessonGameIcons = {
    'sports_esports': Icons.sports_esports,
    'extension': Icons.extension,
    'casino': Icons.casino,
    'emoji_events': Icons.emoji_events,
    'psychology': Icons.psychology,
    'music_note': Icons.music_note,
  };

  IconData _gameIconFromKey(String key) {
    return _lessonGameIcons[key] ?? Icons.sports_esports;
  }

  String _gameIconLabel(String key) {
    switch (key) {
      case 'extension':
        return 'Piezas';
      case 'casino':
        return 'Dados';
      case 'emoji_events':
        return 'Premio';
      case 'psychology':
        return 'Memoria';
      case 'music_note':
        return 'Musica';
      case 'sports_esports':
      default:
        return 'Juego';
    }
  }

  Widget _buildPerfilModule() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'Sesion no disponible',
        message: 'Vuelve a iniciar sesion para ver tu perfil.',
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('superiores').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final nombre = (data['nombre'] ?? _displayNameFromUser(user))
            .toString();
        final rol = (data['rol'] ?? 'Coordinador parroquial').toString();
        final email = user.email ?? 'Sin correo';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildWelcomeCard(nombre),
            const SizedBox(height: 18),
            _buildProfileInfoCard(
              nombre: nombre,
              rol: rol,
              email: email,
              onEdit: () => _showProfileDialog(
                userId: user.uid,
                nombre: nombre,
                rol: rol,
              ),
            ),
            const SizedBox(height: 18),
            _buildSupportCard(),
            const SizedBox(height: 18),
            _buildMissionCard(),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeCard(String nombre) {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A44),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 18,
            bottom: 12,
            child: Icon(
              Icons.church,
              size: 118,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PANEL DE COORDINADOR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bienvenido,\n$nombre',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Bienvenido, ha ingresado al modulo Coordinador. Esperamos que tenga un buen dia.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard({
    required String nombre,
    required String rol,
    required String email,
    required VoidCallback onEdit,
  }) {
    final now = TimeOfDay.now().format(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF5F3F2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Informacion del Perfil',
                    style: TextStyle(
                      color: Color(0xFF1E2A44),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFFB83357),
                  tooltip: 'Editar perfil',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileRow('Nombre Completo', nombre),
            _buildProfileRow('Rol de Supervision', rol),
            _buildProfileRow('Ultimo Acceso', 'Hoy, $now'),
            _buildProfileRow('Correo Electronico', email),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E2A44),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showSnackBar('Soporte parroquial pendiente de configurar'),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xFFB83357),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(
                Icons.support_agent,
                size: 100,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contactar a Soporte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Asistencia inmediata para supervisores.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/fondo.jpeg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0x990F2135), BlendMode.multiply),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Mision Parroquial\n2024',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Supervisando el crecimiento espiritual de nuestra comunidad con excelencia y devocion.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileDialog({
    required String userId,
    required String nombre,
    required String rol,
  }) async {
    final nombreController = TextEditingController(text: nombre);
    final rolController = TextEditingController(text: rol);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Editar perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rolController,
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final saved = await _saveSuperiorProfile(
                  userId: userId,
                  nombre: nombreController.text,
                  rol: rolController.text,
                );
                if (saved && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    } finally {
      nombreController.dispose();
      rolController.dispose();
    }
  }

  Future<bool> _saveSuperiorProfile({
    required String userId,
    required String nombre,
    required String rol,
  }) async {
    final cleanNombre = nombre.trim();

    if (cleanNombre.isEmpty) {
      _showSnackBar('El nombre es obligatorio');
      return false;
    }

    try {
      await _firestore.collection('superiores').doc(userId).set({
        'nombre': cleanNombre,
        'rol': rol.trim().isEmpty ? 'Coordinador parroquial' : rol.trim(),
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showSnackBar('Perfil actualizado');
      return true;
    } catch (e) {
      _showSnackBar('No se pudo guardar el perfil: $e');
      return false;
    }
  }

  String _displayNameFromUser(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final emailName = user.email?.split('@').first.trim();
    if (emailName == null || emailName.isEmpty) {
      return 'Superior';
    }

    return emailName
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupClassDaySummary {
  _GroupClassDaySummary(this.dateId);

  final String dateId;
  int asistencias = 0;
  int incidencias = 0;
  int reportes = 0;
}

class _GroupClassDayDetail {
  const _GroupClassDayDetail({
    required this.totalAlumnos,
    required this.presentAlumnos,
    required this.incidencias,
    required this.reportes,
  });

  final int totalAlumnos;
  final List<String> presentAlumnos;
  final List<Map<String, dynamic>> incidencias;
  final List<Map<String, dynamic>> reportes;
}
