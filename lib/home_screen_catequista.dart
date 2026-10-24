import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_screen.dart';
import 'verse_of_day_service.dart';

class HomeCatequistaScreen extends StatefulWidget {
  const HomeCatequistaScreen({super.key});

  @override
  State<HomeCatequistaScreen> createState() => _HomeCatequistaScreenState();
}

class _HomeCatequistaScreenState extends State<HomeCatequistaScreen> {
  int _selectedModuleIndex = 0;
  late Map<String, dynamic> catequistaData = {};
  bool _isLoading = true;
  late final Future<DailyVerse> _dailyVerseFuture;

  final List<String> modules = [
    'Mi perfil',
    'Mis grupos',
    'Lecciones',
    'Mensajes',
  ];
  final List<IconData> moduleIcons = [
    Icons.person,
    Icons.groups,
    Icons.school,
    Icons.chat_bubble_outline,
  ];

  @override
  void initState() {
    super.initState();
    _dailyVerseFuture = VerseOfDayService.fetch();
    _fetchCatequistaData();
  }

  Future<void> _fetchCatequistaData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('Usuario actual: ${user?.uid}');

      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('catequistas')
              .doc(user.uid)
              .get();

          debugPrint('Documento existe: ${doc.exists}');
          debugPrint('Datos del documento: ${doc.data()}');

