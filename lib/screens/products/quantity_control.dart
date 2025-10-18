import 'package:flutter/material.dart';
import 'package:vendwise/models/productmodel.dart';

class QuantityControl extends StatefulWidget {
  final Productmodel product;
  final ValueChanged<int> onChanged;
  const QuantityControl({
    super.key,
    required this.product,
    required this.onChanged,
  });

  @override
  State<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  int _quantity = 0;
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  @override
  void initState() {
    super.initState();
    _quantity = (widget.product as dynamic).quantity ?? 0;
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
    widget.onChanged(_quantity);
  }

  void _decrement() {
    setState(() {
      if (_quantity > 0) _quantity--;
    });
    widget.onChanged(_quantity);
  }

  void _startIncrementing() {
    _isIncrementing = true;
    _increment();
    Future.delayed(const Duration(milliseconds: 400), _repeatIncrement);
  }

  void _repeatIncrement() {
    if (!_isIncrementing) return;
    _increment();
    Future.delayed(const Duration(milliseconds: 80), _repeatIncrement);
  }

  void _stopIncrementing() {
    _isIncrementing = false;
  }

  void _startDecrementing() {
    _isDecrementing = true;
    _decrement();
    Future.delayed(const Duration(milliseconds: 400), _repeatDecrement);
  }

  void _repeatDecrement() {
    if (!_isDecrementing) return;
    _decrement();
    Future.delayed(const Duration(milliseconds: 80), _repeatDecrement);
  }

  void _stopDecrementing() {
    _isDecrementing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _decrement,
          onLongPressStart: (_) => _startDecrementing(),
          onLongPressEnd: (_) => _stopDecrementing(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.remove, color: Colors.red, size: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: _increment,
          onLongPressStart: (_) => _startIncrementing(),
          onLongPressEnd: (_) => _stopIncrementing(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.add, color: Colors.green, size: 20),
          ),
        ),
      ],
    );
  }
}
