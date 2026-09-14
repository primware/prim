import 'package:flutter/material.dart';

class ScrollablePillRow extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ScrollablePillRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<ScrollablePillRow> createState() => _ScrollablePillRowState();
}

class _ScrollablePillRowState extends State<ScrollablePillRow> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollState();
    });
  }

  @override
  void didUpdateWidget(ScrollablePillRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollState();
    });
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients || !mounted) return;
    
    final canScrollLeft = _scrollController.position.pixels > 0;
    final canScrollRight = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;

    if (canScrollLeft != _canScrollLeft || canScrollRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canScrollLeft;
        _canScrollRight = canScrollRight;
      });
    }
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final targetPosition = _scrollController.position.pixels + offset;
    _scrollController.animateTo(
      targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.children,
            ),
          ),
          if ((_isHovering || _canScrollLeft) && _canScrollLeft)
            Positioned(
              left: 0,
              child: _buildArrow(
                icon: Icons.chevron_left,
                onTap: () => _scrollBy(-250),
              ),
            ),
          if ((_isHovering || _canScrollRight) && _canScrollRight)
            Positioned(
              right: 0,
              child: _buildArrow(
                icon: Icons.chevron_right,
                onTap: () => _scrollBy(250),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArrow({required IconData icon, required VoidCallback onTap}) {
    return _AnimatedArrow(icon: icon, onTap: onTap);
  }
}

class _AnimatedArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedArrow({required this.icon, required this.onTap});

  @override
  State<_AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<_AnimatedArrow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(widget.icon, color: Colors.blue[900], size: 24),
        ),
      ),
    );
  }
}
