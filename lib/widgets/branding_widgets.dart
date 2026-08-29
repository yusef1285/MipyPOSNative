import 'dart:io';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double height;
  const BrandLogo({this.height = 48, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/mipypos_logo.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'MipyPOS Logo',
    );
  }
}

class CopyrightText extends StatelessWidget {
  final TextAlign align;
  const CopyrightText({this.align = TextAlign.center, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© 2026 MipyPOS — Desarrollado por Alex Yusef. Todos los derechos reservados.',
      textAlign: align,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class ProductImage extends StatelessWidget {
  final String? url; // can be asset path or network
  final double size;

  const ProductImage({this.url, this.size = 56, super.key});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Image.asset(
        'assets/productos/placeholder.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (url!.startsWith('http')) {
      return Image.network(url!, width: size, height: size, fit: BoxFit.cover);
    }

    if (url!.startsWith('/') || url!.contains('\\')) {
      return Image.file(
        File(url!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/productos/placeholder.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(url!, width: size, height: size, fit: BoxFit.cover);
  }
}
