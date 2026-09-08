import 'package:flutter/material.dart';

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
      return _placeholder();
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progreso) {
          if (progreso == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
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
}