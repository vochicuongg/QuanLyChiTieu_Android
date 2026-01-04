import 'package:flutter/material.dart';
import '../main.dart'; // For expenseColor access if needed, though we generally pass colors or use constants

class NumPad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onDelete;

  const NumPad({
    super.key,
    required this.onInput,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, ['1', '2', '3']),
          const SizedBox(height: 24),
          _buildRow(context, ['4', '5', '6']),
          const SizedBox(height: 24),
          _buildRow(context, ['7', '8', '9']),
          const SizedBox(height: 24),
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
    // 000 is wider than single digits, but layout asks for equal spacing grid usually. 
    // The user image shows alignment. Let's stick to Expanded or fixed width.
    // Fixed width items with SpaceBetween looks good.
    return InkWell(
      onTap: () {
        if (isIcon) {
          onDelete();
        } else {
          onInput(value);
        }
      },
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        width: 80, 
        height: 60,
        child: Center(
          child: isIcon
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF0044CC), width: 2), // Blue outline like image
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.backspace_outlined, color: Color(0xFF0044CC), size: 24),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0044CC), // Blue digit color
                  ),
                ),
        ),
      ),
    );
  }
}
