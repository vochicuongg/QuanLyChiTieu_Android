import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';

/// Statistics Screen - Shows spending analysis with animated pie chart
class StatisticsScreen extends StatefulWidget {
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;

  const StatisticsScreen({
    super.key,
    required this.chiTheoMuc,
    required this.lichSuThang,
    required this.currentDay,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    // Start animation when screen loads
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate monthly expenses by category
    final currentMonthKey = getMonthKey(widget.currentDay);
    final todayDayKey = dinhDangNgayDayDu(widget.currentDay);
    
    final Map<ChiTieuMuc, int> categoryTotals = {};
    
    // Today's expenses
    widget.chiTheoMuc.forEach((muc, items) {
      if (muc == ChiTieuMuc.soDu || muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) return;
      final total = items.fold(0, (sum, item) => sum + item.soTien);
      if (total > 0) categoryTotals[muc] = (categoryTotals[muc] ?? 0) + total;
    });
    
    // History expenses for current month
    final currentMonthData = widget.lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc == ChiTieuMuc.soDu) continue;
          categoryTotals[entry.muc] = (categoryTotals[entry.muc] ?? 0) + entry.item.soTien;
        }
      }
    }
    
    final totalExpenses = categoryTotals.values.fold(0, (sum, v) => sum + v);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage == 'vi' ? 'Thống kê' : 'Statistics', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: totalExpenses == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    appLanguage == 'vi' ? 'Chưa có dữ liệu chi tiêu' : 'No expense data yet',
                    style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly header
                  Text(
                    appLanguage == 'vi'
                        ? 'Tháng ${widget.currentDay.month}/${widget.currentDay.year}'
                        : '${getMonthName(widget.currentDay.month)} ${widget.currentDay.year}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLanguage == 'vi' ? 'Tổng chi tiêu: ' : 'Total expenses: ',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  Text(
                    formatAmountWithCurrency(totalExpenses),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: expenseColor),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Pie Chart with animation
                  Text(
                    appLanguage == 'vi' ? 'Tỷ lệ theo danh mục' : 'Category breakdown',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            sections: sortedCategories.map((entry) {
                              final percentage = (entry.value / totalExpenses * 100);
                              // Animate the radius from 0 to 50
                              final animatedRadius = 50.0 * _animation.value;
                              return PieChartSectionData(
                                color: entry.key.color,
                                value: entry.value.toDouble(),
                                title: _animation.value > 0.5 ? '${percentage.toStringAsFixed(0)}%' : '',
                                radius: animatedRadius,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 150),
                          swapAnimationCurve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category List
                  Text(
                    appLanguage == 'vi' ? 'Chi tiết theo danh mục' : 'Category details',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...sortedCategories.map((entry) {
                    final percentage = (entry.value / totalExpenses * 100);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: entry.key.color.withOpacity(0.2),
                          child: Icon(entry.key.icon, color: entry.key.color, size: 20),
                        ),
                        title: Text(entry.key.ten, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(entry.key.color),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatAmountWithCurrency(entry.value),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: expenseColor),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
