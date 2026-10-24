import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _navy = Color(0xFF1E2A44);
  static const Color _bone = Color(0xFFF5F3F2);
  static const Color _wine = Color(0xFFB83357);

  @override
  Widget build(BuildContext context) {
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
          const _SettingsOptionCard(
            icon: Icons.dark_mode_outlined,
            title: 'Modo Oscuro',
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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: SettingsScreen._bone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SettingsScreen._wine.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: SettingsScreen._wine),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: SettingsScreen._navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text('Proximamente'),
        trailing: const Icon(Icons.lock_outline, color: SettingsScreen._navy),
      ),
    );
  }
}
