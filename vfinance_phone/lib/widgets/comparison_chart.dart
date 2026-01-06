import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/comparison_model.dart';
import '../models/expense_categories.dart';
import '../main.dart'; // For formatting utilities

class ComparisonChart extends StatefulWidget {
  final ComparisonState data;

  const ComparisonChart({super.key, required this.data});

  @override
  State<ComparisonChart> createState() => _ComparisonChartState();
}

class _ComparisonChartState extends State<ComparisonChart> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _tooltipController;
  late Animation<double> _tooltipAnimation;
  int _touchedIndex = -1; // Added state

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();

    _tooltipController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
    );
    _tooltipAnimation = CurvedAnimation(parent: _tooltipController, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant ComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
      // Reset selection on data change
      _touchedIndex = -1; 
      _tooltipController.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
      if (_touchedIndex == index) {
        _tooltipController.reverse().whenComplete(() {
           if (mounted && _touchedIndex == index) {
             setState(() { _touchedIndex = -1; });
           }
        });
      } else {
        setState(() {
          _touchedIndex = index;
          _tooltipController.reset();
          _tooltipController.forward();
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    // Only show top 5 categories by current amount to avoid clutter
    final displayData = widget.data.data.take(6).toList();
    if (displayData.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No data')));
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation, _tooltipController]),
        builder: (context, child) {
          
          // Generate Bar Groups
          final barGroups = displayData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final hasBaseline = item.baselineAmount > 0;
            final hasCurrent = item.currentAmount > 0;
            
            // Build rods list based on data presence
            List<BarChartRodData> rods = [];
            
            if (hasBaseline) {
                rods.add(BarChartRodData(
                    toY: item.baselineAmount.toDouble() * _animation.value,
                    color: Colors.grey.withOpacity(0.4),
                    width: 12, 
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ));
            }
            
            // Add current rod if it has value OR if both are zero (to ensure at least one rod exists)
            if (hasCurrent || rods.isEmpty) {
                rods.add(BarChartRodData(
                    toY: item.currentAmount.toDouble() * _animation.value,
                    color: item.category.color,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ));
            }

            return BarChartGroupData(
              x: index,
              showingTooltipIndicators: _touchedIndex == index ? [rods.length - 1] : [],
              barRods: rods,
            );
          }).toList();

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(displayData),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: false, // Custom handling
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent) {
                      if (barTouchResponse == null || barTouchResponse.spot == null) {
                         if (_touchedIndex != -1) {
                           _tooltipController.reverse().whenComplete(() {
                             if (mounted && _touchedIndex != -1) {
                               setState(() { _touchedIndex = -1; });
                             }
                           });
                         }
                      } else {
                         _handleTap(barTouchResponse.spot!.touchedBarGroupIndex);
                      }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.9 * _tooltipAnimation.value), // Animate opacity
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  maxContentWidth: 250, // Increase width to prevent wrapping (rơi chữ)
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    // Only show combined tooltip on the "Current" rod (which is always the last one)
                    if (rodIndex != group.barRods.length - 1) return null;

                    final item = displayData[group.x.toInt()];
                    
                    final prevLabel = appLanguage == 'vi' ? 'Kỳ trước: ' : 'Previous: ';
                    final currLabel = appLanguage == 'vi' ? 'Kỳ này: ' : 'Current: ';
                    
                    final opacity = _tooltipAnimation.value;
                    
                    return BarTooltipItem(
                      '$currLabel${formatAmountWithCurrency(item.currentAmount)}\n',
                       TextStyle(
                        color: Colors.white.withOpacity(opacity), 
                        fontWeight: FontWeight.bold,
                        fontSize: 14, 
                      ),
                      children: [
                        TextSpan(
                          text: '$prevLabel${formatAmountWithCurrency(item.baselineAmount)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8 * opacity),
                            fontWeight: FontWeight.normal,
                            fontSize: 12, 
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= displayData.length) return const SizedBox();
                      final category = displayData[value.toInt()].category;
                      return GestureDetector(
                        onTap: () => _handleTap(value.toInt()),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Icon(category.icon, size: 20, color: category.color),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          );
        }
      ),
    );
  }

  double _calculateMaxY(List<CategoryComparisonData> list) {
    double max = 0;
    for (var item in list) {
      if (item.currentAmount > max) max = item.currentAmount.toDouble();
      if (item.baselineAmount > max) max = item.baselineAmount.toDouble();
    }
    return max * 1.2; // Add 20% headroom
  }
}
