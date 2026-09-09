import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  static const _secciones = [
    (
      'Términos y Condiciones de Uso',
      'Última actualización: 2026\nEntidad responsable: JPLABS\nNombre de la aplicación: Tribuna Pro',
    ),
    (
      '1. Aceptación de los Términos',
      'Al descargar, instalar o utilizar la aplicación Tribuna Pro (en adelante, "la Aplicación"), el usuario acepta quedar vinculado por los presentes Términos y Condiciones. Si no está de acuerdo con estos términos, debe abstenerse de utilizar la Aplicación y desinstalarla de inmediato.',
    ),
    (
      '2. Edad mínima',
      'La Aplicación está dirigida a usuarios mayores de 13 años. Los usuarios menores de esa edad no deben utilizar Tribuna Pro sin la supervisión y el consentimiento de su tutor legal.',
    ),
    (
      '3. Naturaleza de la Aplicación y Exclusión de Apuestas',
      'Tribuna Pro es una herramienta digital de carácter estrictamente informativo, estadístico y de entretenimiento centrada en el análisis de fútbol.\n\nNo es una casa de apuestas: la Aplicación no promueve, facilita, opera ni constituye una plataforma de apuestas en línea, juegos de azar o casino de ningún tipo. Ningún elemento dentro de la app involucra transacciones de dinero real para apuestas.\n\nLas funciones de predicción y análisis se basan en datos históricos y algoritmos estadísticos de rendimiento deportivo.',
    ),
    (
      '4. Exención de Responsabilidad por Predicciones y Resultados',
      'Naturaleza azarosa del deporte: el fútbol es un deporte dinámico, impredecible y sujeto a múltiples factores aleatorios (lesiones, decisiones arbitrales, rendimiento imprevisto, entre otros).\n\nFallo de las predicciones: las predicciones generadas por la Aplicación pueden fallar. JPLABS no garantiza ni asegura un porcentaje de acierto exacto.\n\nLimitación de daños: JPLABS no se hace responsable, bajo ninguna circunstancia, por pérdidas económicas, financieras, de apuestas externas o de cualquier otra índole que el usuario pueda sufrir al tomar decisiones basándose en la información, estadísticas o predicciones proporcionadas por Tribuna Pro.',
    ),
    (
      '5. Responsabilidad del Usuario',
      'El usuario es total y único responsable del uso que le da a la Aplicación, de la interpretación que haga de los datos estadísticos y de las decisiones que tome en su vida personal o profesional a partir de estos. El uso de la información contenida en Tribuna Pro queda bajo el riesgo exclusivo del usuario.',
    ),
    (
      '6. Compras dentro de la Aplicación',
      'La Aplicación puede ofrecer contenido o funciones adicionales ("Modo Pro") mediante compras dentro de la app, gestionadas a través de los sistemas de pago de la tienda correspondiente (Google Play). Estas compras se rigen adicionalmente por los términos de esa plataforma. JPLABS podrá habilitar, modificar o discontinuar estas funciones en cualquier momento.',
    ),
    (
      '7. Propiedad Intelectual y Derechos Reservados',
      'Todos los derechos de propiedad intelectual e industrial sobre la Aplicación, incluyendo su diseño gráfico, código fuente, interfaces de usuario, logotipos, bases de datos, estructura de contenidos y marcas asociadas, están reservados exclusivamente para JPLABS. Queda estrictamente prohibida la reproducción, distribución, modificación o ingeniería inversa de cualquier componente de la app sin autorización previa y por escrito de JPLABS.',
    ),
    (
      '8. Modificaciones de los Términos',
      'JPLABS se reserva el derecho de modificar, actualizar o cambiar estos Términos y Condiciones en cualquier momento. Las modificaciones entrarán en vigor a partir de su publicación en la Aplicación o en los canales oficiales de distribución.',
    ),
    (
      'Política de Privacidad',
      '',
    ),
    (
      '1. Información que Recopilamos',
      'Para garantizar el correcto funcionamiento de Tribuna Pro, podemos recopilar la siguiente información:\n\nDatos de cuenta: información básica de registro (nombre, apellido, correo electrónico) o un identificador anónimo si se ingresa como invitado, gestionados de forma segura a través de Firebase Authentication (Google).\n\nDatos de uso y preferencias: preferencias de visualización, competencias favoritas e interacciones con el contenido de la aplicación para mejorar la experiencia general.',
    ),
    (
      '2. Uso de la Información',
      'Los datos recopilados son utilizados exclusivamente para:\n\nGestionar la cuenta del usuario y el acceso a funciones específicas de la plataforma.\nSincronizar contenidos, resultados y estadísticas en tiempo real.\nMantener la seguridad, estabilidad y rendimiento técnico de la Aplicación.',
    ),
    (
      '3. Proveedores de Servicios y Terceros',
      'Tribuna Pro utiliza los siguientes servicios de terceros para su funcionamiento técnico:\n\nFirebase (Google) — autenticación de usuarios y almacenamiento de datos (base de datos Firestore).\nfootball-data.org — proveedor externo de estadísticas y resultados deportivos utilizados para generar el contenido de la app.\n\nEstos servicios cumplen con normativas de protección de datos estándar de la industria y solo procesan la información necesaria para el funcionamiento técnico de la app.',
    ),
    (
      '4. Seguridad de los Datos',
      'Implementamos medidas de seguridad técnicas y organizativas orientadas a proteger la información personal de accesos no autorizados, pérdidas o alteraciones. Sin embargo, ningún sistema de transmisión por internet es 100% seguro.',
    ),
    (
      '5. Privacidad de Menores',
      'La Aplicación está dirigida a un público general interesado en el deporte, mayor de 13 años, y no recopila intencionalmente datos de menores de esa edad sin la supervisión o consentimiento de sus tutores legales.',
    ),
    (
      '6. Eliminación de Cuenta y Datos',
      'El usuario puede eliminar su cuenta y los datos asociados en cualquier momento desde la sección Ajustes de la Aplicación, o solicitándolo directamente por correo electrónico a los canales de contacto indicados a continuación.',
    ),
    (
      '7. Contacto',
      'Para cualquier duda, consulta, solicitud de eliminación de cuenta o ejercicio de derechos relacionados con su privacidad o estos términos, el usuario puede ponerse en contacto directamente con los administradores a través del siguiente correo electrónico: jplabscreator@gmail.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? AppColors.textoOscuro : AppColors.textoClaro;
    final textoSecundario = esOscuro ? AppColors.textoSecundarioOscuro : AppColors.textoSecundarioClaro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Privacidad'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _secciones.length,
          itemBuilder: (context, index) {
            final (titulo, cuerpo) = _secciones[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textoPrincipal,
                    ),
                  ),
                  if (cuerpo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      cuerpo,
                      style: TextStyle(fontSize: 13, height: 1.5, color: textoSecundario),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}