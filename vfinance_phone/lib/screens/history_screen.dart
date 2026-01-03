import 'package:flutter/material.dart';
import '../main.dart';
import '../models/expense_categories.dart';

/// History Screen - Shows transaction history
class HistoryScreen extends StatelessWidget {
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;
  final Map<ChiTieuMuc, List<ChiTieuItem>> currentData;

  const HistoryScreen({
    super.key,
    required this.lichSuThang,
    required this.currentDay,
    required this.currentData,
  });

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Combine current day data with history
    final combined = <String, Map<String, List<HistoryEntry>>>{
      for (final e in lichSuThang.entries)
        e.key: {for (final d in e.value.entries) d.key: List<HistoryEntry>.from(d.value)}
    };

    final monthKeyNow = getMonthKey(currentDay);
    final dayKeyNow = dinhDangNgayDayDu(currentDay);
    final currentDayEntries = <HistoryEntry>[];
    
    currentData.forEach((muc, items) {
      if (muc == ChiTieuMuc.lichSu || muc == ChiTieuMuc.caiDat) return;
      for (final it in items.where((item) => _sameDay(item.thoiGian, currentDay))) {
        currentDayEntries.add(HistoryEntry(muc: muc, item: it));
      }
    });
    currentDayEntries.sort((a, b) => b.item.soTien.compareTo(a.item.soTien));
    
    if (currentDayEntries.isNotEmpty) {
      combined.putIfAbsent(monthKeyNow, () => {});
      combined[monthKeyNow]![dayKeyNow] = currentDayEntries;
    }

    final sortedMonths = combined.keys.toList()..sort((a, b) {
      final pa = a.split('/'), pb = b.split('/');
      return DateTime(int.parse(pb[1]), int.parse(pb[0]))
          .compareTo(DateTime(int.parse(pa[1]), int.parse(pa[0])));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage == 'vi' ? 'Lịch sử' : 'History', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: sortedMonths.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    appLanguage == 'vi' ? 'Chưa có dữ liệu lịch sử' : 'No history data yet',
                    style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedMonths.length,
              itemBuilder: (context, i) => _buildMonthCard(context, combined, sortedMonths[i], i == 0),
            ),
    );
  }

  Widget _buildMonthCard(BuildContext context, Map<String, Map<String, List<HistoryEntry>>> combined, String monthKey, bool expanded) {
    final daysData = combined[monthKey]!;
    final totalExpense = daysData.values.expand((l) => l).where((e) => e.muc != ChiTieuMuc.soDu).fold(0, (s, e) => s + e.item.soTien);
    final totalIncome = daysData.values.expand((l) => l).where((e) => e.muc == ChiTieuMuc.soDu).fold(0, (s, e) => s + e.item.soTien);
    
    final sortedDays = daysData.keys.toList()..sort((a, b) {
      final pa = a.split('/'), pb = b.split('/');
      return DateTime(int.parse(pb[2]), int.parse(pb[1]), int.parse(pb[0]))
          .compareTo(DateTime(int.parse(pa[2]), int.parse(pa[1]), int.parse(pa[0])));
    });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          title: Row(children: [
            Text(appLanguage == 'vi' ? 'Tháng $monthKey' : '${getMonthName(int.parse(monthKey.split('/')[0]))} ${monthKey.split('/')[1]}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (totalExpense > 0) Text(formatAmountWithCurrency(totalExpense), style: const TextStyle(color: expenseColor, fontSize: 13, fontWeight: FontWeight.bold)),
              if (totalIncome > 0) Text(formatAmountWithCurrency(totalIncome), style: const TextStyle(color: incomeColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ]),
          children: sortedDays.map((dayKey) => _buildDayTile(context, daysData[dayKey]!, dayKey)).toList(),
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, List<HistoryEntry> items, String dayKey) {
    final dayExpense = items.where((e) => e.muc != ChiTieuMuc.soDu).fold(0, (s, e) => s + e.item.soTien);
    final dayIncome = items.where((e) => e.muc == ChiTieuMuc.soDu).fold(0, (s, e) => s + e.item.soTien);

    // Group items by category (muc)
    final groupedByCategory = <ChiTieuMuc, List<HistoryEntry>>{};
    for (final entry in items) {
      groupedByCategory.putIfAbsent(entry.muc, () => []).add(entry);
    }

    // Sort categories: soDu first, then by total amount descending
    final sortedCategories = groupedByCategory.keys.toList()
      ..sort((a, b) {
        if (a == ChiTieuMuc.soDu) return -1;
        if (b == ChiTieuMuc.soDu) return 1;
        final totalA = groupedByCategory[a]!.fold(0, (s, e) => s + e.item.soTien);
        final totalB = groupedByCategory[b]!.fold(0, (s, e) => s + e.item.soTien);
        return totalB.compareTo(totalA);
      });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(children: [
          Text(appLanguage == 'vi' ? 'Ngày ${dayKey.split('/')[0]}' : getOrdinalSuffix(int.parse(dayKey.split('/')[0]))),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (dayExpense > 0) Text(formatAmountWithCurrency(dayExpense), style: const TextStyle(color: expenseColor, fontSize: 12, fontWeight: FontWeight.bold)),
            if (dayIncome > 0) Text(formatAmountWithCurrency(dayIncome), style: const TextStyle(color: incomeColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ]),
        children: sortedCategories.map((muc) {
          final categoryItems = groupedByCategory[muc]!;
          final categoryTotal = categoryItems.fold(0, (s, e) => s + e.item.soTien);
          
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: muc.color.withOpacity(0.2),
                radius: 16,
                child: Icon(muc.icon, color: muc.color, size: 18),
              ),
              title: Text(muc.ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: Text(
                formatAmountWithCurrency(categoryTotal),
                style: TextStyle(
                  color: muc == ChiTieuMuc.soDu ? incomeColor : expenseColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              children: categoryItems.map((e) => ListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                leading: Icon(
                  e.item.subCategory != null 
                      ? getCategoryIcon(e.item.subCategory!)
                      : muc.icon,
                  color: muc.color,
                  size: 18,
                ),
                title: Text(
                  e.item.subCategory != null 
                      ? getCategoryDisplayName(e.item.subCategory!, appLanguage)
                      : (e.item.tenChiTieu ?? muc.ten),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(dinhDangGio(e.item.thoiGian), style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  formatAmountWithCurrency(e.item.soTien),
                  style: TextStyle(
                    color: muc == ChiTieuMuc.soDu ? incomeColor : expenseColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
