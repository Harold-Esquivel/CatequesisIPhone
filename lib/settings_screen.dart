import 'design/borgona_theme.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Color get _navy => Borgona.navy;
  static Color get _bone => Borgona.background;
  static Color get _wine => Borgona.burgundy;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _bone,
      appBar: AppBar(
        title: const Text('Configuraciones'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Salir',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          NeoCard(
            margin: EdgeInsets.zero,
            child: ValueListenableBuilder<bool>(
              valueListenable: Borgona.darkMode,
              builder: (context, enabled, child) => SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: Text(enabled ? 'Activado' : 'Desactivado'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: enabled,
                onChanged: (value) async {
                  try {
                    await Borgona.setDarkMode(value);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo guardar la preferencia. Vuelve a intentar.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SettingsOptionCard(
            icon: Icons.text_fields,
            title: 'Tipo de Letra',
          ),
          const SizedBox(height: 12),
          const _SettingsOptionCard(
            icon: Icons.palette_outlined,
            title: 'Colores del aplicativo',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _SettingsOptionCard extends StatelessWidget {
  const _SettingsOptionCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return NeoCard(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: SettingsScreen._bone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: NeoDecoration(
            color: SettingsScreen._wine.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: SettingsScreen._wine),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: SettingsScreen._navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text('Proximamente'),
        trailing: Icon(Icons.lock_outline, color: SettingsScreen._navy),
      ),
    );
  }
}
