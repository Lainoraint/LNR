import 'package:flutter/material.dart';
import 'dart:math';

class FlippingFeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget destination;

  const FlippingFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.destination,
  });

  @override
  _FlippingFeatureCardState createState() => _FlippingFeatureCardState();
}

class _FlippingFeatureCardState extends State<FlippingFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _toggleCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isFlipped = !_isFlipped;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => widget.destination),
        );
      },
      onLongPress: _toggleCard,
      onLongPressUp: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_animation.value * 3.14),
            child:
                _animation.value < 0.5 ? _buildFrontCard() : _buildBackCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 50, color: Colors.blue.shade700),
          const SizedBox(height: 10),
          Text(widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return _buildCard(
        child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(pi), // Putar kembali agar tidak mirror
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Text(
            widget.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: child,
    );
  }
}
