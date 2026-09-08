import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EscudoImagen extends StatelessWidget {
  final String url;
  final double size;

  const EscudoImagen({
    super.key,
    required this.url,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Icon(
        Icons.shield_outlined,
        size: size,
        color: Colors.grey,
      );
    }

    final isSvg = url.toLowerCase().endsWith('.svg');

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: isSvg
            ? SvgPicture.network(
                url,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => SizedBox(
                  width: size,
                  height: size,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shield_outlined,
                  size: size,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
