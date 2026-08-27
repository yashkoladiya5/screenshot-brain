import 'package:flutter/material.dart';
import 'dart:ui';
import '../design/tokens.dart';

class SbGlassDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SbGlassDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class SbGlassDropdown<T> extends StatefulWidget {
  final List<SbGlassDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final double width;
  final double blurSigma;
  final Color? tintColor;

  const SbGlassDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint = 'Select an option',
    this.width = 250.0,
    this.blurSigma = 10.0,
    this.tintColor,
  });

  @override
  State<SbGlassDropdown<T>> createState() => _SbGlassDropdownState<T>();
}

class _SbGlassDropdownState<T> extends State<SbGlassDropdown<T>> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    // Determine if we should open upwards or downwards based on screen space
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow = screenHeight - offset.dy - size.height;
    
    // Estimate menu height (max 250px or item count * 50px)
    final double menuHeight = (widget.items.length * 50.0).clamp(50.0, 250.0) + 16.0;
    
    final bool openUpwards = spaceBelow < menuHeight && offset.dy > spaceBelow;

    _overlayEntry = _createOverlayEntry(size, menuHeight, openUpwards);
    Overlay.of(context).insert(_overlayEntry!);
    
    setState(() => _isOpen = true);
    _animationController.forward();
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
    });
  }

  OverlayEntry _createOverlayEntry(Size size, double menuHeight, bool openUpwards) {
    final theme = Theme.of(context);
    final tint = widget.tintColor ?? theme.colorScheme.surface.withValues(alpha: 0.4);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible dismissible background
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: widget.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, openUpwards ? -menuHeight - 8 : size.height + 8),
              child: Material(
                color: Colors.transparent,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: openUpwards ? 1.0 : -1.0,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: menuHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SBRadius.md),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SBRadius.md),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: widget.blurSigma, 
                          sigmaY: widget.blurSigma
                        ),
                        child: Container(
                          color: tint,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              final isSelected = item.value == widget.value;
                              
                              return InkWell(
                                onTap: () {
                                  widget.onChanged?.call(item.value);
                                  _closeDropdown();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: SBSpacing.md, 
                                    vertical: 12,
                                  ),
                                  color: isSelected 
                                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      if (item.icon != null) ...[
                                        Icon(
                                          item.icon, 
                                          size: 18, 
                                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = widget.tintColor ?? theme.colorScheme.surface.withValues(alpha: 0.4);
    
    SbGlassDropdownItem<T>? selectedItem;
    try {
      selectedItem = widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      selectedItem = null;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: widget.width,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SBRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SBRadius.md),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md),
                color: tint,
                child: Row(
                  children: [
                    if (selectedItem?.icon != null) ...[
                      Icon(selectedItem!.icon, size: 20),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        selectedItem?.label ?? widget.hint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selectedItem == null 
                              ? theme.colorScheme.onSurfaceVariant 
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
