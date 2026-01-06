import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/comparison_model.dart'; // New Import
import '../widgets/comparison_chart.dart'; // New Import
import '../widgets/delta_list_view.dart';   // New Import
import '../main.dart';
import '../models/expense_categories.dart';
import '../widgets/animated_progress_bar.dart';
 

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
  
  // Existing Overview State
  int _touchedIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final Map<ChiTieuMuc, GlobalKey> _itemKeys = {};

  // New Comparison State
  bool _isComparisonMode = false;
  DateTime? _selectedBaselineMonth;

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
    
    // Default baseline to previous month
    _selectedBaselineMonth = DateTime(widget.currentDay.year, widget.currentDay.month - 1);
    
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
      _touchedIndex = -1; // Reset selection
    }
    // Update baseline constraint if current day changes significantly (unlikely in session but safe)
     if (widget.currentDay != oldWidget.currentDay) {
        _selectedBaselineMonth = DateTime(widget.currentDay.year, widget.currentDay.month - 1);
     }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(ChiTieuMuc category) {
    final key = _itemKeys[category];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  /// Helper to get all transactions for a specific month from History or Current Data
  /// Returns List<HistoryEntry> to preserve Category info
  List<HistoryEntry> _getTransactionsForMonth(DateTime month) {
    final monthKey = getMonthKey(month);
    final currentMonthKey = getMonthKey(widget.currentDay);
    
    List<HistoryEntry> results = [];

    // If requesting the current month, merge live data + history
    if (monthKey == currentMonthKey) {
       // 1. Add from chiTheoMuc (Today)
       widget.chiTheoMuc.forEach((cat, items) {
          for (var item in items) {
             results.add(HistoryEntry(muc: cat, item: item));
          }
       });
       
       // 2. Add from lichSuThang (Past days of this month)
       final historyData = widget.lichSuThang[monthKey];
       if (historyData != null) {
         historyData.forEach((key, entries) {
           if (key != dinhDangNgayDayDu(widget.currentDay)) { // Avoid dupes if today is synced
              results.addAll(entries);
           }
         });
       }
    } else {
      // Just history
      final historyData = widget.lichSuThang[monthKey];
      if (historyData != null) {
         // historyData is Map<dayString, List<HistoryEntry>>
         historyData.forEach((key, entries) {
            results.addAll(entries);
         });
      }
    }
    return results;
  }

  /// Show bottom sheet with daily breakdown (Existing logic, kept for Overview)
  void _showCategoryBreakdown(BuildContext context, ChiTieuMuc category, String currentMonthKey, String todayDayKey) {
     // ... (Existing implementation kept intact conceptually, but re-implemented here or use existing if not replaced block)
     // Since I am replacing the whole class body essentially or large chunk, I must include it.
     // For brevity in this replacing tool, I'll rely on the existing method signatures if I wasn't replacing the whole class.
     // But looking at the tool usage, I am replacing practically the whole file content?
     // No, I'm replacing from line 1 to 563 (EndLine). So I must provide full implementation.
     
     // Correcting: I should keep the logic.
     
    final List<Map<String, dynamic>> transactions = [];
    final todayItems = widget.chiTheoMuc[category] ?? <ChiTieuItem>[];
    for (final item in todayItems) {
      transactions.add({
        'date': item.thoiGian, 'amount': item.soTien, 'name': item.tenChiTieu,
        'subCategory': item.subCategory, 'dayKey': todayDayKey,
      });
    }
    final currentMonthData = widget.lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc == category) {
            transactions.add({
              'date': entry.item.thoiGian, 'amount': entry.item.soTien, 'name': entry.item.tenChiTieu,
              'subCategory': entry.item.subCategory, 'dayKey': dayEntry.key,
            });
          }
        }
      }
    }
    transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final total = transactions.fold(0, (sum, t) => sum + (t['amount'] as int));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
               Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
               Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                 CircleAvatar(backgroundColor: category.color.withOpacity(0.2), child: Icon(category.icon, color: category.color)),
                 const SizedBox(width: 12),
                 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                   Text(category.ten, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                   Text(appLanguage == 'vi' ? 'Tháng ${widget.currentDay.month}/${widget.currentDay.year}' : '${getMonthName(widget.currentDay.month)} ${widget.currentDay.year}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13.0)),
                 ])),
                 Text(formatAmountWithCurrency(total), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: expenseColor)),
               ])),
               const SizedBox(height: 16),
               Expanded(
                 child: transactions.isEmpty 
                    ? Center(child: Text(appLanguage == 'vi' ? 'Không có giao dịch' : 'No transactions', style: TextStyle(color: Colors.grey.shade500)))
                    : Builder(builder: (context) {
                        final groupedByDay = <String, List<Map<String, dynamic>>>{};
                        for (final t in transactions) { groupedByDay.putIfAbsent(t['dayKey'] as String, () => []).add(t); }
                        final sortedDays = groupedByDay.keys.toList()..sort((a, b) {
                              final pa = a.split('/'), pb = b.split('/');
                              return DateTime(int.parse(pb[2]), int.parse(pb[1]), int.parse(pb[0])).compareTo(DateTime(int.parse(pa[2]), int.parse(pa[1]), int.parse(pa[0])));
                            });
                        return ListView.builder(
                          controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(dayParts[0], style: TextStyle(fontWeight: FontWeight.bold, color: category.color, fontSize: 14.0)),
                                    Text(appLanguage == 'vi' ? 'Th${dayParts[1]}' : getMonthName(int.parse(dayParts[1])).substring(0, 3), style: TextStyle(fontSize: 9.0, color: category.color)),
                                  ]),
                                ),
                                title: Text(appLanguage == 'vi' ? 'Ngày ${dayParts[0]}' : getOrdinalSuffix(int.parse(dayParts[0])), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
                                trailing: Text(formatAmountWithCurrency(dayTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: expenseColor, fontSize: 13.0)),
                                children: dayItems.map((t) {
                                  final date = t['date'] as DateTime;
                                  final amount = t['amount'] as int;
                                  final subCategory = t['subCategory'] as String?;
                                  final name = t['name'] as String?;
                                  final displayName = name ?? (subCategory != null ? getCategoryDisplayName(subCategory, appLanguage) : category.ten);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                    leading: Icon(subCategory != null ? getCategoryIcon(subCategory) : category.icon, color: category.color, size: 18),
                                    title: Text(displayName, style: const TextStyle(fontSize: 13.0)),
                                    subtitle: Text(dinhDangGio(date), style: const TextStyle(fontSize: 11.0)),
                                    trailing: Text(formatAmountWithCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w500, color: expenseColor, fontSize: 12.0)),
                                  );
                                }).toList(),
                              ),
                            );
                        });
                    }),
               ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage == 'vi' ? 'Thống kê' : 'Statistics', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // 1. Toggle Control (Overview vs Comparison)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false, 
                  label: Text(appLanguage == 'vi' ? 'Tổng quan' : 'Overview'),
                  icon: const Icon(Icons.pie_chart),
                ),
                ButtonSegment(
                  value: true, 
                  label: Text(appLanguage == 'vi' ? 'So sánh' : 'Comparison'),
                  icon: const Icon(Icons.bar_chart),
                ),
              ],
              selected: {_isComparisonMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isComparisonMode = newSelection.first;
                  // If switching back to Overview, restart pie chart animation and reset selection
                  if (!_isComparisonMode) {
                    _animationController.reset();
                    _animationController.forward();
                    _touchedIndex = -1; // Reset selection
                  }
                });
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xff4CEEC8);
                  }
                  return Colors.transparent; // Use default or transparent for unselected
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                   if (states.contains(MaterialState.selected)) {
                     return Colors.black; // Ensure text is readable on light green
                   }
                   return Colors.white; // Or default theme color
                }),
              ),
            ),
          ),
          
          // 2. Main Content
          Expanded(
            child: _isComparisonMode ? _buildComparisonView() : _buildOverviewView(),
          ),
        ],
      ),
    );
  }

  /// Original Overview Logic (Refactored)
  Widget _buildOverviewView() {
    // Calculate monthly expenses by category (Existing Logic)
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
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // ... (Existing Return Scaffold Body)
    if (totalExpenses == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(appLanguage == 'vi' ? 'Chưa có dữ liệu chi tiêu' : 'No expense data yet', style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 16)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly header
          Text(
            appLanguage == 'vi' ? 'Tháng ${widget.currentDay.month}/${widget.currentDay.year}' : '${getMonthName(widget.currentDay.month)} ${widget.currentDay.year}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(appLanguage == 'vi' ? 'Tổng chi tiêu: ' : 'Total expenses: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          Text(
            formatAmountWithCurrency(totalExpenses),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: expenseColor, shadows: [Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 0.5), blurRadius: 0.5)]),
          ),
          const SizedBox(height: 32),
          
          // Pie Chart
          Text(appLanguage == 'vi' ? 'Tỷ lệ theo danh mục' : 'Category breakdown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height < 600 ? 180 : 250,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return PieChart(PieChartData(
                  pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (event is FlTapUpEvent) {
                        final touchedSection = pieTouchResponse?.touchedSection;
                        if (touchedSection != null && touchedSection.touchedSectionIndex != -1) {
                          final newIndex = touchedSection.touchedSectionIndex;
                          if (newIndex >= 0 && newIndex < sortedCategories.length) {
                             if (_touchedIndex == newIndex) { _touchedIndex = -1; } 
                             else { _touchedIndex = newIndex; _scrollToCategory(sortedCategories[newIndex].key); }
                          }
                        } else { _touchedIndex = -1; }
                      }
                    });
                  }),
                  sectionsSpace: 0, centerSpaceRadius: 65, startDegreeOffset: -360.0 + (360.0 * _animation.value),
                  sections: sortedCategories.asMap().entries.map((entry) {
                    final index = entry.key; final data = entry.value; final isTouched = index == _touchedIndex;
                    final percentage = (data.value / totalExpenses * 100);
                    final baseRadius = 60.0 * _animation.value; final radius = isTouched ? baseRadius + 10 : baseRadius;
                    final opacity = ((_animation.value - 0.5) * 2.0).clamp(0.0, 1.0);
                    return PieChartSectionData(
                      color: data.key.color, value: data.value.toDouble(), title: '${percentage.toStringAsFixed(1)}%', radius: radius,
                      titleStyle: TextStyle(fontSize: isTouched ? 16 : 14, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(opacity), shadows: [Shadow(color: Colors.black.withOpacity(0.5 * opacity), offset: const Offset(1, 1), blurRadius: 1)]),
                      borderSide: BorderSide.none,
                    );
                  }).toList(),
                ), swapAnimationDuration: _animationController.isAnimating ? Duration.zero : const Duration(milliseconds: 250), swapAnimationCurve: Curves.easeInOut);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Category List
          Text(appLanguage == 'vi' ? 'Chi tiết theo danh mục' : 'Category details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...sortedCategories.map((entry) {
            final percentage = (entry.value / totalExpenses * 100);
            final isHighlighted = _touchedIndex != -1 && sortedCategories[_touchedIndex].key == entry.key;
            if (!_itemKeys.containsKey(entry.key)) _itemKeys[entry.key] = GlobalKey();
            return Card(
              key: _itemKeys[entry.key], margin: const EdgeInsets.only(bottom: 8), elevation: isHighlighted ? 4 : 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isHighlighted ? BorderSide(color: entry.key.color, width: 2) : BorderSide.none),
              color: isHighlighted ? entry.key.color.withOpacity(0.05) : Theme.of(context).cardColor,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: entry.key.color.withOpacity(0.2), child: Icon(entry.key.icon, color: entry.key.color, size: 20)),
                title: Text(entry.key.ten, style: TextStyle(fontWeight: FontWeight.bold, color: isHighlighted ? entry.key.color : null)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: AnimatedBudgetProgressBar(key: ValueKey('${entry.key.name}_${widget.isVisible}'), progress: percentage / 100, color: entry.key.color, height: 6)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(formatAmountWithCurrency(entry.value), style: TextStyle(fontWeight: FontWeight.bold, color: expenseColor, shadows: [Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 0.2), blurRadius: 0.5)])),
                        Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                    const SizedBox(width: 8), Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ]),
                onTap: () => _showCategoryBreakdown(context, entry.key, currentMonthKey, todayDayKey),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// New Comparison Mode Logic
  Widget _buildComparisonView() {
    // Ensure baseline is set
    final baseline = _selectedBaselineMonth ?? DateTime(widget.currentDay.year, widget.currentDay.month - 1);

    // 1. Prepare Data
    final baselineItems = _getTransactionsForMonth(baseline);
    final currentItems = _getTransactionsForMonth(widget.currentDay);
    
    final comparisonData = DataMerger.mergeAndCompare(
      baselineMonth: baseline,
      currentMonth: widget.currentDay,
      baselineItems: baselineItems,
      currentItems: currentItems,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Month Selectors
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Baseline Selector
                   Expanded(
                     child: InkWell(
                       onTap: () async {
                         // 1. Get available months from history keys
                         // Keys format: "M/YYYY"
                         final availableMonths = widget.lichSuThang.keys.map((key) {
                           final parts = key.split('/');
                           if (parts.length == 2) {
                             return DateTime(int.parse(parts[1]), int.parse(parts[0]));
                           }
                           return null;
                         }).whereType<DateTime>()
                           .where((date) => !(date.month == widget.currentDay.month && date.year == widget.currentDay.year)) // Exclude current month
                           .toList();

                         // Add previous month relative to current if not already in list (for edge cases where history might be empty but user wants to compare)
                         // Actually user asked strictly for "Time in History". So let's stick to what's in lichSuThang.
                         
                         // Group by year
                         final Map<int, List<DateTime>> groupedByYear = {};
                         for (var date in availableMonths) {
                           if (!groupedByYear.containsKey(date.year)) {
                             groupedByYear[date.year] = [];
                           }
                           groupedByYear[date.year]!.add(date);
                         }
                         
                         // Sort years descending
                         final sortedYears = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

                         await showModalBottomSheet(
                           context: context,
                           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                           builder: (context) {
                             return Container(
                               padding: const EdgeInsets.symmetric(vertical: 20),
                               height: MediaQuery.of(context).size.height * 0.5, // Increased height slightly
                               child: Column(
                                 children: [
                                   Text(
                                     appLanguage == 'vi' ? 'Chọn kỳ so sánh' : 'Select Baseline Period',
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                   ),
                                   const SizedBox(height: 10),
                                   Expanded(
                                     child: ListView.builder(
                                       itemCount: sortedYears.length,
                                       itemBuilder: (context, yearIndex) {
                                         final year = sortedYears[yearIndex];
                                         final months = groupedByYear[year]!;

                                         return Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Padding(
                                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                               child: Text(
                                                 '$year',
                                                 style: TextStyle(
                                                   fontSize: 14,
                                                   fontWeight: FontWeight.bold,
                                                   color: Colors.grey.shade600,
                                                 ),
                                               ),
                                             ),
                                             ...months.map((date) {
                                                final isSelected = date.year == baseline.year && date.month == baseline.month;
                                                return ListTile(
                                                   visualDensity: VisualDensity.compact, // Make it tighter
                                                   leading: Icon(Icons.calendar_today, color: isSelected ? primaryColor : Colors.grey),
                                                   title: Text(
                                                     appLanguage == 'vi' 
                                                        ? 'Tháng ${date.month}' 
                                                        : getMonthName(date.month),
                                                     style: TextStyle(
                                                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                       color: isSelected ? primaryColor : null,
                                                     ),
                                                   ),
                                                   trailing: isSelected ? const Icon(Icons.check, color: primaryColor) : null,
                                                   onTap: () {
                                                     setState(() {
                                                       _selectedBaselineMonth = date;
                                                     });
                                                     Navigator.pop(context);
                                                   },
                                                 );
                                             }).toList(),
                                             Divider(height: 1, color: Colors.grey.withOpacity(0.5)),
                                           ],
                                         );
                                       },
                                     ),
                                   ),
                                 ],
                               ),
                             );
                           },
                         );
                       },
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(appLanguage == 'vi' ? 'Kỳ trước' : 'Baseline', style: TextStyle(fontSize: 12, color: Colors.grey)),
                           Row(
                             children: [
                               Text('${baseline.month}/${baseline.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               const Icon(Icons.arrow_drop_down, size: 20),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                   const Icon(Icons.arrow_forward, color: Colors.grey),
                   // Current Month (Fixed or Selectable? Keeping fixed to "Current" context for now based on user flow, but strictly it compares "Current View Date")
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.only(left: 16),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(appLanguage == 'vi' ? 'Kỳ này' : 'Current', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${widget.currentDay.month}/${widget.currentDay.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. Summary
          Text(appLanguage == 'vi' ? 'Biểu đồ so sánh' : 'Comparison Chart', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ComparisonChart(data: comparisonData),
          
          const SizedBox(height: 24),
          
          // 3. Breakdown List
          Text(appLanguage == 'vi' ? 'Chi tiết chênh lệch' : 'Delta Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DeltaListView(data: comparisonData),
        ],
      ),
    );
  }
}
