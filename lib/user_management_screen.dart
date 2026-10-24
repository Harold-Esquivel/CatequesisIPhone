import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'design/borgona_theme.dart';
import 'services/user_management.dart';

Future<bool?> showCatequistaForm(
  BuildContext context, {
  DocumentSnapshot<Map<String, dynamic>>? profile,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _MemberForm(profile: profile, catequista: true),
);
Future<bool?> showAlumnoForm(
  BuildContext context,
  DocumentSnapshot<Map<String, dynamic>> profile,
) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _MemberForm(profile: profile, catequista: false),
);

class _MemberForm extends StatefulWidget {
  const _MemberForm({this.profile, required this.catequista});
  final DocumentSnapshot<Map<String, dynamic>>? profile;
  final bool catequista;
  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(
    text: widget.profile?.data()?['nombre'] ?? '',
  );
  late final _phone = TextEditingController(
    text:
        widget.profile?.data()?[widget.catequista
            ? 'telefono'
            : 'telefonoApoderado'] ??
        '',
  );
  late final _cedula = TextEditingController(
    text: widget.profile?.data()?['cedula'] ?? '',
  );
  final _usuario = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;
  bool get _creating => widget.profile == null;
  @override
  void dispose() {
    for (final c in [_nombre, _phone, _cedula, _usuario, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = UserManagementService(FirebaseFirestore.instance);
      if (_creating) {
        await service.createCatequista(
          nombre: _nombre.text,
          usuario: _usuario.text,
          password: _password.text,
          telefono: _phone.text,
          cedula: _cedula.text,
        );
      } else if (widget.catequista) {
        await service.updateCatequista(
          id: widget.profile!.id,
          nombre: _nombre.text,
          telefono: _phone.text,
          cedula: _cedula.text,
        );
      } else {
        await service.updateAlumno(
          id: widget.profile!.id,
          nombre: _nombre.text,
          telefonoApoderado: _phone.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = userManagementError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        _creating
            ? 'Crear catequista'
            : widget.catequista
            ? 'Editar catequista'
            : 'Editar alumno',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Borgona.burgundy)),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nombre,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Escribe el nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: widget.catequista
                        ? 'Teléfono'
                        : 'Teléfono del apoderado',
                  ),
                ),
                if (widget.catequista) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cedula,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Documento de identidad',
                    ),
                  ),
                ],
                if (_creating) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usuario,
                    enabled: !_busy,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Usuario para iniciar sesión',
                      hintText: 'Ej. ana.perez',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Escribe un usuario' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidden,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        tooltip: _hidden
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: _busy
                            ? null
                            : () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'Usa al menos 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'El catequista podrá entrar con ese usuario y contraseña. Asígnalo a un grupo desde «Editar grupo».',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: Text(
            _busy
                ? 'Guardando…'
                : _creating
                ? 'Crear catequista'
                : 'Guardar',
          ),
        ),
      ],
    ),
  );
}

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key, required this.groupId});
  final String groupId;

  Future<void> _delete(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> member,
    bool catequista,
  ) async {
    final name =
        (member.data()?['nombre'] ?? (catequista ? 'Catequista' : 'Alumno'))
            .toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar a $name?'),
        content: Text(
          catequista
              ? 'Se quitará de todos sus grupos y se bloqueará su acceso. Sus reportes anteriores se conservarán.'
              : 'Se quitará del grupo y de las listas de alumnos activos. Su historial se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final service = UserManagementService(FirebaseFirestore.instance);
      if (catequista) {
        await service.deleteCatequista(member.id);
      } else {
        await service.deleteAlumno(member.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name fue eliminado')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userManagementError(e))));
      }
    }
  }

  Widget _list(
    BuildContext context, {
    required bool catequista,
    required List<String> ids,
  }) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: catequista
        ? FirebaseFirestore.instance.collection('catequistas').snapshots()
        : FirebaseFirestore.instance
              .collection('alumnos')
              .where('grupoId', isEqualTo: groupId)
              .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'No se pudieron cargar los integrantes. Revisa tu conexión.',
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final members =
          snapshot.data!.docs
              .where(
                (d) =>
                    d.data()['eliminado'] != true &&
                    (!catequista || ids.contains(d.id)),
              )
              .toList()
            ..sort(
              (a, b) => (a.data()['nombre'] ?? '').toString().compareTo(
                (b.data()['nombre'] ?? '').toString(),
              ),
            );
      if (members.isEmpty) {
        return Center(
          child: Text(
            catequista
                ? 'No hay catequistas asignados a este grupo.'
                : 'No hay alumnos en este grupo.',
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        separatorBuilder: (_, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final member = members[index];
          final data = member.data();
          final phone =
              (data[catequista ? 'telefono' : 'telefonoApoderado'] ?? '')
                  .toString();
          return NeoCard(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(
                catequista ? Icons.badge_outlined : Icons.person_outline,
              ),
              title: Text(
                (data['nombre'] ?? (catequista ? 'Catequista' : 'Alumno'))
                    .toString(),
              ),
              subtitle: phone.isEmpty
                  ? null
                  : Text(catequista ? 'Teléfono: $phone' : 'Apoderado: $phone'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Administrar usuario',
                onSelected: (action) async {
                  if (action == 'delete') {
                    await _delete(context, member, catequista);
                  } else if (catequista) {
                    await showCatequistaForm(context, profile: member);
                  } else {
                    await showAlumnoForm(context, member);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar datos')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar usuario'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('grupos')
            .doc(groupId)
            .snapshots(),
        builder: (context, snapshot) {
          final group = snapshot.data?.data() ?? {};
          final ids = <String>{
            ...List<String>.from(group['catequistaIds'] ?? []),
            if ((group['catequistaId'] ?? '').toString().isNotEmpty)
              group['catequistaId'].toString(),
          }.toList();
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  (group['nombre'] ?? 'Integrantes del grupo').toString(),
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Catequistas'),
                    Tab(text: 'Alumnos'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _list(context, catequista: true, ids: ids),
                  _list(context, catequista: false, ids: ids),
                ],
              ),
            ),
          );
        },
      );
}
