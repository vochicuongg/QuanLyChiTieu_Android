import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../models/expense_categories.dart';

/// Statistics Screen - Shows spending analysis with animated pie chart
class StatisticsScreen extends StatefulWidget {
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;
  final bool isVisible;

  const StatisticsScreen({
    super.key,
    required this.chiTheoMuc,
    required this.lichSuThang,
    required this.currentDay,
    required this.isVisible,
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    // Start animation if visible initially
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when switching to this tab
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Show bottom sheet with daily breakdown for a category
  void _showCategoryBreakdown(BuildContext context, ChiTieuMuc category, String currentMonthKey, String todayDayKey) {
    // Collect all transactions for this category in the current month
    final List<Map<String, dynamic>> transactions = [];
    
    // Today's transactions
    final todayItems = widget.chiTheoMuc[category] ?? <ChiTieuItem>[];
    for (final item in todayItems) {
      transactions.add({
        'date': item.thoiGian,
        'amount': item.soTien,
        'name': item.tenChiTieu,
        'subCategory': item.subCategory,
        'dayKey': todayDayKey,
      });
    }
    
    // History transactions for current month
    final currentMonthData = widget.lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue; // Already added today
        for (final entry in dayEntry.value) {
          if (entry.muc == category) {
            transactions.add({
              'date': entry.item.thoiGian,
              'amount': entry.item.soTien,
              'name': entry.item.tenChiTieu,
              'subCategory': entry.item.subCategory,
              'dayKey': dayEntry.key,
            });
          }
        }
      }
    }
    
    // Sort by date (newest first)
    transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    // Calculate total
    final total = transactions.fold(0, (sum, t) => sum + (t['amount'] as int));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      child: Icon(category.icon, color: category.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.ten,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            appLanguage == 'vi'
                                ? 'Tháng ${widget.currentDay.month}/${widget.currentDay.year}'
                                : '${getMonthName(widget.currentDay.month)} ${widget.currentDay.year}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatAmountWithCurrency(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Transaction list
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          appLanguage == 'vi' ? 'Không có giao dịch' : 'No transactions',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Group transactions by day
                          final groupedByDay = <String, List<Map<String, dynamic>>>{};
                          for (final t in transactions) {
                            final dayKey = t['dayKey'] as String;
                            groupedByDay.putIfAbsent(dayKey, () => []).add(t);
                          }
                          
                          // Sort days (newest first)
                          final sortedDays = groupedByDay.keys.toList()
                            ..sort((a, b) {
                              final pa = a.split('/'), pb = b.split('/');
                              return DateTime(int.parse(pb[2]), int.parse(pb[1]), int.parse(pb[0]))
                                  .compareTo(DateTime(int.parse(pa[2]), int.parse(pa[1]), int.parse(pa[0])));
                            });
                          
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedDays.length,
                            itemBuilder: (_, dayIndex) {
                              final dayKey = sortedDays[dayIndex];
                              final dayItems = groupedByDay[dayKey]!;
                              final dayTotal = dayItems.fold(0, (s, t) => s + (t['amount'] as int));
                              final dayParts = dayKey.split('/');
                              
                              return Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayParts[0],
                                          style: TextStyle(fontWeight: FontWeight.bold, color: category.color, fontSize: 14),
                                        ),
                                        Text(
                                          appLanguage == 'vi' ? 'Th${dayParts[1]}' : getMonthName(int.parse(dayParts[1])).substring(0, 3),
                                          style: TextStyle(fontSize: 9, color: category.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    appLanguage == 'vi' ? 'Ngày ${dayParts[0]}' : getOrdinalSuffix(int.parse(dayParts[0])),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  trailing: Text(
                                    formatAmountWithCurrency(dayTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: expenseColor, fontSize: 13),
                                  ),
                                  children: dayItems.map((t) {
                                    final date = t['date'] as DateTime;
                                    final amount = t['amount'] as int;
                                    final subCategory = t['subCategory'] as String?;
                                    final name = t['name'] as String?;
                                    
                                    final displayName = name ?? (subCategory != null 
                                        ? getCategoryDisplayName(subCategory, appLanguage)
                                        : category.ten);
                                    
                                    return ListTile(
                                      contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                      leading: Icon(
                                        subCategory != null ? getCategoryIcon(subCategory) : category.icon,
                                        color: category.color,
                                        size: 18,
                                      ),
                                      title: Text(displayName, style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(dinhDangGio(date), style: const TextStyle(fontSize: 11)),
                                      trailing: Text(
                                        formatAmountWithCurrency(amount),
                                        style: const TextStyle(fontWeight: FontWeight.w500, color: expenseColor, fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
                            // Rotate from -90 to 270 degrees (360 degree rotation)
                            startDegreeOffset: -90.0 + (360.0 * _animation.value),
                            sections: sortedCategories.map((entry) {
                              final percentage = (entry.value / totalExpenses * 100);
                              
                              // All sections animate radius together
                              final animatedRadius = 50.0 * _animation.value;
                              
                              return PieChartSectionData(
                                color: entry.key.color,
                                value: entry.value.toDouble(),
                                title: _animation.value > 0.8 ? '${percentage.toStringAsFixed(0)}%' : '',
                                radius: animatedRadius,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                          swapAnimationDuration: Duration.zero,
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
                        title: Text(entry.key.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(entry.key.color),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
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
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                        onTap: () => _showCategoryBreakdown(context, entry.key, currentMonthKey, todayDayKey),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
