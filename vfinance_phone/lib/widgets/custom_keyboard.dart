import 'package:flutter/material.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onInput;
  final VoidCallback onDelete;

  const CustomKeyboard({
    super.key,
    required this.onInput,
    required this.onDelete,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  bool _isShiftEnabled = false;

  final List<String> _row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  final List<String> _row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  final List<String> _row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E2C) 
          : Colors.grey[100],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(_row1),
          const SizedBox(height: 8),
          _buildRow(_row2, padding: 12),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildShiftKey(),
              Expanded(child: _buildRow(_row3)),
              _buildBackspaceKey(),
            ],
          ),
          const SizedBox(height: 8),
          _buildSpaceBar(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, {double padding = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map((k) => _buildKey(k)).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final displayKey = _isShiftEnabled ? key.toUpperCase() : key;
    return Expanded(
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D3F) 
              : Colors.white,
          borderRadius: BorderRadius.circular(5),
          elevation: 1,
          child: InkWell(
            onTap: () => widget.onInput(displayKey),
            borderRadius: BorderRadius.circular(5),
            child: Center(
              child: Text(
                displayKey,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftKey() {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: _isShiftEnabled 
            ? const Color(0xFF6C5CE7) 
            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D3F) : Colors.grey[300]),
        borderRadius: BorderRadius.circular(5),
        elevation: 1,
        child: InkWell(
          onTap: () {
            setState(() {
              _isShiftEnabled = !_isShiftEnabled;
            });
          },
          borderRadius: BorderRadius.circular(5),
          child: Center(
            child: Icon(
              Icons.arrow_upward,
              size: 20,
              color: _isShiftEnabled 
                  ? Colors.white 
                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D3F) 
              : Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
        elevation: 1,
        child: InkWell(
          onTap: widget.onDelete,
          borderRadius: BorderRadius.circular(5),
          child: const Center(
            child: Icon(Icons.backspace_outlined, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 40), // Indent to center roughly
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D3F) 
              : Colors.white,
        borderRadius: BorderRadius.circular(5),
        elevation: 1,
        child: InkWell(
          onTap: () => widget.onInput(' '),
          borderRadius: BorderRadius.circular(5),
          child: Center(
            child: Text(
              'Space',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
