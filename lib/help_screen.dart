import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'design/borgona_theme.dart';

Future<void> showTechnicalSupport(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Soporte técnico',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const SelectableText('971 135 384', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.call_outlined),
            label: const Text('Llamar'),
            onPressed: () async {
              try {
                if (await launchUrl(Uri(scheme: 'tel', path: '+51971135384'))) {
                  return;
                }
              } catch (_) {
                /* Offer copying when no phone handler is installed. */
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo iniciar la llamada. Puedes copiar el número.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar número'),
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: '971135384'));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Número copiado')));
              }
            },
          ),
        ],
      ),
    ),
  ),
);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.superior});
  final bool superior;
  @override
  Widget build(BuildContext context) {
    final sections = superior
        ? const [
            (
              'Mi perfil',
              Icons.person_outline,
              'Consulta tu nombre, rol y correo. Pulsa editar para actualizar tu nombre y rol visible. Desde esta pantalla también puedes contactar al soporte técnico.',
            ),
            (
              'Grupos',
              Icons.groups_outlined,
              'Crea grupos con nombre, sala y descripción, incluso sin catequista. Editar grupo permite asignar uno o varios catequistas o retirarlos. El botón Crear catequista registra su nombre, usuario y contraseña sin cerrar tu sesión. Después, asígnalo desde Editar grupo.\n\nAbre un grupo para agregar alumnos con el teléfono de su apoderado o moverlos a otro grupo. En Administrar integrantes encontrarás las pestañas Catequistas y Alumnos: usa el menú junto al nombre para editar sus datos o eliminar al usuario. Eliminar un catequista lo retira de todos sus grupos y bloquea su acceso. El historial anterior se conserva.',
            ),
            (
              'Lecciones',
              Icons.menu_book_outlined,
              'Configura el enlace de reunión, los enlaces de juegos o videos y los medios de comunicación de las clases. El contenido que guardes estará disponible para los catequistas en Lecciones o Mensajes.',
            ),
            (
              'Clases',
              Icons.event_available_outlined,
              'Habilita en el calendario los días de asistencia. Los catequistas podrán registrar asistencias, incidencias y reportes únicamente en las fechas habilitadas. Quita una fecha si ya no debe estar disponible.',
            ),
            (
              'Reportes',
              Icons.assessment_outlined,
              'Selecciona año, mes, grupo y día para revisar la asistencia, las incidencias y las fotos de clase. Los reportes de clase incluyen Pizarra, Mesas y Limpio. Toca una foto para ampliarla. También puedes registrar tus propias incidencias y reportes desde los formularios disponibles.',
            ),
          ]
        : const [
            (
              'Mi perfil',
              Icons.person_outline,
              'Consulta tus datos personales, correo, teléfono y los nombres de los grupos que el superior te ha asignado. Si necesitas cambiar tus datos, solicita la actualización al superior. Aquí encontrarás el acceso al soporte técnico.',
            ),
            (
              'Mis grupos',
              Icons.groups_outlined,
              'Abre un grupo para ver su nombre, sala, descripción, catequistas y alumnos. En una fecha habilitada por el superior, pulsa Iniciar clase para registrar la asistencia de cada alumno. La app evita registrar dos veces al mismo alumno en el día.\n\nDurante la clase puedes registrar una incidencia: selecciona los alumnos involucrados, escribe el asunto y, si lo deseas, añade una foto. Para completar el reporte de clase añade las tres fotos obligatorias: Pizarra, Mesas y Limpio. Puedes usar cámara o galería; revisa las vistas previas antes de guardar. Si falla el guardado, conserva la pantalla y vuelve a intentar: las fotos seleccionadas permanecen allí. Si no aparece tu grupo o no puedes iniciar clase, contacta al superior.',
            ),
            (
              'Lecciones',
              Icons.school_outlined,
              'Abre el enlace de reunión y los juegos o videos que el superior preparó para la clase. También puedes leer el versículo del día. Los enlaces se abren en la aplicación o navegador disponible en tu teléfono.',
            ),
            (
              'Mensajes',
              Icons.chat_bubble_outline,
              'Consulta y abre el enlace de comunicación configurado por el superior para coordinar las clases. Si aún no hay un enlace, solicita que lo configure.',
            ),
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          superior ? 'Ayuda para el superior' : 'Ayuda para el catequista',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NeoCard(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  leading: Icon(section.$2),
                  title: Text(section.$1),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Text(section.$3, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
          const NeoCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuraciones y navegación',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Usa la barra inferior para cambiar de módulo. En el menú superior encontrarás Configuraciones, Ayuda y Salir. En Configuraciones puedes activar Modo oscuro; la app recuerda tu elección. Tipo de Letra y Colores del aplicativo continúan como Próximamente.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showTechnicalSupport(context),
            icon: const Icon(Icons.support_agent),
            label: const Text('Soporte técnico · 971 135 384'),
          ),
        ],
      ),
    );
  }
}
