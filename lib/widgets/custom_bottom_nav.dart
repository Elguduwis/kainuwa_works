import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final List<String> labels;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.colorScheme.surface;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? Colors.grey[600]! : const Color(0xFF9CA3AF);

    return SizedBox(
      height: 85,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: (currentIndex + 0.5) / icons.length),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
            builder: (context, notchPosition, child) {
              return CustomPaint(
                size: const Size(double.infinity, 85),
                painter: UNotchPainter(
                  notchPosition: notchPosition,
                  bgColor: bgColor,
                  borderColor: isDark ? Colors.grey[800]! : const Color(0xFFE5E7EB),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              final isSelected = index == currentIndex;
              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / icons.length,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.translationValues(0, isSelected ? 12 : -4, 0),
                        child: Icon(
                          icons[index],
                          color: isSelected ? activeColor : inactiveColor,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.0,
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            color: activeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class UNotchPainter extends CustomPainter {
  final double notchPosition;
  final Color bgColor;
  final Color borderColor;

  UNotchPainter({
    required this.notchPosition,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, 0);

    final notchRadius = 26.0;
    final notchCenter = notchPosition * size.width;

    // Line from left edge to the start of the U
    path.lineTo(notchCenter - notchRadius, 0);
    
    // The downward U-cutout (arc)
    path.arcToPoint(
      Offset(notchCenter + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Line from the end of the U to the right edge
    path.lineTo(size.width, 0);
    
    // Close the shape downwards to fill the background color
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow first, then the background block
    canvas.drawShadow(path, Colors.black, 15, false);
    canvas.drawPath(path, paint);

    // Draw the exact top border with the U-curve matching your sketch
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(notchCenter - notchRadius, 0);
    borderPath.arcToPoint(
      Offset(notchCenter + notchRadius, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    borderPath.lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant UNotchPainter oldDelegate) {
    return oldDelegate.notchPosition != notchPosition ||
           oldDelegate.bgColor != bgColor ||
           oldDelegate.borderColor != borderColor;
  }
}
