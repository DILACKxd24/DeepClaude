import 'package:flutter/material.dart';

/// TDesign 风格的颜色常量
class TDColors {
  // 品牌色
  static const Color brandColor = Color(0xFFD97706);
  static const Color brandColorLight = Color(0xFFFFF7ED);
  static const Color brandColorFocus = Color(0xFFB45309);
  
  // 功能色
  static const Color successColor = Color(0xFF00A870);
  static const Color warningColor = Color(0xFFED7B2F);
  static const Color errorColor = Color(0xFFE34D59);
  static const Color infoColor = Color(0xFF0052D9);
  
  // 文字色 - 浅色模式
  static const Color textPrimary = Color(0xFF181818);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textPlaceholder = Color(0xFFBBBBBB);
  static const Color textDisabled = Color(0xFFDCDCDC);
  
  // 文字色 - 深色模式
  static const Color textPrimaryDark = Color(0xFFE7E7E7);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textPlaceholderDark = Color(0xFF6B6B6B);
  static const Color textDisabledDark = Color(0xFF4D4D4D);
  
  // 背景色 - 浅色模式
  static const Color bgPage = Color(0xFFF5F5F5);
  static const Color bgContainer = Color(0xFFFFFFFF);
  static const Color bgComponent = Color(0xFFF3F3F3);
  static const Color bgComponentHover = Color(0xFFE7E7E7);
  
  // 背景色 - 深色模式
  static const Color bgPageDark = Color(0xFF0D0D0D);
  static const Color bgContainerDark = Color(0xFF1A1A1A);
  static const Color bgComponentDark = Color(0xFF262626);
  static const Color bgComponentHoverDark = Color(0xFF333333);
  
  // 边框色
  static const Color borderLevel1 = Color(0xFFE5E5E5);
  static const Color borderLevel2 = Color(0xFFD9D9D9);
  static const Color borderLevel1Dark = Color(0xFF333333);
  static const Color borderLevel2Dark = Color(0xFF404040);
  
  // 侧边栏颜色
  static const Color sidebarBg = Color(0xFFFAFAFA);
  static const Color sidebarBgDark = Color(0xFF141414);
  
  // 获取适配深色模式的颜色
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color getTextPlaceholder(bool isDark) => isDark ? textPlaceholderDark : textPlaceholder;
  static Color getBgPage(bool isDark) => isDark ? bgPageDark : bgPage;
  static Color getBgContainer(bool isDark) => isDark ? bgContainerDark : bgContainer;
  static Color getBgComponent(bool isDark) => isDark ? bgComponentDark : bgComponent;
  static Color getBgComponentHover(bool isDark) => isDark ? bgComponentHoverDark : bgComponentHover;
  static Color getBorder(bool isDark) => isDark ? borderLevel1Dark : borderLevel1;
  static Color getSidebarBg(bool isDark) => isDark ? sidebarBgDark : sidebarBg;
}

/// TDesign 风格的按钮
class TDStyledButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isOutline;
  final bool isText;
  final bool isDanger;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final EdgeInsets? padding;

  const TDStyledButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isOutline = false,
    this.isText = false,
    this.isDanger = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  State<TDStyledButton> createState() => _TDStyledButtonState();
}

class _TDStyledButtonState extends State<TDStyledButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    Color bgColor;
    Color textColor;
    Color borderColor;
    
    if (widget.isDisabled) {
      bgColor = isDark ? TDColors.bgComponentDark : TDColors.bgComponent;
      textColor = isDark ? TDColors.textDisabledDark : TDColors.textDisabled;
      borderColor = Colors.transparent;
    } else if (widget.isDanger) {
      if (widget.isText) {
        bgColor = _isHovered ? TDColors.errorColor.withOpacity(0.1) : Colors.transparent;
        textColor = TDColors.errorColor;
        borderColor = Colors.transparent;
      } else if (widget.isOutline) {
        bgColor = _isHovered ? TDColors.errorColor.withOpacity(0.1) : Colors.transparent;
        textColor = TDColors.errorColor;
        borderColor = TDColors.errorColor;
      } else {
        bgColor = _isHovered ? TDColors.errorColor.withOpacity(0.9) : TDColors.errorColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
      }
    } else if (widget.isText) {
      bgColor = _isHovered ? accentColor.withOpacity(0.1) : Colors.transparent;
      textColor = accentColor;
      borderColor = Colors.transparent;
    } else if (widget.isOutline) {
      bgColor = _isHovered ? accentColor.withOpacity(0.1) : Colors.transparent;
      textColor = accentColor;
      borderColor = accentColor;
    } else {
      bgColor = _isHovered ? accentColor.withOpacity(0.9) : accentColor;
      textColor = Colors.white;
      borderColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: borderColor != Colors.transparent
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的输入框
class TDStyledInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const TDStyledInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<TDStyledInput> createState() => _TDStyledInputState();
}

