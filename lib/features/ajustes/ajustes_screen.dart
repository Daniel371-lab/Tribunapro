import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../app/theme/app_colors.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Ajustes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _item(context, Icons.person_outline, 'Perfil', onTap: () {}),
                _itemModoOscuro(),
                _item(context, Icons.workspace_premium_outlined, 'Modo Pro', onTap: () {}),
                _item(context, Icons.bar_chart_outlined, 'Porcentaje de aciertos', onTap: () {}),
                _item(context, Icons.info_outline, 'Sobre nosotros', onTap: () {}),
                const Divider(height: 32),
                _item(context, Icons.logout, 'Cerrar sesión', onTap: () {}),
                _item(context, Icons.delete_outline, 'Eliminar cuenta', onTap: () {}, esPeligroso: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icono, String texto, {required VoidCallback onTap, bool esPeligroso = false}) {
    return ListTile(
      leading: Icon(icono, color: esPeligroso ? AppColors.error : null),
      title: Text(texto, style: TextStyle(color: esPeligroso ? AppColors.error : null)),
      onTap: onTap,
    );
  }

  Widget _itemModoOscuro() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Modo oscuro'),
          trailing: Switch(
            value: mode == ThemeMode.dark,
            onChanged: (activo) {
              themeModeNotifier.value = activo ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        );
      },
    );
  }
}