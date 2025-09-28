import 'package:flutter/material.dart';

class UniConnectLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final EdgeInsets? padding;

  const UniConnectLogo({
    super.key,
    this.size = 120,
    this.showShadow = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2), // 20% of size for rounded corners
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: size * 0.15,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: Image.asset(
            'assets/Logos/UniConnect Logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if logo fails to load
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6), // AppColors.primary
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
                child: Icon(
                  Icons.school,
                  size: size * 0.5,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Specialized variants for common use cases
class UniConnectLogoLarge extends StatelessWidget {
  final bool showShadow;

  const UniConnectLogoLarge({
    super.key,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return UniConnectLogo(
      size: 120,
      showShadow: showShadow,
    );
  }
}

class UniConnectLogoMedium extends StatelessWidget {
  final bool showShadow;

  const UniConnectLogoMedium({
    super.key,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return UniConnectLogo(
      size: 80,
      showShadow: showShadow,
    );
  }
}

class UniConnectLogoSmall extends StatelessWidget {
  final bool showShadow;

  const UniConnectLogoSmall({
    super.key,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return UniConnectLogo(
      size: 40,
      showShadow: showShadow,
    );
  }
}