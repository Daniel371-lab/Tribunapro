import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EscudoImagen extends StatelessWidget {
  final String url;
  final double size;

  const EscudoImagen({
    super.key,
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.shield_outlined,
          size: size * 0.7,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.network(
        url,
        placeholderBuilder: (context) => SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.shield_outlined,
            size: size * 0.7,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
