import 'package:flutter/material.dart';
import '../main.dart'; // For expenseColor access if needed, though we generally pass colors or use constants

class NumPad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onDelete;
  final VoidCallback? onLongDelete;

  const NumPad({
    super.key,
    required this.onInput,
    required this.onDelete,
    this.onLongDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Reduced vertical padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, ['1', '2', '3']),
          const SizedBox(height: 10), // Reduced spacing
          _buildRow(context, ['4', '5', '6']),
          const SizedBox(height: 10),
          _buildRow(context, ['7', '8', '9']),
          const SizedBox(height: 10),
          _buildRow(context, ['0', '000', 'delete']),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: values.map((val) {
        if (val == 'delete') {
          return _buildButton(context, val, isIcon: true);
        }
        return _buildButton(context, val);
      }).toList(),
    );
  }

  Widget _buildButton(BuildContext context, String value, {bool isIcon = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Vibranter blue for Dark Mode, Deeper blue for Light Mode
    final keyColor = isDark ? const Color(0xFF448AFF) : const Color(0xFF0044CC);
    
    return InkWell(
      onTap: () {
        if (isIcon) {
          onDelete();
        } else {
          onInput(value);
        }
      },
      onLongPress: isIcon ? onLongDelete : null,
      borderRadius: BorderRadius.circular(25), // Adjusted for smaller height
      child: SizedBox(
        width: 80, 
        height: 50, 
        child: Center(
          child: isIcon
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: keyColor, // Filled blue background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.backspace_outlined, color: Theme.of(context).scaffoldBackgroundColor, size: 24),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: keyColor,
                    shadows: isDark ? [
                      Shadow(
                        color: keyColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      )
                    ] : null, // Add a subtle glow in Dark Mode
                  ),
                ),
        ),
      ),
    );
  }
}