class _TDStyledInputState extends State<TDStyledInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? TDColors.textPrimaryDark : TDColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? TDColors.bgContainerDark : TDColors.bgContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? accentColor
                  : (isDark ? TDColors.borderLevel1Dark : TDColors.borderLevel1),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: isDark ? TDColors.textSecondaryDark : TDColors.textSecondary,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  autofocus: widget.autofocus,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? TDColors.textPrimaryDark : TDColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: isDark ? TDColors.textPlaceholderDark : TDColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixIcon != null ? 8 : 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                ),
              ),
              if (widget.suffix != null) ...[
                widget.suffix!,
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// TDesign 风格的卡片
class TDStyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;

  const TDStyledCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? TDColors.bgContainerDark : TDColors.bgContainer),
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: isDark ? TDColors.borderLevel1Dark : TDColors.borderLevel1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的标签
class TDStyledTag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isOutline;
  final bool isLight;
  final IconData? icon;
  final VoidCallback? onClose;

  const TDStyledTag({
    super.key,
    required this.text,
    this.color,
    this.isOutline = false,
    this.isLight = true,
    this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? TDColors.brandColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color textColor;
    Color borderColor;
    
    if (isOutline) {
      bgColor = Colors.transparent;
      textColor = tagColor;
      borderColor = tagColor;
    } else if (isLight) {
      bgColor = tagColor.withOpacity(0.1);
      textColor = tagColor;
      borderColor = Colors.transparent;
    } else {
      bgColor = tagColor;
      textColor = Colors.white;
      borderColor = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != Colors.transparent
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, size: 14, color: textColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// TDesign 风格的开关
class TDStyledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;

  const TDStyledSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDisabled
              ? (isDark ? TDColors.bgComponentDark : TDColors.bgComponent)
              : (value ? accentColor : (isDark ? TDColors.bgComponentDark : TDColors.bgComponent)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的分割线
class TDStyledDivider extends StatelessWidget {
  final double? height;
  final double? indent;
  final double? endIndent;

  const TDStyledDivider({
    super.key,
    this.height,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Divider(
      height: height ?? 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: isDark ? TDColors.borderLevel1Dark : TDColors.borderLevel1,
    );
  }
}

/// TDesign 风格的空状态
class TDEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const TDEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? TDColors.bgComponentDark : TDColors.bgComponent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isDark ? TDColors.textSecondaryDark : TDColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? TDColors.textPrimaryDark : TDColors.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? TDColors.textSecondaryDark : TDColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// TDesign 风格的加载指示器
class TDLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? text;

  const TDLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: accentColor,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 12),
          Text(
            text!,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? TDColors.textSecondaryDark : TDColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// TDesign 风格的头像
class TDAvatar extends StatelessWidget {
  final String? text;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final IconData? icon;

  const TDAvatar({
    super.key,
    this.text,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? TDColors.brandColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(size / 4),
                child: Image.network(
                  imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : icon != null
                ? Icon(icon, color: Colors.white, size: size * 0.5)
                : Text(
                    text?.isNotEmpty == true ? text![0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
      ),
    );
  }
}

/// TDesign 风格的徽标
class TDBadge extends StatelessWidget {
  final Widget child;
  final int? count;
  final bool showDot;
  final Color? color;

  const TDBadge({
    super.key,
    required this.child,
    this.count,
    this.showDot = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? TDColors.errorColor;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showDot || (count != null && count! > 0))
          Positioned(
            right: -4,
            top: -4,
            child: showDot
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count! > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}


/// TDesign 风格的侧边栏项
class TDSidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isHighlighted;
  final Widget? trailing;

  const TDSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isHighlighted = false,
    this.trailing,
  });

  @override
  State<TDSidebarItem> createState() => _TDSidebarItemState();
}

class _TDSidebarItemState extends State<TDSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    Color bgColor;
    if (widget.isSelected) {
      bgColor = accentColor.withOpacity(0.1);
    } else if (_isHovered) {
      bgColor = TDColors.getBgComponentHover(isDark);
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: accentColor.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected || widget.isHighlighted
                    ? accentColor
                    : TDColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? accentColor
                        : TDColors.getTextPrimary(isDark),
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的列表项
class TDListItem extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsets? padding;

  const TDListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding,
  });

  @override
  State<TDListItem> createState() => _TDListItemState();
}

class _TDListItemState extends State<TDListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    Color bgColor;
    if (widget.isSelected) {
      bgColor = accentColor.withOpacity(0.08);
    } else if (_isHovered) {
      bgColor = TDColors.getBgComponentHover(isDark);
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: TDColors.getTextPrimary(isDark),
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: TDColors.getTextSecondary(isDark),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的搜索框
class TDSearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const TDSearchInput({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  State<TDSearchInput> createState() => _TDSearchInputState();
}

class _TDSearchInputState extends State<TDSearchInput> {
  late TextEditingController _controller;
  bool _isFocused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: TDColors.getBgContainer(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isFocused ? accentColor : TDColors.getBorder(isDark),
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search,
            size: 18,
            color: TDColors.getTextPlaceholder(isDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 13,
                color: TDColors.getTextPrimary(isDark),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: TDColors.getTextPlaceholder(isDark),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onClear?.call();
                widget.onChanged?.call('');
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: TDColors.getTextSecondary(isDark),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// TDesign 风格的标签页
class TDTabBar extends StatelessWidget {
  final List<TDTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const TDTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TDColors.getBgComponent(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == selectedIndex;
          
          return Expanded(
            child: _TDTabButton(
              icon: tab.icon,
              label: tab.label,
              isSelected: isSelected,
              onTap: () => onChanged?.call(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TDTabItem {
  final IconData icon;
  final String label;

  const TDTabItem({required this.icon, required this.label});
}

class _TDTabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TDTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TDTabButton> createState() => _TDTabButtonState();
}

class _TDTabButtonState extends State<_TDTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? TDColors.getBgContainer(isDark)
                : (_isHovered ? TDColors.getBgComponentHover(isDark) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isSelected
                    ? accentColor
                    : TDColors.getTextSecondary(isDark),
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isSelected
                      ? TDColors.getTextPrimary(isDark)
                      : TDColors.getTextSecondary(isDark),
                  fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TDesign 风格的消息输入框
class TDMessageInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final bool isLoading;
  final List<Widget>? attachments;
  final Widget? leading;
  final List<Widget>? actions;

  const TDMessageInput({
    super.key,
    this.controller,
    this.hintText,
    this.onSend,
    this.onAttach,
    this.isLoading = false,
    this.attachments,
    this.leading,
    this.actions,
  });

  @override
  State<TDMessageInput> createState() => _TDMessageInputState();
}

class _TDMessageInputState extends State<TDMessageInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: TDColors.getBgContainer(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TDColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 附件预览
          if (widget.attachments != null && widget.attachments!.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.attachments!,
              ),
            ),

          // 输入框
          TextField(
            controller: _controller,
            maxLines: null,
            minLines: 1,
            style: TextStyle(
              fontSize: 15,
              color: TDColors.getTextPrimary(isDark),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Type a message...',
              hintStyle: TextStyle(
                color: TDColors.getTextPlaceholder(isDark),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          // 底部工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: TDColors.getBorder(isDark).withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                if (widget.leading != null) widget.leading!,
                // 附件按钮
                _TDIconButton(
                  icon: Icons.add,
                  tooltip: 'Add attachment',
                  onTap: widget.onAttach,
                ),
                if (widget.actions != null) ...widget.actions!,
                const Spacer(),
                // 发送按钮
                GestureDetector(
                  onTap: widget.isLoading ? null : widget.onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.isLoading ? TDColors.getBgComponent(isDark) : accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: widget.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TDColors.getTextSecondary(isDark),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// TDesign 风格的图标按钮
class _TDIconButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool isSelected;

  const _TDIconButton({
    required this.icon,
    this.tooltip,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<_TDIconButton> createState() => _TDIconButtonState();
}

class _TDIconButtonState extends State<_TDIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accentColor.withOpacity(0.1)
                : (_isHovered ? TDColors.getBgComponentHover(isDark) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isSelected
                ? accentColor
                : TDColors.getTextSecondary(isDark),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// TDesign 风格的状态指示器
class TDStatusIndicator extends StatelessWidget {
  final bool isActive;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;

  const TDStatusIndicator({
    super.key,
    required this.isActive,
    this.label,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? (activeColor ?? TDColors.successColor)
        : (inactiveColor ?? TDColors.getTextPlaceholder(isDark));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// TDesign 风格的分组标题
class TDSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const TDSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TDColors.getTextSecondary(isDark),
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// TDesign 风格的工具提示按钮
class TDTooltipButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isHighlighted;
  final double size;

  const TDTooltipButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isSelected = false,
    this.isHighlighted = false,
    this.size = 32,
  });

  @override
  State<TDTooltipButton> createState() => _TDTooltipButtonState();
}

class _TDTooltipButtonState extends State<TDTooltipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    Color bgColor;
    Color iconColor;

    if (widget.isSelected) {
      bgColor = accentColor.withOpacity(0.1);
      iconColor = accentColor;
    } else if (widget.isHighlighted) {
      bgColor = TDColors.warningColor.withOpacity(0.1);
      iconColor = TDColors.warningColor;
    } else if (_isHovered) {
      bgColor = TDColors.getBgComponentHover(isDark);
      iconColor = TDColors.getTextPrimary(isDark);
    } else {
      bgColor = Colors.transparent;
      iconColor = TDColors.getTextSecondary(isDark);
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: widget.isHighlighted
                  ? Border.all(color: TDColors.warningColor.withOpacity(0.5))
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.55,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
