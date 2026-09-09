import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app.dart';
import '../../app/theme/app_colors.dart';

const String _idPaquete = 'com.jplabs.tribunapro.tribunapro';
const String _urlPlayStore = 'https://play.google.com/store/apps/details?id=$_idPaquete';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con botón de retroceso
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: textoPrincipal,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: textoPrincipal,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de configuraciones agrupadadas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Seccion General
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: textoSecundario,
                      ),
                    ),
                  ),
                  _buildGrupo(
                    superficie: superficie,
                    borde: borde,
                    children: [
                      _item(
                        context,
                        Icons.person_outline_rounded,
                        'Perfil',
                        onTap: () {},
                      ),
                      _itemModoOscuro(context),
                      _item(
                        context,
                        Icons.workspace_premium_outlined,
                        'Modo Pro',
                        onTap: () {},
                      ),
                      _item(
                        context,
                        Icons.info_outline_rounded,
                        'Sobre nosotros',
                        onTap: () => _mostrarAcercaDe(context),
                      ),
                      _item(
                        context,
                        Icons.star_outline_rounded,
                        'Calificar la app',
                        onTap: () => _mostrarCalificar(context),
                      ),
                      _item(
                        context,
                        Icons.share_outlined,
                        'Compartir',
                        onTap: () => _compartirApp(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Seccion Cuenta / Acciones
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'CUENTA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: textoSecundario,
                      ),
                    ),
                  ),
                  _buildGrupo(
                    superficie: superficie,
                    borde: borde,
                    children: [
                      _item(
                        context,
                        Icons.logout_rounded,
                        'Cerrar sesión',
                        onTap: () {},
                      ),
                      _item(
                        context,
                        Icons.delete_outline_rounded,
                        'Eliminar cuenta',
                        onTap: () {},
                        esPeligroso: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== VENTANA: Acerca de ====
  void _mostrarAcercaDe(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_soccer_rounded, size: 40, color: AppColors.acento),
              const SizedBox(height: 16),
              Text(
                'Tribuna pro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textoPrincipal),
              ),
              const SizedBox(height: 4),
              Text(
                'Versión 1.0.0',
                style: TextStyle(fontSize: 13, color: textoSecundario),
              ),
              const SizedBox(height: 12),
              Text(
                'Desarrollado por JPLABS',
                style: TextStyle(fontSize: 13, color: textoSecundario),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==== VENTANA: Calificar la app ====
  void _mostrarCalificar(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Te gusta la app?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textoPrincipal),
              ),
              const SizedBox(height: 6),
              Text(
                'Calificanos en Play Store, nos ayuda un montón.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textoSecundario),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(Icons.star_rounded, color: AppColors.acento, size: 32),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.acento,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _abrirPlayStore();
                  },
                  child: const Text('Calificar en Play Store'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirPlayStore() async {
    final uri = Uri.parse(_urlPlayStore);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ==== Compartir ====
  Future<void> _compartirApp() async {
    await Share.share(
      'Descargá Tribuna pro, predicciones de fútbol de las principales ligas y copas del mundo 🏆⚽\n$_urlPlayStore',
    );
  }

  // Contenedor redondeado para agrupar ítems
  Widget _buildGrupo({
    required Color superficie,
    required Color borde,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 0.8),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          final esUltimo = index == children.length - 1;
          return Column(
            children: [
              children[index],
              if (!esUltimo)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 52,
                  color: borde,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icono,
    String texto, {
    required VoidCallback onTap,
    bool esPeligroso = false,
    String? badge,
  }) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esPeligroso
        ? AppColors.error
        : (esOscuro ? AppColors.textoOscuro : AppColors.textoClaro);
    final colorIcono = esPeligroso ? AppColors.error : AppColors.acento;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (esPeligroso ? AppColors.error : AppColors.acento).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, size: 20, color: colorIcono),
      ),
      title: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorTexto,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.proBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pro,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _itemModoOscuro(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final esActivo = mode == ThemeMode.dark;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.acento.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              size: 20,
              color: AppColors.acento,
            ),
          ),
          title: Text(
            'Modo oscuro',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textoPrincipal,
            ),
          ),
          trailing: Switch.adaptive(
            value: esActivo,
            activeColor: AppColors.acento,
            onChanged: (activo) {
              themeModeNotifier.value = activo ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        );
      },
    );
  }
}