          if (doc.exists) {
            setState(() {
              catequistaData = doc.data() ?? {};
              _isLoading = false;
            });
            debugPrint('Datos cargados desde Firebase: $catequistaData');
          } else {
            debugPrint(
              'Documento no encontrado, creando documento automático...',
            );

            // Crear documento automáticamente
            final defaultData = {
              'nombre': user.displayName ?? 'Catequista',
              'cedula': 'N/A',
              'telefono': 'N/A',
              'grupo': 'No asignado',
              'email': user.email ?? '',
              'profileImage': user.photoURL,
              'iglesia': 'Nueva Catedral',
              'direccion': 'Calle Principal 123',
              'rol': 'Catequista',
              'asistencia': 0,
              'participacion': 0,
              'tareasCompletadas': '0/0',
              'integrantes': '0',
              'sala': 'No asignada',
              'createdAt': DateTime.now(),
            };

            try {
              await FirebaseFirestore.instance
                  .collection('catequistas')
                  .doc(user.uid)
                  .set(defaultData, SetOptions(merge: true));

              debugPrint('Documento creado automáticamente');
              setState(() {
                catequistaData = defaultData;
                _isLoading = false;
              });
            } catch (createError) {
              debugPrint('Error creando documento: $createError');
              setState(() {
                catequistaData = defaultData;
                _isLoading = false;
              });
            }
          }
        } catch (firestoreError) {
          debugPrint('Error de Firestore: $firestoreError');
          setState(() {
            catequistaData = {
              'nombre': user.displayName ?? 'Catequista',
              'cedula': 'N/A',
              'telefono': 'N/A',
              'grupo': 'No asignado',
              'email': user.email ?? '',
              'profileImage': user.photoURL,
              'iglesia': 'Nueva Catedral',
              'direccion': 'Calle Principal 123',
              'rol': 'Catequista',
            };
            _isLoading = false;
          });
        }
      } else {
        debugPrint('No hay usuario autenticado');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error general al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final normalizedUrl = url.trim().startsWith('http')
        ? url.trim()
        : 'https://${url.trim()}';
    final uri = Uri.tryParse(normalizedUrl);

    if (uri == null) {
      _showSnackBar('Link no valido');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnackBar('No se pudo abrir el link');
    }
  }

  Future<void> _openWhatsApp(String value) async {
    final cleanValue = value.trim();
    final digits = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
    final url = cleanValue.startsWith('http')
        ? cleanValue
        : digits.isEmpty
        ? ''
        : 'https://wa.me/$digits';

    if (url.isEmpty) {
      _showSnackBar('El WhatsApp de Catequesis no esta configurado');
      return;
    }

    await _launchExternalUrl(url);
  }

  String _todayAttendanceId() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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

  void _changeModule(int index) {
    setState(() {
      _selectedModuleIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F3F2),
        body: _buildLoadingScreen(),
      );
    }

    final profileImage = catequistaData['profileImage']?.toString().trim();
    final hasProfileImage = profileImage != null && profileImage.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.menu,
                    size: 22,
                    color: Color(0xFF1E2A44),
                  ),
                  onSelected: (String value) {
                    if (value == 'logout') {
                      _showLogoutDialog();
                    } else if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    } else if (value == 'help') {
                      _showSnackBar('Ayuda pendiente de configurar');
                    } else {
                      _showSnackBar('Seleccionado: $value');
                    }
                  },
                  itemBuilder: (BuildContext context) => [
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE5E1DE),
                  backgroundImage: hasProfileImage
                      ? NetworkImage(profileImage)
                      : null,
                  child: !hasProfileImage
                      ? Icon(Icons.person, color: Colors.grey[700], size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedModuleIndex,
        children: [
          _buildCatequistaPerfilModule(),
          _buildGrupoModule(),
          _buildLeccionesModule(),
          _buildMensajesModule(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFB83357)),
          ),
          const SizedBox(height: 24),
          Text(
            'Un momentito',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ya estamos entrando a tu perfil',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Módulo: Grupo
  Widget _buildGrupoModule() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(
        child: Text(
          'Error: Usuario no autenticado',
          style: TextStyle(color: Colors.red[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grupos')
          .where('catequistaIds', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        final grupos = snapshot.data?.docs ?? [];

        if (grupos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes grupos asignados',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Mis grupos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...grupos.map((doc) {
              final grupoData = doc.data() as Map<String, dynamic>;
              final nombreGrupo = (grupoData['nombre'] ?? 'Grupo sin nombre')
                  .toString();
              final sala = (grupoData['sala'] ?? 'No asignada').toString();
              final alumnos = grupoData['alumnos'] is List
                  ? List<String>.from(grupoData['alumnos'])
                  : <String>[];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupInfoScreen(groupId: doc.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreGrupo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sala: $sala | Alumnos: ${alumnos.length}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Módulo: Lecciones
  Widget _buildLeccionesModule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('lecciones')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final reunionUrl = (data['reunionUrl'] ?? '').toString().trim();
        final juegos = _readJuegos(data);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis Lecciones',
                style: TextStyle(
                  color: Color(0xFF1E2A44),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Abre la reunion o los juegos que el superior configuro para clase.',
                style: TextStyle(color: Colors.grey[700], height: 1.35),
              ),
              const SizedBox(height: 16),
              _buildLessonActionCard(
                title: 'Meet',
                subtitle: reunionUrl.isEmpty
                    ? 'El superior aun no ha configurado el link de Meet'
                    : reunionUrl,
                icon: Icons.video_call_outlined,
                enabled: reunionUrl.isNotEmpty,
                onTap: reunionUrl.isEmpty
                    ? null
                    : () => _launchExternalUrl(reunionUrl),
              ),
              const SizedBox(height: 12),
              _buildDailyVerseCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB83357).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      color: Color(0xFFB83357),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
              const SizedBox(height: 10),
              if (juegos.isEmpty)
                Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aun no hay juegos cargados.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                )
              else
                ...juegos.map((juego) {
                  final titulo = (juego['titulo'] ?? 'Juego').toString();
                  final url = (juego['url'] ?? '').toString().trim();
                  final iconKey = (juego['icono'] ?? 'sports_esports')
                      .toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildLessonActionCard(
                      title: titulo,
                      subtitle: url,
                      icon: _gameIconFromKey(iconKey),
                      enabled: url.isNotEmpty,
                      onTap: url.isEmpty ? null : () => _launchExternalUrl(url),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyVerseCard() {
    return FutureBuilder<DailyVerse>(
      future: _dailyVerseFuture,
      builder: (context, snapshot) {
        final reference = snapshot.hasData
            ? snapshot.data!.reference
            : snapshot.hasError
            ? 'No se pudo cargar hoy. Intenta nuevamente mas tarde.'
            : 'Buscando la cita biblica de hoy...';

        return _buildLessonActionCard(
          title: 'Versiculo del dia',
          subtitle: reference,
          icon: Icons.menu_book_outlined,
          enabled: false,
          onTap: null,
        );
      },
    );
  }

  // Módulo: Reportes
  Widget _buildMensajesModule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('lecciones')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final whatsAppUrl = (data['whatsAppUrl'] ?? '').toString().trim();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Mensajes',
              style: TextStyle(
                color: Color(0xFF1E2A44),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Entra al WhatsApp oficial de Catequesis para comunicarte.',
              style: TextStyle(color: Colors.grey[700], height: 1.35),
            ),
            const SizedBox(height: 16),
            _buildLessonActionCard(
              title: 'WhatsApp de Catequesis',
              subtitle: whatsAppUrl.isEmpty
                  ? 'El superior aun no ha configurado el WhatsApp'
                  : 'Toca para abrir la conversacion',
              icon: Icons.chat_outlined,
              enabled: whatsAppUrl.isNotEmpty,
              onTap: whatsAppUrl.isEmpty
                  ? null
                  : () => _openWhatsApp(whatsAppUrl),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildReportesModule() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final today = _todayAttendanceId();

    if (userId == null) {
      return Center(
        child: Text(
          'Error: Usuario no autenticado',
          style: TextStyle(color: Colors.red[600]),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('diasAsistencia')
          .snapshots(),
      builder: (context, configSnapshot) {
        final configData =
            configSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final dias = configData['dias'] is List
            ? List<String>.from(configData['dias'])
            : <String>[];
        final claseActiva = dias.contains(today);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('grupos')
              .where('catequistaIds', arrayContains: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                configSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              );
            }

            final grupos = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Reportes de clase',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildReportClassStatusBanner(claseActiva, today),
                const SizedBox(height: 16),
                if (grupos.isEmpty)
                  _buildEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Sin grupos asignados',
                    message:
                        'Cuando un superior te asigne un grupo podras registrar reportes e incidencias.',
                  )
                else
                  ...grupos.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombre'] ?? 'Grupo sin nombre')
                        .toString();
                    final sala = (data['sala'] ?? 'No asignada').toString();
                    final alumnos = data['alumnos'] is List
                        ? List<String>.from(data['alumnos'])
                        : <String>[];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: claseActiva
                              ? const Color(0xFFE5E1DE)
                              : Colors.white,
                          child: Icon(
                            claseActiva
                                ? Icons.photo_camera_outlined
                                : Icons.event_busy,
                            color: claseActiva
                                ? const Color(0xFFB83357)
                                : const Color(0xFF1E2A44),
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Sala: $sala | Alumnos: ${alumnos.length}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupInfoScreen(groupId: doc.id),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReportClassStatusBanner(bool enabled, String today) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF5F3F2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFFB83357) : const Color(0xFFE5E1DE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.lock_clock_outlined,
            color: enabled ? const Color(0xFFB83357) : const Color(0xFF1E2A44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enabled
                  ? 'Hoy ($today) hay clase activa. Puedes tomar fotos desde la camara.'
                  : 'Hoy ($today) no hay clase activa. No se pueden subir reportes ni incidencias.',
              style: TextStyle(
                color: enabled
                    ? const Color(0xFFB83357)
                    : const Color(0xFF1E2A44),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLegacyReportesModule() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(
        child: Text(
          'Error: Usuario no autenticado',
          style: TextStyle(color: Colors.red[600]),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('catequistas')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'No hay datos disponibles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>;
        final asistencia = data['asistencia'] ?? 0;
        final participacion = data['participacion'] ?? 0;
        final tareasCompletadas = data['tareasCompletadas'] ?? 'N/A';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Reportes',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildReportCard(
                'Asistencia',
                '$asistencia%',
                const Color(0xFFB83357),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                'Participación',
                '$participacion%',
                const Color(0xFF1E2A44),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                'Tareas Completadas',
                tareasCompletadas.toString(),
                const Color(0xFFE5E1DE),
              ),
            ],
          ),
        );
      },
    );
  }

  // Módulo: Perfil - MEJORADO Y ESTÉTICO
  Widget _buildCatequistaPerfilModule() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyState(
        icon: Icons.lock_outline,
        title: 'Sesion no disponible',
        message: 'Vuelve a iniciar sesion para ver tu perfil.',
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('catequistas')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data =
            snapshot.data?.data() as Map<String, dynamic>? ?? catequistaData;
        final nombre = (data['nombre'] ?? _displayNameFromUser(user))
            .toString();
        final rol = (data['rol'] ?? 'Catequista').toString();
        final grupo = (data['grupo'] ?? 'No asignado').toString();
        final telefono = (data['telefono'] ?? 'N/A').toString();
        final cedula = (data['cedula'] ?? 'N/A').toString();
        final email = (data['email'] ?? user.email ?? 'Sin correo').toString();

        if (snapshot.connectionState == ConnectionState.waiting &&
            data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildCatequistaWelcomeCard(nombre),
            const SizedBox(height: 18),
            _buildCatequistaProfileInfoCard(
              nombre: nombre,
              rol: rol,
              grupo: grupo,
              telefono: telefono,
              cedula: cedula,
              email: email,
            ),
            const SizedBox(height: 18),
            _buildCatequistaSupportCard(),
            const SizedBox(height: 18),
            _buildCatequistaMissionCard(),
          ],
        );
      },
    );
  }

  Widget _buildCatequistaWelcomeCard(String nombre) {
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
              Icons.auto_stories_outlined,
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
                  'PANEL DE CATEQUISTA',
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
                  'Bienvenido, ha ingresado al modulo Catequista. Esperamos que tenga un buen dia.',
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

  Widget _buildCatequistaProfileInfoCard({
    required String nombre,
    required String rol,
    required String grupo,
    required String telefono,
    required String cedula,
    required String email,
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
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Informacion del Perfil',
                    style: TextStyle(
                      color: Color(0xFF1E2A44),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.badge_outlined, color: Color(0xFFB83357)),
              ],
            ),
            const SizedBox(height: 12),
            _buildCatequistaProfileRow('Nombre Completo', nombre),
            _buildCatequistaProfileRow('Rol', rol),
            _buildCatequistaProfileRow('Grupo', grupo),
            _buildCatequistaProfileRow('Ultimo Acceso', 'Hoy, $now'),
            _buildCatequistaProfileRow('Telefono', telefono),
            _buildCatequistaProfileRow('Cedula', cedula),
            _buildCatequistaProfileRow('Correo Electronico', email),
          ],
        ),
      ),
    );
  }

  Widget _buildCatequistaProfileRow(String label, String value) {
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

  Widget _buildCatequistaSupportCard() {
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
                          'Asistencia inmediata para catequistas.',
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

  Widget _buildCatequistaMissionCard() {
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
              'Acompanando el crecimiento espiritual de cada grupo con dedicacion y servicio.',
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

  String _displayNameFromUser(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final emailName = user.email?.split('@').first.trim();
    if (emailName == null || emailName.isEmpty) {
      return 'Catequista';
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

  // ignore: unused_element
  Widget _buildPerfilModule() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(
        child: Text(
          'Error: Usuario no autenticado',
          style: TextStyle(color: Colors.red[600]),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('catequistas')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'No hay datos de perfil disponibles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>;
        final user = FirebaseAuth.instance.currentUser;

        final nombre = data['nombre'] ?? user?.displayName ?? 'Catequista';
        final rol = data['rol'] ?? 'Catequista';
        final grupo = data['grupo'] ?? 'No asignado';
        final telefono = data['telefono'] ?? 'N/A';
        final email = data['email'] ?? user?.email ?? 'N/A';
        final cedula = data['cedula'] ?? 'N/A';
        final profileImage = data['profileImage'] ?? user?.photoURL;

        debugPrint('Perfil cargado: Nombre=$nombre, Rol=$rol, Grupo=$grupo');

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header con imagen y nombre
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFB83357), const Color(0xFF1E2A44)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          image: profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: profileImage == null
                            ? Center(
                                child: Icon(
                                  Icons.person,
                                  color: const Color(0xFFB83357),
                                  size: 60,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Nombre
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Rol
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          rol,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Sección de Información Personal
                    _buildProfileSection(
                      title: 'Información Personal',
                      icon: Icons.person_outline,
                      children: [
                        _buildProfileInfoRow('Nombre Completo', nombre),
                        _buildProfileInfoRow('Cédula', cedula),
                        _buildProfileInfoRow('Email', email),
                        _buildProfileInfoRow('Teléfono', telefono),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sección de Información Académica
                    _buildProfileSection(
                      title: 'Información Académica',
                      icon: Icons.school_outlined,
                      children: [
                        _buildProfileInfoRow('Grupo', grupo),
                        _buildProfileInfoRow('Rol', rol),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget para secciones del perfil
  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFB83357), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children.asMap().entries.map((entry) {
              int index = entry.key;
              Widget child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(height: 1, color: Colors.grey[200]),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget para filas de información en el perfil
  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: List.generate(modules.length, (index) {
          final selected = _selectedModuleIndex == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _changeModule(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 3,
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
                        moduleIcons[index],
                        size: 20,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF1E2A44),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modules[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
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

  List<Map<String, dynamic>> _readJuegos(Map<String, dynamic> data) {
    final raw = data['juegosVideos'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  Widget _buildLessonActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF5F3F2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
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
                child: Icon(
                  icon,
                  color: enabled ? const Color(0xFFB83357) : Colors.grey[500],
                ),
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
              Icon(
                enabled ? Icons.open_in_new : Icons.link_off,
                color: enabled ? const Color(0xFF1E2A44) : Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  static const String _cloudinaryCloudName = 'izwqrc3a';
  static const String _cloudinaryUploadPreset = 'reportes_unsigned';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _incidenceSubjectController =
      TextEditingController();
  final Map<String, XFile> _classReportPhotos = {};
  final Set<String> _selectedIncidenceAlumnoIds = {};
  XFile? _incidencePhoto;
  bool _savingClassReport = false;
  bool _savingIncidence = false;
  bool _classSessionOpen = false;

  @override
  void dispose() {
    _incidenceSubjectController.dispose();
    super.dispose();
  }

  String _todayAttendanceId() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _registerAttendance(
    String alumnoUid,
    Map<String, dynamic> alumnoData,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final today = _todayAttendanceId();

    if (userId == null) {
      _showSnackBar('Error: usuario no autenticado');
      return;
    }

    try {
      final diasDoc = await _firestore
          .collection('configuracion')
          .doc('diasAsistencia')
          .get();
      final diasData = diasDoc.data() ?? {};
      final dias = diasData['dias'] is List
          ? List<String>.from(diasData['dias'])
          : <String>[];

      if (!dias.contains(today)) {
        _showSnackBar('Hoy no esta habilitada la asistencia');
        return;
      }

      final alumnoRef = _firestore.collection('alumnos').doc(alumnoUid);
      final asistenciaRef = alumnoRef.collection('asistencias').doc(today);
      final asistenciaDoc = await asistenciaRef.get();

      if (asistenciaDoc.exists) {
        _showSnackBar('La asistencia de hoy ya fue registrada');
        return;
      }

      final batch = _firestore.batch();
      batch.set(asistenciaRef, {
        'fecha': today,
        'presente': true,
        'grupoId': alumnoData['grupoId'],
        'registradoPor': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(alumnoRef, {
        'asistencia': FieldValue.increment(1),
        'ultimaAsistencia': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _showSnackBar('Asistencia registrada');
    } catch (e) {
      _showSnackBar('No se pudo registrar la asistencia: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayAttendanceId();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis grupos'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E2A44),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('configuracion')
            .doc('diasAsistencia')
            .snapshots(),
        builder: (context, asistenciaConfigSnapshot) {
          final asistenciaData =
              asistenciaConfigSnapshot.data?.data() as Map<String, dynamic>? ??
              {};
          final dias = asistenciaData['dias'] is List
              ? List<String>.from(asistenciaData['dias'])
              : <String>[];
          final asistenciaHabilitada = dias.contains(today);

          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('grupos')
                .doc(widget.groupId)
                .snapshots(),
            builder: (context, groupSnapshot) {
              if (groupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
                return Center(
                  child: Text(
                    'Grupo no encontrado',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                );
              }

              final grupoData =
                  groupSnapshot.data?.data() as Map<String, dynamic>;
              final nombreGrupo = (grupoData['nombre'] ?? 'Grupo sin nombre')
                  .toString();
              final sala = (grupoData['sala'] ?? 'No asignada').toString();
              final descripcion = (grupoData['descripcion'] ?? '').toString();
              final catequistas = _readCatequistasFromGroup(grupoData);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    nombreGrupo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Información del grupo',
                    children: [
                      _buildInfoRow('Nombre:', nombreGrupo),
                      _buildInfoRow('Sala:', sala),
                      if (descripcion.trim().isNotEmpty)
                        _buildInfoRow('Descripción:', descripcion),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Catequistas',
                    children: catequistas.isEmpty
                        ? [
                            Text(
                              'No hay catequistas asignados.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ]
                        : catequistas.map((catequista) {
                            return _buildInfoRow(
                              'Catequista:',
                              (catequista['nombre'] ?? 'Catequista').toString(),
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildAlumnosSection(
                    asistenciaHabilitada,
                    showAttendanceControls: _classSessionOpen,
                    title:
                        'Alumnos (${grupoData['alumnos'] is List ? (grupoData['alumnos'] as List).length : 0})',
                  ),
                  const SizedBox(height: 16),
                  _buildStartClassButton(asistenciaHabilitada),
                  if (_classSessionOpen) ...[
                    const SizedBox(height: 16),
                    _buildAlumnosSection(
                      asistenciaHabilitada,
                      showAttendanceControls: true,
                      title: 'Asistencia',
                    ),
                    const SizedBox(height: 16),
                    _buildClassReportsSection(
                      activeClass: asistenciaHabilitada,
                      groupName: nombreGrupo,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStartClassButton(bool classIsActive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (!classIsActive) {
            _showNoClassDialog();
            return;
          }
          setState(() => _classSessionOpen = true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: classIsActive
              ? const Color(0xFFB83357)
              : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        icon: Icon(
          classIsActive ? Icons.play_circle_outline : Icons.lock_outline,
        ),
        label: Text(
          classIsActive ? 'Iniciar clase de hoy' : 'No hay clase hoy',
        ),
      ),
    );
  }

  Future<void> _showNoClassDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sin catequesis'),
        content: const Text('Hoy dia no hay catequesis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumnosSection(
    bool asistenciaHabilitada, {
    required bool showAttendanceControls,
    required String title,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('alumnos')
          .where('grupoId', isEqualTo: widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final alumnos = [...(snapshot.data?.docs ?? [])];
        alumnos.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return (aData['nombre'] ?? '').toString().compareTo(
            (bData['nombre'] ?? '').toString(),
          );
        });

        return _buildInfoCard(
          title: title,
          children: alumnos.isEmpty
              ? [
                  Text(
                    'No hay alumnos en este grupo.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ]
              : alumnos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildAlumnoAttendanceCard(
                    alumnoUid: doc.id,
                    alumnoData: data,
                    asistenciaHabilitada:
                        asistenciaHabilitada && showAttendanceControls,
                    showAttendanceControls: showAttendanceControls,
                  );
                }).toList(),
        );
      },
    );
  }

  Widget _buildAlumnoAttendanceCard({
    required String alumnoUid,
    required Map<String, dynamic> alumnoData,
    required bool asistenciaHabilitada,
    required bool showAttendanceControls,
  }) {
    final nombre = (alumnoData['nombre'] ?? 'Alumno sin nombre').toString();
    final telefonoApoderado = (alumnoData['telefonoApoderado'] ?? 'N/A')
        .toString();
    final asistencia = alumnoData['asistencia'] ?? 0;
    final today = _todayAttendanceId();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE5E1DE),
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apoderado: $telefonoApoderado',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Asistencias: $asistencia',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showAttendanceControls) ...[
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('alumnos')
                    .doc(alumnoUid)
                    .collection('asistencias')
                    .doc(today)
                    .snapshots(),
                builder: (context, asistenciaSnapshot) {
                  final registrado =
                      asistenciaSnapshot.hasData &&
                      asistenciaSnapshot.data!.exists;

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: !asistenciaHabilitada || registrado
                          ? null
                          : () => _registerAttendance(alumnoUid, alumnoData),
                      icon: Icon(
                        registrado
                            ? Icons.check_circle
                            : Icons.how_to_reg_outlined,
                      ),
                      label: Text(
                        registrado
                            ? 'Asistencia registrada hoy'
                            : 'Registrar asistencia de hoy',
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassReportsSection({
    required bool activeClass,
    required String groupName,
  }) {
    return Column(
      children: [
        _buildIncidenceUploadCard(
          activeClass: activeClass,
          groupName: groupName,
        ),
        const SizedBox(height: 16),
        _buildClassReportUploadCard(
          activeClass: activeClass,
          groupName: groupName,
        ),
      ],
    );
  }

  Widget _buildClassReportUploadCard({
    required bool activeClass,
    required String groupName,
  }) {
    final today = _todayAttendanceId();

    return _buildInfoCard(
      title: 'Reporte de clase',
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('reportesClase')
              .doc('${widget.groupId}_$today')
              .snapshots(),
          builder: (context, snapshot) {
            final alreadyUploaded = snapshot.data?.exists ?? false;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alreadyUploaded
                    ? const Color(0xFFF5F3F2)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: alreadyUploaded
                      ? const Color(0xFFB83357)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    alreadyUploaded
                        ? Icons.check_circle_outline
                        : Icons.pending_actions_outlined,
                    color: alreadyUploaded
                        ? const Color(0xFFB83357)
                        : Colors.grey[700],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alreadyUploaded
                          ? 'Este grupo ya tiene reporte guardado hoy.'
                          : 'Sube Pizarra, Mesas y Limpio para cerrar la clase.',
                      style: TextStyle(
                        color: alreadyUploaded
                            ? const Color(0xFFB83357)
                            : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildClassPhotoPicker('pizarra', activeClass),
        const SizedBox(height: 10),
        _buildClassPhotoPicker('mesas', activeClass),
        const SizedBox(height: 10),
        _buildClassPhotoPicker('limpio', activeClass),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: !activeClass || _savingClassReport
                ? null
                : () => _saveClassReport(groupName: groupName),
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
                  : activeClass
                  ? 'Guardar reporte de clase'
                  : 'Sin clase activa hoy',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassPhotoPicker(String key, bool activeClass) {
    return _buildPhotoPickerTile(
      title: _classPhotoLabel(key),
      subtitle: activeClass ? 'Obligatoria, solo camara' : 'Sin clase activa',
      photo: _classReportPhotos[key],
      enabled: activeClass && !_savingClassReport,
      icon: _classPhotoIcon(key),
      onPick: () async {
        final photo = await _pickCameraPhoto();
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

  Widget _buildIncidenceUploadCard({
    required bool activeClass,
    required String groupName,
  }) {
    return _buildInfoCard(
      title: 'Incidencias',
      children: [
        Text(
          activeClass
              ? 'Registra incidencias de uno o mas alumnos durante la clase activa.'
              : 'Las incidencias solo se registran cuando hay clase activa.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _incidenceSubjectController,
          enabled: activeClass && !_savingIncidence,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Asunto de la incidencia',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _buildIncidenceStudentSelector(activeClass),
        const SizedBox(height: 12),
        _buildPhotoPickerTile(
          title: 'Foto de la incidencia',
          subtitle: activeClass ? 'Opcional, solo camara' : 'Sin clase activa',
          photo: _incidencePhoto,
          enabled: activeClass && !_savingIncidence,
          onPick: () async {
            final photo = await _pickCameraPhoto();
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
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: !activeClass || _savingIncidence
                ? null
                : () => _saveIncidence(groupName: groupName),
            icon: _savingIncidence
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.report_problem_outlined),
            label: Text(
              _savingIncidence
                  ? 'Guardando...'
                  : activeClass
                  ? 'Guardar incidencia'
                  : 'Sin clase activa hoy',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidenceStudentSelector(bool activeClass) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('alumnos')
          .where('grupoId', isEqualTo: widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        final alumnos = [...(snapshot.data?.docs ?? [])];
        alumnos.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return (aData['nombre'] ?? '').toString().compareTo(
            (bData['nombre'] ?? '').toString(),
          );
        });

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (alumnos.isEmpty) {
          return Text(
            'No hay alumnos en este grupo.',
            style: TextStyle(color: Colors.grey[600]),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: alumnos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = (data['nombre'] ?? 'Alumno').toString();
              final selected = _selectedIncidenceAlumnoIds.contains(doc.id);

              return CheckboxListTile(
                value: selected,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(nombre),
                onChanged: !activeClass || _savingIncidence
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIncidenceAlumnoIds.add(doc.id);
                          } else {
                            _selectedIncidenceAlumnoIds.remove(doc.id);
                          }
                        });
                      },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPickerTile({
    required String title,
    required String subtitle,
    required XFile? photo,
    required bool enabled,
    required Future<void> Function() onPick,
    VoidCallback? onClear,
    IconData icon = Icons.photo_camera_outlined,
  }) {
    final fileName = photo?.name.trim();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: enabled ? const Color(0xFFB83357) : null),
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
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.close),
                tooltip: 'Quitar foto',
              ),
            IconButton(
              onPressed: enabled ? onPick : null,
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Tomar foto',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveClassReport({required String groupName}) async {
    final user = FirebaseAuth.instance.currentUser;
    final missingPhoto = [
      'pizarra',
      'mesas',
      'limpio',
    ].firstWhere((key) => _classReportPhotos[key] == null, orElse: () => '');

    if (user == null) {
      _showSnackBar('Vuelve a iniciar sesion para guardar');
      return;
    }

    if (!await _isTodayActiveClass()) {
      _showSnackBar('Hoy no hay clase activa para subir reportes');
      return;
    }

    if (missingPhoto.isNotEmpty) {
      _showSnackBar('Falta la foto de ${_classPhotoLabel(missingPhoto)}');
      return;
    }

    setState(() {
      _savingClassReport = true;
    });

    try {
      final now = DateTime.now();
      final today = _todayAttendanceId();
      final docRef = _firestore
          .collection('reportesClase')
          .doc('${widget.groupId}_$today');
      final existingDoc = await docRef.get();
      final catequistaNombre = await _loadCatequistaName(user);
      final fotos = <String, Map<String, String>>{};

      for (final key in ['pizarra', 'mesas', 'limpio']) {
        final uploaded = await _uploadReportPhoto(
          photo: _classReportPhotos[key]!,
          folder: 'clases/${widget.groupId}/$today',
          filePrefix: key,
        );
        fotos[key] = uploaded;
      }

      final batch = _firestore.batch();
      final reportData = <String, dynamic>{
        'grupoId': widget.groupId,
        'grupoNombre': groupName,
        'fotos': fotos,
        'fechaId': today,
        'mesId': _monthId(now),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
        'createdBy': user.uid,
        'createdByEmail': user.email ?? '',
        'catequistaNombre': catequistaNombre,
      };

      if (!existingDoc.exists) {
        reportData['createdAt'] = FieldValue.serverTimestamp();
      }

      batch.set(docRef, reportData, SetOptions(merge: true));
      _addSuperiorNotificationToBatch(
        batch: batch,
        type: 'reporte_clase',
        title: 'Reporte de clase completado',
        message: '$groupName termino de subir sus reportes.',
        groupName: groupName,
        dateId: today,
        user: user,
      );

      await batch.commit();

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

  Future<void> _saveIncidence({required String groupName}) async {
    final user = FirebaseAuth.instance.currentUser;
    final asunto = _incidenceSubjectController.text.trim();

    if (user == null) {
      _showSnackBar('Vuelve a iniciar sesion para guardar');
      return;
    }

    if (!await _isTodayActiveClass()) {
      _showSnackBar('Hoy no hay clase activa para registrar incidencias');
      return;
    }

    if (_selectedIncidenceAlumnoIds.isEmpty) {
      _showSnackBar('Selecciona al menos un alumno');
      return;
    }

    if (asunto.isEmpty) {
      _showSnackBar('Escribe el asunto de la incidencia');
      return;
    }

    setState(() {
      _savingIncidence = true;
    });

    try {
      final now = DateTime.now();
      final today = _todayAttendanceId();
      final docRef = _firestore.collection('incidencias').doc();
      final catequistaNombre = await _loadCatequistaName(user);
      final alumnosInfo = await _loadSelectedIncidenceAlumnos();
      final alumnoNombres = alumnosInfo
          .map((alumno) => (alumno['nombre'] ?? '').toString())
          .where((nombre) => nombre.trim().isNotEmpty)
          .join(', ');
      Map<String, String>? photoInfo;

      if (_incidencePhoto != null) {
        photoInfo = await _uploadReportPhoto(
          photo: _incidencePhoto!,
          folder: 'incidencias/${widget.groupId}/$today',
          filePrefix: docRef.id,
        );
      }

      final batch = _firestore.batch();
      batch.set(docRef, {
        'asunto': asunto,
        'alumnoIds': _selectedIncidenceAlumnoIds.toList(),
        'alumnos': alumnosInfo,
        'alumnoId': alumnosInfo.isEmpty ? '' : alumnosInfo.first['id'],
        'alumnoNombre': alumnoNombres,
        'grupoId': widget.groupId,
        'grupoNombre': groupName,
        'fotoUrl': photoInfo?['url'] ?? '',
        'fotoPath': photoInfo?['path'] ?? '',
        'fotoProvider': photoInfo?['provider'] ?? '',
        'fotoPublicId': photoInfo?['publicId'] ?? '',
        'fechaId': today,
        'mesId': _monthId(now),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'createdByEmail': user.email ?? '',
        'catequistaNombre': catequistaNombre,
      });
      _addSuperiorNotificationToBatch(
        batch: batch,
        type: 'incidencia',
        title: 'Nueva incidencia',
        message: '$groupName registro una incidencia: $asunto',
        groupName: groupName,
        dateId: today,
        user: user,
      );

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _selectedIncidenceAlumnoIds.clear();
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

  Future<List<Map<String, dynamic>>> _loadSelectedIncidenceAlumnos() async {
    final docs = await Future.wait(
      _selectedIncidenceAlumnoIds.map(
        (id) => _firestore.collection('alumnos').doc(id).get(),
      ),
    );

    return docs.where((doc) => doc.exists).map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      return {
        'id': doc.id,
        'nombre': data['nombre'] ?? 'Alumno',
        'grupoId': data['grupoId'] ?? widget.groupId,
        'grupoNombre': data['grupoNombre'] ?? '',
      };
    }).toList();
  }

  Future<XFile?> _pickCameraPhoto() async {
    if (!await _isTodayActiveClass()) {
      _showSnackBar('Hoy no hay clase activa para tomar fotos');
      return null;
    }

    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
    } catch (e) {
      _showSnackBar('No se pudo tomar la foto: $e');
      return null;
    }
  }

  Future<bool> _isTodayActiveClass() async {
    final today = _todayAttendanceId();
    final diasDoc = await _firestore
        .collection('configuracion')
        .doc('diasAsistencia')
        .get();
    final diasData = diasDoc.data() ?? {};
    final dias = diasData['dias'] is List
        ? List<String>.from(diasData['dias'])
        : <String>[];
    return dias.contains(today);
  }

  Future<String> _loadCatequistaName(User user) async {
    final doc = await _firestore.collection('catequistas').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final nombre = (data['nombre'] ?? '').toString().trim();
    if (nombre.isNotEmpty) return nombre;
    return user.email?.split('@').first ?? 'Catequista';
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

  void _addSuperiorNotificationToBatch({
    required WriteBatch batch,
    required String type,
    required String title,
    required String message,
    required String groupName,
    required String dateId,
    required User user,
  }) {
    final notificationRef = _firestore
        .collection('notificacionesSuperiores')
        .doc();
    batch.set(notificationRef, {
      'type': type,
      'title': title,
      'message': message,
      'grupoId': widget.groupId,
      'grupoNombre': groupName,
      'fechaId': dateId,
      'mesId': dateId.substring(0, 7),
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'createdByEmail': user.email ?? '',
    });
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

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
