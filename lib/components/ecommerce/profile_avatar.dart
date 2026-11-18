import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.image,
  });

  final double size;
  final String? imageUrl;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final provider =
        image ??
        (url == null || url.isEmpty ? null : CachedNetworkImageProvider(url));
    Widget placeholder() => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person_outline, size: size * 0.55),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: provider == null
            ? placeholder()
            : Image(
                image: provider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              ),
      ),
    );
  }
}
