import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/partido.dart';
import '../../core/services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _servicio = FirestoreService();
  final Set<String> _marcadosPro = {};
  bool _publicando = false;

  Future<void> _publicarTodos(List<Partido> pendientes) async {
    setState(() => _publicando = true);
    try {
      // Primero guarda qué partidos quedaron marcados como Pro.
      for (final partido in pendientes) {
        if (_marcadosPro.contains(partido.id)) {
          await _servicio.actualizarEsPro(partido.id, true);
        }
      }
      // Después publica todos los pendientes de una sola vez.
      await _servicio.publicarPartidos(pendientes.map((p) => p.id).toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pendientes.length} partido(s) publicados correctamente.')),
        );
        setState(() => _marcadosPro.clear());
      }
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esOscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final superficie = esOscuro ? AppColors.superficieOscuro : AppColors.superficieClaro;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;
    final borde = esOscuro ? AppColors.bordeOscuro : AppColors.bordeClaro;

    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textoPrincipal),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Partidos pendientes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textoPrincipal),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Partido>>(
                stream: _servicio.partidosPendientes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar pendientes', style: TextStyle(color: textoSecundario)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pendientes = snapshot.data!;

                  if (pendientes.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay partidos pendientes de revisión.',
                        style: TextStyle(color: textoSecundario, fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          itemCount: pendientes.length,
                          itemBuilder: (context, index) {
                            final partido = pendientes[index];
                            final marcado = _marcadosPro.contains(partido.id);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: superficie,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borde, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${partido.equipoLocal} vs ${partido.equipoVisitante}',
                                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textoPrincipal),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${partido.competenciaNombre} • ${_formatearFecha(partido.fecha)}',
                                          style: TextStyle(fontSize: 11.5, color: textoSecundario),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: marcado ? AppColors.pro : textoSecundario)),
                                      Switch.adaptive(
                                        value: marcado,
                                        activeColor: AppColors.pro,
                                        onChanged: (valor) {
                                          setState(() {
                                            if (valor) {
                                              _marcadosPro.add(partido.id);
                                            } else {
                                              _marcadosPro.remove(partido.id);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _publicando ? null : () => _publicarTodos(pendientes),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.acento,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _publicando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('Publicar ${pendientes.length} partido(s)'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '${fecha.day} ${meses[fecha.month - 1]} • $hora';
  }
}