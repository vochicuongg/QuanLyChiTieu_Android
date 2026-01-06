import 'package:flutter/material.dart';
import '../models/comparison_model.dart';
import '../models/expense_categories.dart';
import '../main.dart';

class DeltaListView extends StatelessWidget {
  final ComparisonState data;

  const DeltaListView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.data.length,
      itemBuilder: (context, index) {
        final item = data.data[index];
        final isIncrease = item.delta > 0;
        final isDecrease = item.delta < 0;
        final isZero = item.delta == 0;
        
        // Expenses logic: Increase (Red) is usually bad, Decrease (Green) is usually good
        final deltaColor = isIncrease ? Colors.red : (isDecrease ? Colors.green : Colors.grey);
        final deltaIcon = isIncrease ? Icons.arrow_upward : (isDecrease ? Icons.arrow_downward : Icons.remove);
        
        return Card(
          color: Theme.of(context).cardColor,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // Icon
                CircleAvatar(
                  backgroundColor: item.category.color.withOpacity(0.1),
                  radius: 20,
                  child: Icon(item.category.icon, color: item.category.color, size: 20),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.ten,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                             appLanguage == 'vi' ? 'Kỳ trước: ' : 'Previous: ',
                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            formatAmountWithCompact(item.baselineAmount),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                             appLanguage == 'vi' ? 'Kỳ này: ' : 'Current: ',
                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            formatAmountWithCompact(item.currentAmount),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Delta Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deltaColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: deltaColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isZero) ...[
                        Icon(deltaIcon, size: 14, color: deltaColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isZero ? '-' : formatAmountWithCompact(item.delta.abs()),
                        style: TextStyle(
                          color: deltaColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String formatAmountWithCompact(int amount) {
    amount = amount.abs();
    if (amount >= 1000000) {
      double val = amount / 1000000.0;
      String s = val.toStringAsFixed(1).replaceAll(',', '.');
      if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
      return '${s}Tr';
    }
    if (amount >= 1000) {
       double val = amount / 1000.0;
       return '${val.toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}
