import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'td_components.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: TDColors.getSidebarBg(isDark),
          border: Border(
            bottom: BorderSide(
              color: TDColors.getBorder(isDark),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // macOS 交通灯按钮占位
            if (Platform.isMacOS) const SizedBox(width: 72),

            // 快捷键提示
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: TDColors.getBgComponent(isDark),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: TDColors.getBorder(isDark),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 14,
                    color: TDColors.getTextPlaceholder(isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '⌘ K',
                    style: TextStyle(
                      color: TDColors.getTextPlaceholder(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 应用名称
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'DeepClaude',
                  style: TextStyle(
                    color: TDColors.getTextPrimary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Windows 窗口控制按钮
            if (Platform.isWindows) ...[
              _WindowButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: Icons.crop_square_outlined,
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                onPressed: () => windowManager.close(),
                isClose: true,
              ),
            ] else
              const SizedBox(width: 72),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isClose 
                    ? const Color(0xFFE34D59) 
                    : TDColors.getBgComponentHover(isDark))
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.isClose
                ? Colors.white
                : TDColors.getTextSecondary(isDark),
          ),
        ),
      ),
    );
  }
}
