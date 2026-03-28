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

    return Container(
      height: 90,
      color: Colors.transparent,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: (currentIndex + 0.5) / icons.length),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, notchPosition, child) {
              return CustomPaint(
                size: const Size(double.infinity, 90),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active Icon at the TOP of the U
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        top: isSelected ? 10 : 25, 
                        child: Icon(
                          icons[index],
                          color: isSelected ? activeColor : inactiveColor,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                      // Label at the bottom
                      Positioned(
                        bottom: 12,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Text(
                            labels[index],
                            style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
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

  UNotchPainter({required this.notchPosition, required this.bgColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = bgColor..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1.5;

    final path = Path();
    final double nPos = notchPosition * size.width;
    final double radius = 30.0;
    final double depth = 35.0; // Deeper U as per your sketch

    path.moveTo(0, 0);
    path.lineTo(nPos - radius - 10, 0);
    
    // Smooth U curve
    path.cubicTo(
      nPos - radius, 0, 
      nPos - radius + 5, depth, 
      nPos, depth
    );
    path.cubicTo(
      nPos + radius - 5, depth, 
      nPos + radius, 0, 
      nPos + radius + 10, 0
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 10, false);
    canvas.drawPath(path, paint);
    
    // Draw top border only
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(nPos - radius - 10, 0);
    borderPath.cubicTo(nPos - radius, 0, nPos - radius + 5, depth, nPos, depth);
    borderPath.cubicTo(nPos + radius - 5, depth, nPos + radius, 0, nPos + radius + 10, 0);
    borderPath.lineTo(size.width, 0);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(UNotchPainter old) => old.notchPosition != notchPosition;
}
